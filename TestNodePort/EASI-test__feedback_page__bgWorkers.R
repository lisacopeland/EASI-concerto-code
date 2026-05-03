test = c.get("test")
participant = c.get("participant")

fetchScores = function(query) {
  concerto.log(query, "QUERY")

  params = list(
    scoresTable = paste0(test$code, "_scores"),
    participant_id=participant$id,
    hiddenScores=test$hiddenScores
  )

  sql = "
SELECT name COLLATE utf8_bin AS name, value, timeCreated FROM {{scoresTable}} 
WHERE participant_id='{{participant_id}}' AND
('{{hiddenScores}}'='' OR !JSON_CONTAINS('{{hiddenScores}}',JSON_QUOTE(name)))
"
  sql = concerto.table.insertParams(sql, params)

  #where clause - metric
  metricSelected = query$allMetrics == 1
  sqlWhereMetric = "1"
  if(query$allMetrics == 0 && length(query$metrics) > 0)  {
    namesSql = NULL
    for(name in ls(query$metrics)) {
      if(query$metrics[[name]] == 0) { next }

      metricSelected = T
      namesSql = c(namesSql, concerto.table.insertParams("'{{name}}'", list(name=name)))
    }

    if(metricSelected) {
      sqlWhereMetric = paste0("name IN (",paste0(namesSql, collapse=", "),")")
    }
  }

  #collection
  collection = NULL
  metrics = NULL
  if(metricSelected) {
    sqlCollection = paste0("
SELECT *, UNIX_TIMESTAMP(timeCreated) AS timestamp FROM (", paste0(sql, collapse=" UNION "), ") AS tu
WHERE ",sqlWhereMetric,"
ORDER BY timeCreated ASC")
    collection = concerto.table.query(sqlCollection)
  }

  #metrics
  sqlMetrics = paste0("SELECT DISTINCT name FROM (", paste0(sql, collapse=" UNION "), ") AS tu")
  metrics = as.list(concerto.table.query(sqlMetrics)$name)

  list(
    collection=collection,
    metrics=metrics
  )
}

list(
  fetchScores = function(response) {
    result = fetchScores(response)
  }
)