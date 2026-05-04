clients = concerto.table.query("SELECT DISTINCT language FROM EASI_participants WHERE language IS NOT NULL AND languageCode IS NULL")
for(i in 1:nrow(clients)) {
  languageLabel = clients[i, "language"]
  language = concerto.table.query("SELECT * FROM EASI_languages WHERE label='{{languageLabel}}' LIMIT 1", list(languageLabel=languageLabel))
  if(nrow(language) > 0) {
    concerto.table.query("UPDATE EASI_participants SET languageCode='{{languageCode}}' WHERE language='{{languageLabel}}' AND languageCode IS NULL", list(languageCode=language$code, languageLabel=languageLabel))
  }
}
