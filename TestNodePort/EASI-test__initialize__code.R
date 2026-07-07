concerto.log("hi from initialize! Participant:")
concerto.log(
  jsonlite::toJSON(participant, pretty = TRUE, auto_unbox = TRUE)
)
lib$helloWorld()
concerto.log(
  jsonlite::toJSON(session, pretty = TRUE, auto_unbox = TRUE)
)

concerto.table.query(
  "UPDATE EASI_participants SET lastAssessmentDate=NOW() WHERE id='{{id}}'",
  list(id = participant$id)
)

getAgeYears <- function(dateOfBirth, assessmentDate) {
  dateOfBirth <- as.Date(dateOfBirth)
  assessmentDate <- as.Date(assessmentDate)

  round(
    as.numeric(assessmentDate - dateOfBirth) / 365.25,
    3
  )
}
#responses
responsesTable <- paste0(test$code, "_responses")
responses <- concerto.table.query(
  "SELECT * FROM {{responsesTable}} WHERE session_id='{{id}}'",
  list(responsesTable = responsesTable, id = session$id)
)

#scores
scoresTable <- paste0(test$code, "_scores")
scoresRecords <- concerto.table.query(
  "SELECT * FROM {{scoresTable}} WHERE session_id='{{id}}'",
  list(scoresTable = scoresTable, id = session$id)
)
scores <- list()
if (nrow(scoresRecords) > 0) {
  for (i in 1:nrow(scoresRecords)) {
    record <- scoresRecords[i, ]
    scores[[record$name]] <- record$value
  }
}

#items
itemTable <- paste0(test$code, "_items")
stemTransCol <- lib$getTransCol(itemTable, "stem", language)
questionTransCol <- lib$getTransCol(itemTable, "question", language)
optionLabel1TransCol <- lib$getTransCol(itemTable, "optionLabel1", language)
optionLabel2TransCol <- lib$getTransCol(itemTable, "optionLabel2", language)
optionLabel3TransCol <- lib$getTransCol(itemTable, "optionLabel3", language)
optionLabel4TransCol <- lib$getTransCol(itemTable, "optionLabel4", language)
optionLabel5TransCol <- lib$getTransCol(itemTable, "optionLabel5", language)
items <- concerto.table.query(
  "
SELECT 
*,
IFNULL({{stemTransCol}}, stem) stem_trans,
IFNULL({{questionTransCol}}, question) question_trans,
IFNULL({{optionLabel1TransCol}}, optionLabel1) optionLabel1_trans,
IFNULL({{optionLabel2TransCol}}, optionLabel2) optionLabel2_trans,
IFNULL({{optionLabel3TransCol}}, optionLabel3) optionLabel3_trans,
IFNULL({{optionLabel4TransCol}}, optionLabel4) optionLabel4_trans,
IFNULL({{optionLabel5TransCol}}, optionLabel5) optionLabel5_trans
FROM {{itemTable}} 
WHERE enabled=1",
  list(
    itemTable = itemTable,
    stemTransCol = stemTransCol,
    questionTransCol = questionTransCol,
    optionLabel1TransCol = optionLabel1TransCol,
    optionLabel2TransCol = optionLabel2TransCol,
    optionLabel3TransCol = optionLabel3TransCol,
    optionLabel4TransCol = optionLabel4TransCol,
    optionLabel5TransCol = optionLabel5TransCol
  )
)

if (nrow(responses) > 0) {
  answeredItemsIndices <- which(responses$item_id %in% items$id)
  answeredItems <- items[answeredItemsIndices, ]
  unansweredItems <- items[-answeredItemsIndices, ]
  unansweredItems <- unansweredItems[unansweredItems$enabled == 1, ]
  items <- rbind(answeredItems, unansweredItems)
}

#settings
settings <- list(
  itemsperpage = test$itemsPerPage,
  scoringalgo = test$scoringAlgo,
  itemselectionalgo = test$itemSelectionAlgo,
  stopalgo = test$stopAlgo,
  cangoback = test$canGoBack
)

#default settings
if (is.na(settings$itemsperpage)) {
  settings$itemsperpage <- nrow(items)
}

settingsTable <- paste0(test$code, "_settings")
extraSettings <- concerto.table.query(
  "
SELECT * FROM {{settingsTable}} 
WHERE (minParticipantMonths<='{{months}}' OR minParticipantMonths IS NULL) AND
(maxParticipantMonths>='{{months}}' OR maxParticipantMonths IS NULL)",
  list(settingsTable = settingsTable, months = session$participantMonths)
)

if (nrow(extraSettings) > 0) {
  for (i in 1:nrow(extraSettings)) {
    extraSetting <- as.list(extraSettings[i, ])
    settings[[tolower(extraSetting$name)]] <- extraSetting$value
  }
}

if (test$scoringAlgo == "new") {
  settingsTableNew <- paste0(test$code, "_settings_new")
  extraSettingsNew <- concerto.table.query(
    "SELECT * FROM {{settingsTableNew}}",
    list(settingsTableNew = settingsTableNew)
  )

  childsAge <- getAgeYears(participant$dateOfBirth, session$dateAssessment)
  settings$childsAge <- childsAge

  settings$scoreSettings <- list()

  for (i in seq_len(nrow(extraSettingsNew))) {
    row <- as.list(extraSettingsNew[i, ])
    row$id <- NULL
    names(row) <- tolower(names(row))

    trait <- row$trait
    row$trait <- NULL

    settings$scoreSettings[[i]] <- row
  }
}

concerto.log("hi from initialize, settings:")
concerto.log(
  jsonlite::toJSON(settings, pretty = TRUE, auto_unbox = TRUE)
)

.branch <- "intro"
instructionsAvailable <- 1
if (is.na(test$instructionsTranscript) && is.na(test$instructionsFile)) {
  .branch <- "assessment"
  instructionsAvailable <- 0
}
