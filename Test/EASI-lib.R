transColumnCache <- list()
translationCache <- list()
EASItestsCache <- NULL
translationDictionaryCache <- NULL

getEASITests <- function() {
  if (is.null(EASItestsCache)) {
    titleTransCol <- getTransCol(
    "EASI_tests",
    "title",
    language
  )
    EASItestsCache <<- concerto.table.query(
    "
    SELECT
    *,
    IFNULL({{titleTransCol}}, title) title_trans
    FROM EASI_tests ORDER BY orderIndex ASC",
    list(titleTransCol = titleTransCol)
  )

  }
  EASItestsCache
}



getTableColumns <- function(table) {
  if (is.null(transColumnCache[[table]])) {
    cols <- concerto.table.query(
      "SHOW COLUMNS FROM `{{table}}`",
      list(table = table)
    )

    transColumnCache[[table]] <<- cols$Field
  }

  transColumnCache[[table]]
}

getTranslationDictionary <- function() {
  if (is.null(translationDictionaryCache)) {
    translationDictionaryCache <<- concerto.table.query(
      "SELECT * FROM EASI_translation_dictionary"
    )
  }

  translationDictionaryCache
}

  getTransCol = function(table, col, language) {
    tableCols <- getTableColumns(table)

    transColName <- paste0(col, "_", language)
    if (transColName %in% tableCols) {
      transColName
    } else {
      col
    }
  }

isValid = function(value) {
  !is.null(value) &&
    length(value) > 0 &&
    !is.na(value) &&
    value != ""
}

getParticipantMonths <- function(dateOfBirth, assessmentDate) {
  days <- as.numeric(difftime(
    as.POSIXct(assessmentDate, tz = "UTC"),
    as.POSIXct(dateOfBirth, tz = "UTC")
  ))
  round(days / 30.4375)
}

getAgeYears <- function(dateOfBirth, assessmentDate) {
  dateOfBirth <- as.Date(dateOfBirth)
  assessmentDate <- as.Date(assessmentDate)

  round(
    as.numeric(assessmentDate - dateOfBirth) / 365.25,
    3
  )
}

getSettings <- function(test, participantId, participantMonths, ageInYears) {
  settings <- list(
    itemsperpage = test$itemsPerPage,
    scoringalgo = test$scoringAlgo,
    itemselectionalgo = test$itemSelectionAlgo,
    stopalgo = test$stopAlgo,
    cangoback = test$canGoBack,
    participantId = participantId
  )

  # default settings
  # if (is.na(settings$itemsperpage)) {
  #  settings$itemsperpage <- nrow(items)
  # }

  settingsTable <- paste0(test$code, "_settings")
  extraSettings <- concerto.table.query(
    "
SELECT * FROM {{settingsTable}}
WHERE (minParticipantMonths<='{{months}}' OR minParticipantMonths IS NULL) AND
(maxParticipantMonths>='{{months}}' OR maxParticipantMonths IS NULL)",
    list(settingsTable = settingsTable, months = participantMonths)
  )

  for (i in seq_len(nrow(extraSettings))) {
    extraSetting <- as.list(extraSettings[i, ])
    settings[[tolower(extraSetting$name)]] <- extraSetting$value
  }
  if (test$scoringAlgo != "norm") {
    settingsTableNew <- paste0(test$code, "_settings_new")
    extraSettingsNew <- concerto.table.query(
      "SELECT * FROM {{settingsTableNew}}",
      list(settingsTableNew = settingsTableNew)
    )

    settings$childsAge <- ageInYears
    settings$scoreSettings <- list()

    for (i in seq_len(nrow(extraSettingsNew))) {
      row <- as.list(extraSettingsNew[i, ])
      row$id <- NULL
      names(row) <- tolower(names(row))
      settings$scoreSettings[[i]] <- row
    }
  }

  settings
}

calcScores <- function(responses, items, settings) {
if (is.null(responses) || nrow(responses) == 0) {
  stop("calcScores: no responses found")
}

if (is.null(items) || nrow(items) == 0) {
  stop("calcScores: no test items found")
}

  scoringModuleName <- paste0("EASI-scoring-", settings$scoringalgo)

concerto.log(paste0("scoring module", scoringModuleName))
  scoringResult <- concerto.test.run(scoringModuleName, list(
    items = items,
    responses = responses,
    settings = settings
  ))
  scores <- scoringResult$scores
}

updateScoreTable <- function(testCode, sessionId, participantId, scores) {
  scoresTable <- paste0(testCode, "_scores")
  concerto.table.query("DELETE FROM {{scoresTable}} WHERE session_id='{{session_id}}'", list(scoresTable = scoresTable, session_id = sessionId))

  if (is.list(scores) && length(scores) > 0) {
    insertSql <- concerto.table.insertParams("INSERT INTO {{scoresTable}} (session_id, name, value, timeCreated, participant_id) VALUES ", list(scoresTable = scoresTable))

    scoreValuesSqlArray <- NULL
    for (scoreName in names(scores)) {
      scoreValuesSql <- concerto.table.insertParams("('{{session_id}}', '{{name}}', IF('{{value}}'='', NULL, '{{value}}'), NOW(), '{{participant_id}}')", list(
        session_id = sessionId,
        name = scoreName,
        value = scores[[scoreName]],
        participant_id = participantId
      ))
      scoreValuesSqlArray <- c(scoreValuesSqlArray, scoreValuesSql)
    }
    insertSql <- paste0(insertSql, paste0(scoreValuesSqlArray, collapse = ","))
    concerto.table.query(insertSql)
  }
}

lib <- list(
  getParticipantMonths = getParticipantMonths,
  getSettings = getSettings,
  getAgeYears = getAgeYears,
  getEasiTests = getEasiTests,
  calcScores = calcScores,
  isValid = isValid,
  updateScoreTable = updateScoreTable,
  getTransCol = getTransCol,
  getPropName = function(trait, name, includeTraitInScoreName = FALSE) {
    if (isValid(trait) && includeTraitInScoreName) {
      paste0(trait, " - ", name)
    } else {
      name
    }
  },
  getScorableItems = function(responses, items, trait = NULL) {
    scoringResponses <- if (
      is.null(trait) ||
        length(trait) == 0 ||
        is.na(trait) ||
        !nzchar(trait)
    ) {
      responses
    } else {
      responses[responses$trait == trait, ]
    }

    scoreableItems <- items[
      is.na(items$excludeFromScoring) |
        items$excludeFromScoring != 1, ,
      drop = FALSE
    ]

    responseKeys <- paste(
      scoringResponses$test,
      scoringResponses$item_id
    )

    itemKeys <- paste(
      scoreableItems$test,
      scoreableItems$id
    )

    scoreableResponses <- scoringResponses[
      responseKeys %in% itemKeys &
        scoringResponses$scoreStatus == "scored",
    ]

    scoreableResponses
  },
  translate = function(entryKey, languageCode) {
    if (is.null(languageCode) || languageCode == "") {
      languageCode <- "en"
    }

    dict <- getTranslationDictionary()

    if (!(languageCode %in% names(dict))) {
      languageCode <- "en"
    }

    row <- dict[dict$entryKey == entryKey, ]

    if (nrow(row) == 0) {
      return(entryKey)
    }

    translation <- row[[languageCode]]

    if (is.null(translation) || is.na(translation) || translation == "") {
      translation <- row[["en"]]
    }

    if (is.null(translation) || is.na(translation) || translation == "") {
      entryKey
    } else {
      translation
    }
  },

  # translate data frame
  transDF = function(tdf, language, cols) {
    if (nrow(tdf) > 0) {
      for (col in cols) {
        transColName <- paste0(col, "_trans")
        tdf[, transColName] <- NA
      }

      for (i in 1:nrow(tdf)) {
        row <- tdf[i, ]
        for (col in cols) {
          langColName <- paste0(col, "_", language)
          transColName <- paste0(col, "_trans")
          langColValue <- row[[langColName]]
          if (!is.null(langColValue) && !is.na(langColValue)) {
            row[[transColName]] <- langColValue
          } else {
            row[[transColName]] <- row[[col]]
          }
        }

        tdf[i, ] <- data.frame(row)
      }
    }

    tdf
  }

)
