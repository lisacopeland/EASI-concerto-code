concerto.log(assessmentDate, "date")

getParticipantMonths = function(participant, assessmentDate) {
  days = as.numeric(difftime(as.POSIXct(assessmentDate, tz="UTC"), as.POSIXct(participant$dateOfBirth, tz="UTC")))
  round(days / 30.4375)
}

sessionTable = paste0(test$code, "_sessions")

participantMonths = getParticipantMonths(participant, assessmentDate)
concerto.table.query("UPDATE {{sessionTable}} SET participantMonths='{{participantMonths}}', dateAssessment='{{dateAssessment}}' WHERE id='{{id}}'", list(
  sessionTable=sessionTable,
  participantMonths=participantMonths,
  dateAssessment=assessmentDate,
  id=session$id
))
session = concerto.table.query("SELECT * FROM {{sessionTable}} WHERE id='{{id}}'", list(
  sessionTable=sessionTable, 
  id=session$id
))
session = as.list(session[1,])
