concerto.log("hi from EASI-test__scoring__code.R")

calcScores <- function(scoringAlgo, responses, items, settings) {
  scoringModuleName <- paste0("EASI-scoring-", scoringAlgo)
  # if this is the
  scoringResult <- concerto.test.run(scoringModuleName, list(
    items = items,
    responses = responses,
    settings = settings,
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

scores <- calcScores(settings$scoringAlgo, responses, items, settings)

updateScoreTable(test$code, session$id, session$participant_id, scores)

# to do composite:
# see if this test has composite
# if (test$compositeGroup)
# get all tests for this composite
# select from EASI_tests where compositeGroup == test$compositeGroup
# tests for Each
# SELECT *
# FROM test$code_sessions
# WHERE participant_Id = session$participant_id and status = 2
# ORDER BY dateAssessment DESC
# LIMIT 1;
# you have to get at least one session for each test
# if you got them,
# select * from compositeGroup settings table and load into a settings object
# get the items for all the tests
# get the responses for each of those sessions
# for each composite trait -
# - for each test
# -   get the items and responses for that trait
# - combine the list of items and responses
# settings forEach
# (test items from all three tests, responses from all three tests)
# settings will be for all three traits
# run calcScore on that list with those settings
# scores columns will include the session id for each test, prp_sessionId, etc
# write the scores to the composite score table
