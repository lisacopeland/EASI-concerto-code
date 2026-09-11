transColumnCache <- list()
translationCache <- list()
translationDictionaryCache <- NULL

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

isValid <- function(trait) {
  !is.null(trait) && !is.na(trait) && length(trait) > 0
}

lib <- list(
  isValid = isValid,
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
  },
  getTransCol = function(table, col, language) {
    tableCols <- getTableColumns(table)

    transColName <- paste0(col, "_", language)
    if (transColName %in% tableCols) {
      transColName
    } else {
      col
    }
  }
)
