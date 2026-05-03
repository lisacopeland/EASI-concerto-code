#SETTINGS START
mailgunDomain = Sys.getenv("MAILGUN_DOMAIN")
mailgunApiKey = Sys.getenv("MAILGUN_API_KEY")
mailgunApiUrl = Sys.getenv("MAILGUN_API_URL")
platformUrl = Sys.getenv("CONCERTO_PLATFORM_URL") #ends with /

from = "EASI Tests <notifications@easitests.com>"
#SETTINGS END

library(httr)
success = T

admin = concerto.table.query("SELECT * FROM EASI_admins WHERE id='{{id}}'", list(id=participant$admin_id))
if(is.na(admin$email)) {
  return()
}

languageCode = admin$languageCode
if(is.na(languageCode)) { languageCode = "en" }

defaultSubject = concerto$globals$easi$lib$translate('email_demographics_completed_subject', languageCode)
defaultTemplateHtml = concerto.template.insertParams(
  concerto$globals$easi$lib$translate('email_demographics_completed_body', languageCode),
  list(
    participantCustomId=participant$customId
  ),
  F
)
vars = list()
body = list()

vars[[admin$email]] = list()
body = append(body, list(
  to = admin$email
))

url = paste0(mailgunApiUrl,"/",mailgunDomain,"/messages")

subject = defaultSubject
templateHtml = defaultTemplateHtml

body = append(body, list(
  "from" = from,
  "subject" = subject,
  "html" = templateHtml,
  "recipient-variables" = toJSON(vars)
))
concerto.log(body, "body")
config = add_headers(
  .headers=unlist(list(
    Authorization=paste0("Basic ", mailgunApiKey)
  ))
)

response = POST(url, config, body=body, encode="form")
concerto.log(response$status_code, "status code")
concerto.log(content(response), "response content")

if(response$status_code != 200) {
  success = F
  break
}