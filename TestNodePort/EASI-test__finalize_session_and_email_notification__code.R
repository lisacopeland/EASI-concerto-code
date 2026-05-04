concerto.log(endReason, "end reason")

sessionTable = paste0(test$code, "_sessions")
concerto.table.query("UPDATE {{sessionTable}} SET status=2, statusDescription='{{reason}}', timeFinished=NOW() WHERE id='{{id}}'", list(sessionTable=sessionTable, reason=endReason, id=session$id))

concerto.test.run("EASI-email-test-completed", list(
  participant=participant,
  test=test
))
