language = "en"
languageRecord = concerto.table.query("SELECT * FROM EASI_languages WHERE code='{{pLang}}'", list(pLang=l))
if(nrow(languageRecord) > 0) {
  language = languageRecord$code
}