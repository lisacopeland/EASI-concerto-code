concerto.log("hi from EASI-test__scoring__code.R")
concerto.log("settings: ")
concerto.log(
  jsonlite::toJSON(settings, pretty = TRUE, auto_unbox = TRUE)
)
runCompositeScoring <- function(settings, participant_id, compositeGroup) {
  scoringModuleName <- "EASI-scoring-composite"
  concerto.log("hi from run composite scoring, here we go!")
  scoringResult <- concerto.test.run(scoringModuleName, list(
    settings = settings,
    participant_id = participant_id,
    compositeGroup = compositeGroup
  ))
}

items$test <- test$code
responses$test <- test$code
scores <- concerto$globals$easi$lib$calcScores(responses, items, settings)

if (is.null(scores)) {
  concerto.log("No scores returned from scoring module")
  scores <- list()
} else {
  concerto$globals$easi$lib$updateScoreTable(test$code, session$id, settings$participantId, scores)
}

if (
  !is.null(test$compositeGroup) &&
    !is.na(test$compositeGroup) &&
    test$compositeGroup != ""
) {
  settings$testIteration <- session$testIteration
  concerto.log("hi from test scoring code - going to invoke composite scoring")
  runCompositeScoring(settings, session$participant_id, test$compositeGroup)
}
