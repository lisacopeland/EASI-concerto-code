concerto$globals$easi <<- list(
  lib = lib
)

htmlTransCol = lib$getTransCol("EASI_content", "html", language)
records = concerto.table.query("
SELECT 
*,
IFNULL({{htmlTransCol}}, html) html_trans
FROM EASI_content", list(htmlTransCol=htmlTransCol))

content = list()
for(i in 1:nrow(records)) {
  row = as.list(records[i,])
  content[[row$section]] = row
}

labelTransCol = lib$getTransCol("EASI_diagnoses", "label", language)
diagnoses = concerto.table.query("
SELECT 
*,
IFNULL({{labelTransCol}}, label) label_trans
FROM EASI_diagnoses
ORDER BY label_trans ASC", list(labelTransCol=labelTransCol))

labelTransCol = lib$getTransCol("EASI_researchProjects", "label", language)
researchProjects = concerto.table.query("
SELECT 
*,
IFNULL({{labelTransCol}}, label) label_trans
FROM EASI_researchProjects
ORDER BY label_trans ASC", list(labelTransCol=labelTransCol))

languages = concerto.table.query("SELECT * FROM EASI_languages ORDER BY label ASC")
collections = list(
  diagnoses = diagnoses,
  researchProjects = researchProjects,
  languages = languages
)
