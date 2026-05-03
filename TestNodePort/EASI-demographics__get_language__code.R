validLang = "en"
languageRecord = concerto.table.query("SELECT * FROM EASI_languages WHERE code='{{pLang}}'", list(pLang=l))
if(nrow(languageRecord) > 0) {
  validLang = languageRecord$code
}

l = validLang