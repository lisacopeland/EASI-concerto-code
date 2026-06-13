concerto.log("hi from EASI-test__scoring__code.R")

if(!is.na(settings$scoringalgo)) {
  scoringModuleName = paste0("EASI-scoring-", settings$scoringalgo)
  scores = concerto.test.run(scoringModuleName, list(
    items=items,
    responses=responses,
    settings=settings,
    scores=scores,
    session=session,
    test=test
  ))$scores
} else {
  scores = list(
    "raw score" = sum(responses$score, na.rm=T)
  )
}

#cleaning past scores
scoresTable = paste0(test$code, "_scores")
concerto.table.query("DELETE FROM {{scoresTable}} WHERE session_id='{{session_id}}'", list(scoresTable=scoresTable, session_id=session$id))

#adding latest scores

if(is.list(scores) && length(scores) > 0) {
  insertSql = concerto.table.insertParams("INSERT INTO {{scoresTable}} (session_id, name, value, timeCreated, participant_id) VALUES ", list(scoresTable=scoresTable))
  scoreValuesSqlArray = NULL
  for(scoreName in ls(scores)) {
    scoreValuesSql = concerto.table.insertParams("('{{session_id}}', '{{name}}', IF('{{value}}'='', NULL, '{{value}}'), NOW(), '{{participant_id}}')", list(
      session_id=session$id,
      name=scoreName,
      value=scores[[scoreName]],
      participant_id=session$participant_id
    ))
    scoreValuesSqlArray = c(scoreValuesSqlArray, scoreValuesSql)
  }

  insertSql = paste0(insertSql, paste0(scoreValuesSqlArray, collapse=","))
  concerto.table.query(insertSql)
}
