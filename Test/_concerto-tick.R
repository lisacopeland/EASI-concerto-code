batchSize = 5

###

generate = function(ids, cols, admin, filePath) {
  concerto.log("*****hi from generate****")
  concerto.log(filePath, "filePath before write")
  ids = paste0(as.numeric(ids), collapse = ",")

  participantCols = NULL
  validParticipantCols = c(
    "id", 
    "customId", 
    "dateOfBirth", 
    "countryOfResidence", 
    "gender", 
    "languageCode", 
    "diagnoses", 
    "diagnosesSelected", 
    "initials", 
    "email", 
    "assessmentReason", 
    "clinicalAssessmentReferrer", 
    "researchProjectSelected", 
    "researchGroup"
  )

  for(col in ls(cols)) {
    if(col %in% validParticipantCols && cols[col] == 'true') {
      participantCols = c(participantCols, col)
    }
  }

  params = list(
    ids = ids,
    admin_id = admin$id,
    admin_researchGroup = admin$researchGroup,
    participantCols = paste0(participantCols, collapse=", ")
  )

  participantsSql = "SELECT {{participantCols}} FROM EASI_participants"

  if (admin$type == 0) {
    participantsSql = paste0(participantsSql, " WHERE exportExclusion=0 AND id IN ({{ids}}) AND admin_id='{{admin_id}}'")
  }
  if (admin$type == 1) {
    participantsSql = paste0(participantsSql, " WHERE exportExclusion=0 AND id IN ({{ids}})")
  }
  if (admin$type == 2) {
    participantsSql = paste0(participantsSql, " WHERE exportExclusion=0 AND id IN ({{ids}}) AND (admin_id='{{admin_id}}' OR researchGroup='{{admin_researchGroup}}')")
  }
  participants = concerto.table.query(participantsSql, params)
  if(nrow(participants) == 0) {
    return(F)
  }

  params$ids = paste0(as.numeric(participants$id), collapse = ",")

  testCodes = concerto.table.query("SELECT code FROM EASI_tests ORDER BY orderIndex ASC")[, 1]
  filteredTestCodes = NULL
  for(testCode in testCodes) {
    if(testCode %in% ls(cols) && cols[testCode] == 'true') {
      filteredTestCodes = c(filteredTestCodes, testCode)
    }
  }
  testCodes = filteredTestCodes
  if(is.null(testCodes) && (cols['testAdmin'] == 'true' || cols['testResponses'] == 'true' || cols['testScores'] == 'true')) {
    return(F)
  }

  if(cols['testAdmin'] == 'true' | cols['testScores'] == 'true') {
    scoresSql = paste0(
      "SELECT '", testCodes, "' COLLATE utf8_bin AS testCode, session_id, s.name COLLATE utf8_bin AS name, value COLLATE utf8_bin AS value, s.participant_id, a.id AS admin_id, a.login AS admin_login
FROM ", testCodes, "_scores AS s 
LEFT JOIN ", testCodes, "_sessions AS se ON se.id=s.session_id
LEFT JOIN EASI_admins AS a ON a.id=se.admin_id
WHERE s.participant_id IN ({{ids}}) AND session_id = (SELECT MAX(session_id) FROM ", testCodes, "_scores WHERE participant_id=s.participant_id)")
    scoresSql = paste0(
      "SELECT * FROM (", 
      paste0(scoresSql, collapse = " UNION ALL "),
      ") t ORDER BY testCode, name"
    )
    scores = concerto.table.query(scoresSql, params)
    concerto.log(nrow(scores), "scores num")
    if(nrow(scores) == 0) {
      return(F)
    }
  }

  responsesSql = paste0(
    "SELECT '", testCodes, "' COLLATE utf8_bin AS testCode, 
r.session_id, 
r.item_id, 
CASE
WHEN r.value COLLATE utf8_bin = i.optionValue1 COLLATE utf8_bin THEN i.optionLabel1 COLLATE utf8_bin
WHEN r.value COLLATE utf8_bin = i.optionValue2 COLLATE utf8_bin THEN i.optionLabel2 COLLATE utf8_bin
WHEN r.value COLLATE utf8_bin = i.optionValue3 COLLATE utf8_bin THEN i.optionLabel3 COLLATE utf8_bin
WHEN r.value COLLATE utf8_bin = i.optionValue4 COLLATE utf8_bin THEN i.optionLabel4 COLLATE utf8_bin
WHEN r.value COLLATE utf8_bin = i.optionValue5 COLLATE utf8_bin THEN i.optionLabel5 COLLATE utf8_bin
END label,
r.score, 
r.skipped, 
se.participant_id
FROM ", testCodes, "_responses AS r 
LEFT JOIN ", testCodes, "_sessions AS se ON se.id=r.session_id
LEFT JOIN ", testCodes, "_items AS i ON i.id=r.item_id
WHERE se.participant_id IN ({{ids}}) AND session_id = (SELECT MAX(session_id) FROM ", testCodes, "_responses LEFT JOIN ", testCodes, "_sessions as ses on ses.id=session_id WHERE ses.participant_id=se.participant_id)")
  responsesSql = paste0(
    "SELECT * FROM (", 
    paste0(responsesSql, collapse = " UNION ALL "),
    ") t ORDER BY testCode, item_id"
  )
  responses = concerto.table.query(responsesSql, params)
  concerto.log(nrow(responses), "responses num")

  concerto.log("creating data frame input...")
  dfi = list()
  for(name in ls(participants)) {
    dfi[[name]] = participants[[name]]
  }

  cellDefault = NA
  colIndex = length(dfi)
  adminColIndexOffset = 0
  lastTestCode = ''
  lastScoreName = ''
  lastItemId = 0

  if(cols['testAdmin'] == 'true' | cols['testScores'] == 'true') {
    for(i in 1:nrow(scores)) {
      score = scores[i,]
      participantIndex = which(participants$id==score$participant_id)

      if(score$testCode != lastTestCode) {
        if(cols['testAdmin'] == 'true') {
          dfi[[paste0(score$testCode, ": admin_id")]] = rep(cellDefault, nrow(participants))
          dfi[[paste0(score$testCode, ": admin_login")]] = rep(cellDefault, nrow(participants))

          colIndex = colIndex + 2
          adminColIndexOffset = 0
        }

        lastTestCode = score$testCode
      }

      if(score$name != lastScoreName) {
        if(cols['testScores'] == 'true') {
          dfi[[paste0(score$testCode, ": ", score$name)]] = rep(cellDefault, nrow(participants))

          colIndex = colIndex + 1
          adminColIndexOffset = adminColIndexOffset + 1
        }

        lastScoreName = score$name
      }

      if(cols['testAdmin'] == 'true') {
        dfi[[colIndex - adminColIndexOffset - 1]][[participantIndex]] = score$admin_id
        dfi[[colIndex - adminColIndexOffset]][[participantIndex]] = score$admin_login
      }
      if(cols['testScores'] == 'true') {
        dfi[[colIndex]][[participantIndex]] = score$value
      }
    }
  }

  if(cols['testResponses'] == 'true') {
    for (i in 1:nrow(responses)) {
      response = responses[i,]
      participantIndex = which(participants$id==response$participant_id)

      if(response$testCode != lastTestCode || response$item_id != lastItemId) {
        dfi[[paste0(response$testCode, ": item #", response$item_id, " response label")]] = rep(cellDefault, nrow(participants))
        dfi[[paste0(response$testCode, ": item #", response$item_id, " response score")]] = rep(cellDefault, nrow(participants))
        dfi[[paste0(response$testCode, ": item #", response$item_id, " response skipped")]] = rep(cellDefault, nrow(participants))

        colIndex = colIndex + 3
        lastTestCode = response$testCode
        lastItemId = response$item_id
      }

      dfi[[colIndex - 2]][[participantIndex]] = response$label
      dfi[[colIndex - 1]][[participantIndex]] = response$score
      dfi[[colIndex]][[participantIndex]] = response$skipped
    }
  }

  concerto.log("creating data frame...")
  result = data.frame(dfi, check.rows=F, check.names=F, fix.empty.names=F)
  concerto.log(dim(result), "data frame dimensions")

  concerto.log("saving CSV...")

  write.csv(result, filePath, row.names = F, na = "")
  T
}

###

queue = concerto.table.query("SELECT * FROM EASI_export_queue WHERE status=0 LIMIT {{batchSize}}", list(batchSize=batchSize))
if(nrow(queue) > 0) {
  concerto.table.query("UPDATE EASI_export_queue SET status=1 WHERE id IN ({{ids}})", list(ids=paste0(queue$id, collapse=",")))

  for(i in 1:nrow(queue)) {
    export = queue[i,]

    # admin = as.list(concerto.table.query("SELECT * FROM EASI_admin WHERE id='{{id}}'", list(id=export$admin_id))[1,])
    adminQuery = concerto.table.query(
  "SELECT * FROM EASI_admins WHERE id='{{id}}'",
  list(id=export$admin_id)
)

concerto.log(nrow(adminQuery), "admin rows from EASI_admins")

if(nrow(adminQuery) == 0) {
  concerto.log(export$admin_id, "admin NOT FOUND in EASI_admins")
  return(FALSE)
}

admin = as.list(adminQuery[1,])
    args = fromJSON(export$args)
    ids = args$participants
    cols = args$cols

    filename = export$filename
    session = concerto.table.query("SELECT hash FROM TestSession WHERE id='{{id}}'", list(id=export$session_id))
    # filePath = paste0("/data/sessions/", session$hash, "/", filename)
    dirPath = paste0("/data/sessions/", session$hash, "/files")
if(!dir.exists(dirPath)) {
  dir.create(dirPath, recursive = TRUE, showWarnings = FALSE)
}
filePath = paste0(dirPath, "/", filename)
    concerto.log(filePath)

    success = generate(ids, cols, admin, filePath)
    concerto.log(success, "generation status")
    status = if(success) { 2 } else { -1 }
    concerto.table.query("UPDATE EASI_export_queue SET status='{{status}}' WHERE id='{{id}}'", list(id=export$id, status=status))
  }
}