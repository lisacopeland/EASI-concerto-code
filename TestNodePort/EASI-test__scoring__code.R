concerto.log("hi from EASI-test__scoring__code.R")

calcScores <- function(scoringAlgo, responses, items, settings) {
  scoringModuleName <- paste0("EASI-scoring-", scoringAlgo)

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
scores <- calcScores(test$scoringAlgo, responses, items, settings)

if (is.null(scores)) {
  concerto.log("No scores returned from scoring module")
  scores <- list()
} else {
  updateScoreTable(test$code, session$id, session$participant_id, scores)
}

if (!is.null(test$compositeGroup) && test$compositeGroup != "") {
  concerto.log("hi from test scoring code - going to invoke composite scoring")
  runCompositeScoring(settings, session$participant_id, test$compositeGroup)
}
