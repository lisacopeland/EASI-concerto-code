concerto.log("hi from EASI-scoring-aggr")
testCodes = trimws(unlist(strsplit(settings$aggrtestcodes, ",")))

traits = trimws(unlist(strsplit(settings$aggrtraits, ",")))

responses = responses[, c("score", "trait")]
for(trait in traits) {
  union = NULL
  for(testCode in testCodes) {
    if(testCode == test$code) { next }
    sql = concerto.table.insertParams("
(
SELECT r.score, r.trait COLLATE utf8_bin AS trait FROM {{testCode}}_responses AS r 
LEFT JOIN {{testCode}}_sessions AS s ON s.id=r.session_id
WHERE s.participant_id='{{participant_id}}' AND r.trait='{{trait}}'
)", list(
  testCode=testCode,
  participant_id=session$participant_id,
  trait=trait
))
    union = c(union, sql)
  }

  newResponses = concerto.table.query(paste0("SELECT ROUND(AVG(score)) AS score, trait FROM (", paste0(union, collapse=" UNION "), ") AS t1 GROUP BY trait"))
  responses = rbind(responses, newResponses)
}

scores = concerto.test.run("EASI-scoring-norm", list(
  items=items,
  responses=responses,
  scores=scores,
  session=session,
  settings=settings,
  test=test
))$scores
