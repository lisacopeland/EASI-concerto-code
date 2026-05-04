labelTransCol = lib$getTransCol("EASI_demographics_fields", "label", language)
fields = concerto.table.query("
SELECT 
*,
IFNULL({{labelTransCol}}, label) label_trans
FROM EASI_demographics_fields", list(labelTransCol=labelTransCol))

labelTransCol = lib$getTransCol("EASI_diagnoses", "label", language)
diagnoses = concerto.table.query("
SELECT 
*,
IFNULL({{labelTransCol}}, label) label_trans
FROM EASI_diagnoses", list(labelTransCol=labelTransCol))

labelTransCol = lib$getTransCol("EASI_ethnicities", "label", language)
ethnicities = concerto.table.query("
SELECT 
*,
IFNULL({{labelTransCol}}, label) label_trans
FROM EASI_ethnicities", list(labelTransCol=labelTransCol))

collections = list(
  diagnoses = diagnoses$label_trans,
  ethnicities = ethnicities$label_trans
)
