assessmentDate = NULL
tests = concerto.table.query("SELECT id, code FROM EASI_tests")
if(nrow(tests) > 0) {
  sessionSql = NULL
  for(i in 1:nrow(tests)) {
    test = tests[i,]
    sessionTable = paste0(test$code, "_sessions")

    sessionSql = c(
      sessionSql, 
      concerto.table.insertParams("
SELECT id, dateAssessment, timeStarted
FROM {{sessionTable}} 
WHERE participant_id='{{participant_id}}' AND dateAssessment IS NOT NULL
", list(sessionTable=sessionTable, participant_id=participant$id))
    )
  }

  result = concerto.table.query(paste0("
SELECT t.id, t.dateAssessment, t.timeStarted
FROM (",paste0(sessionSql, collapse = "UNION"),") AS t
ORDER BY t.timeStarted DESC LIMIT 1"))

  if(nrow(result) > 0) {
    assessmentDate = result$dateAssessment
  }
}
concerto.log(assessmentDate, "last date")

if(is.na(session$participantMonths)) { 
  .branch = "no"
} else { 
  .branch = "yes"
}
