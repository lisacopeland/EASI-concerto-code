dictionary = c.get("dictionary", global=T)
languages = concerto.table.query("SELECT * FROM EASI_languages WHERE enabled=1 ORDER BY label ASC")

event = function(params) {
  objDictionary = list()
  for(i in 1:nrow(dictionary)) {
    entry = dictionary[i,]
    objDictionary[[entry$entryKey]] = entry$trans
  }
  concerto$templateParams$dictionary <<- objDictionary
  concerto$templateParams$language <<- language
  concerto$templateParams$languages <<- languages
}

concerto.event.add("onBeforeTemplateShow", event)