languageQuery = lang

validLang = "en"
languageRecord = concerto.table.query("SELECT * FROM EASI_languages WHERE code='{{pLang}}'", list(pLang=lang))
if(nrow(languageRecord) > 0) {
  validLang = languageRecord$code
}

lang = validLang
