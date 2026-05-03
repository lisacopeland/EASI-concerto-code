.branch = "unauthorized"

#test
titleTransCol = lib$getTransCol("EASI_tests", "title", language)
instructionsFileTransCol = lib$getTransCol("EASI_tests", "instructionsFile", language)
instructionsTranscriptTransCol = lib$getTransCol("EASI_tests", "instructionsTranscript", language)
feedbackInfoTransCol = lib$getTransCol("EASI_tests", "feedbackInfo", language)
test = concerto.table.query("
SELECT 
*,
IFNULL({{titleTransCol}}, title) title_trans,
IFNULL({{instructionsFileTransCol}}, instructionsFile) instructionsFile_trans,
IFNULL({{instructionsTranscriptTransCol}}, instructionsTranscript) instructionsTranscript_trans,
IFNULL({{feedbackInfoTransCol}}, feedbackInfo) feedbackInfo_trans
FROM EASI_tests WHERE id='{{id}}'", list(
  id=test_id,
  titleTransCol=titleTransCol,
  instructionsFileTransCol=instructionsFileTransCol,
  instructionsTranscriptTransCol=instructionsTranscriptTransCol,
  feedbackInfoTransCol=feedbackInfoTransCol
))

if(nrow(test) == 1) {
  test = as.list(test[1,])
  
  #session
  sessionTable = paste0(test$code, "_sessions")

  session = concerto.table.query("SELECT * FROM {{sessionTable}} WHERE id='{{id}}' AND token='{{token}}'", list(
    id=session_id,
    token=session_token,
    sessionTable=sessionTable
  ))

  if(nrow(session) == 1) {
    session = as.list(session[1,])

    #participant
    participant = concerto.table.query("SELECT * FROM EASI_participants WHERE id='{{id}}'", list(id=session$participant_id))
    if(nrow(participant) == 1) {
      participant = as.list(participant)

      if(session$status == 0) {
        concerto.table.query("UPDATE {{sessionTable}} SET timeStarted=NOW(), status=1, admin_id=IF('{{pAdmin_id}}'='', NULL, '{{pAdmin_id}}') WHERE id='{{id}}'", list(
          sessionTable=sessionTable,
          pAdmin_id=admin_id,
          id=session_id
        ))
        session = concerto.table.query("SELECT * FROM {{sessionTable}} WHERE id='{{id}}'", list(sessionTable=sessionTable, id=session_id))
        session = as.list(session[1,])
      } 
      .branch = "authorized"
    }
  }
}