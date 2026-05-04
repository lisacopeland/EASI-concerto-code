feedbackTable = paste0(test$code, "_feedback")
feedbackTransCol = lib$getTransCol(feedbackTable, "feedback", language)
feedback = concerto.table.query("
SELECT 
*,
IFNULL({{feedbackTransCol}}, feedback) feedback_trans
FROM {{feedbackTable}} 
WHERE (minParticipantMonths<='{{months}}' OR minParticipantMonths IS NULL) AND
(maxParticipantMonths>='{{months}}' OR maxParticipantMonths IS NULL)", list(
  feedbackTable=feedbackTable, 
  months=session$participantMonths,
  feedbackTransCol=feedbackTransCol
))
