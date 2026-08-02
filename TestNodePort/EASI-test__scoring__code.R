concerto.log("hi from EASI-test__scoring__code.R")

# TODO: maybe add an error message or something to settings to flag whether the response
# processing code found an error in the responses - if there was, don't produce scores
if (!is.na(settings$scoringalgo) && settings$scoringalgo != "") {
  scoringModuleName <- paste0("EASI-scoring-", settings$scoringalgo)
  # if this is the
  scoringResult <- concerto.test.run(scoringModuleName, list(
    items = items,
    responses = responses,
    settings = settings,
    scores = scores,
    session = session,
    test = test
  ))
  concerto.log("scoringResult: ")
  concerto.log(
    jsonlite::toJSON(scoringResult, pretty = TRUE, auto_unbox = TRUE)
  )
  scores <- scoringResult$scores
} else {
  scores <- list(
    "raw score" = sum(responses$score, na.rm = T)
  )
}

concerto.log("*****SCORES*****")

concerto.log(
  jsonlite::toJSON(scores, pretty = TRUE, auto_unbox = TRUE)
)


# cleaning past scores
scoresTable <- paste0(test$code, "_scores")
concerto.table.query("DELETE FROM {{scoresTable}} WHERE session_id='{{session_id}}'", list(scoresTable = scoresTable, session_id = session$id))

# adding latest scores

if (is.list(scores) && length(scores) > 0) {
  insertSql <- concerto.table.insertParams("INSERT INTO {{scoresTable}} (session_id, name, value, timeCreated, participant_id) VALUES ", list(scoresTable = scoresTable))
  scoreValuesSqlArray <- NULL
  for (scoreName in names(scores)) {
    scoreValuesSql <- concerto.table.insertParams("('{{session_id}}', '{{name}}', IF('{{value}}'='', NULL, '{{value}}'), NOW(), '{{participant_id}}')", list(
      session_id = session$id,
      name = scoreName,
      value = scores[[scoreName]],
      participant_id = session$participant_id
    ))
    scoreValuesSqlArray <- c(scoreValuesSqlArray, scoreValuesSql)
  }

  insertSql <- paste0(insertSql, paste0(scoreValuesSqlArray, collapse = ","))
  concerto.table.query(insertSql)
}
