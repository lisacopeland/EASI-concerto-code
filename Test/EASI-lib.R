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

lib <- list(
  helloWorld = function() {
    concerto.log("hello from hello world")
    "hello"
  },
  oldTranslate = function(entryKey, languageCode) {
    if (languageCode == "") {
      languageCode <- "en"
    }
    columns <- concerto.table.query(
      "SHOW COLUMNS FROM `EASI_translation_dictionary` LIKE '{{languageCode}}'",
      list(languageCode = languageCode)
    )
    concerto.log(columns, "COLUMNS")
    if (nrow(columns) == 0) {
      languageCode <- "en"
    }

    result <- concerto.table.query(
      "SELECT entryKey, IF({{languageCode}} IS NOT NULL, {{languageCode}}, en) AS translation FROM EASI_translation_dictionary WHERE entryKey='{{entryKey}}'",
      list(entryKey = entryKey, languageCode = languageCode)
    )
    if (nrow(result) == 0) {
      entryKey
    } else {
      result$translation
    }
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

  #translate data frame
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
  },

  oldGetTransCol = function(table, col, language) {
    transColName <- paste0(col, "_", language)
    result <- concerto.table.query(
      "SHOW COLUMNS FROM `{{table}}` WHERE Field='{{transColName}}'",
      list(table = table, transColName = transColName)
    )
    if (nrow(result) > 0) {
      transColName
    } else {
      col
    }
  }
)
