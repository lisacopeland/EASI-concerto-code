concerto.log("Hi from update session")
sessionTable <- paste0(test$code, "_sessions")

participantMonths <- concerto$globals$easi$lib$getParticipantMonths(participant$dateOfBirth, assessmentDate)
concerto.table.query("UPDATE {{sessionTable}} SET participantMonths='{{participantMonths}}', dateAssessment='{{dateAssessment}}' WHERE id='{{id}}'", list(
  sessionTable = sessionTable,
  participantMonths = participantMonths,
  dateAssessment = assessmentDate,
  id = session$id
))
session <- concerto.table.query("SELECT * FROM {{sessionTable}} WHERE id='{{id}}'", list(
  sessionTable = sessionTable,
  id = session$id
))
session <- as.list(session[1, ])
