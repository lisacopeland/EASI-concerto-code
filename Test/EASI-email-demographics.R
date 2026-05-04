#assumes that all participants are of same language

#SETTINGS START
mailgunDomain = Sys.getenv("MAILGUN_DOMAIN")
mailgunApiKey = Sys.getenv("MAILGUN_API_KEY")
mailgunApiUrl = Sys.getenv("MAILGUN_API_URL")
platformUrl = Sys.getenv("CONCERTO_PLATFORM_URL") #ends with /

from = "EASI tests <demographics@easitests.com>"
#SETTINGS END

library(httr)
success = T

if(is.list(participants)) {
  participants = data.frame(participants, stringsAsFactors=F)
}
participants = participants[!is.na(participants$email),]

while(nrow(participants) > 0) {
  languageCode = participants[1, "languageCode"]
  linkUrl = paste0(platformUrl, "test/demographics")
  subject = concerto$globals$easi$lib$translate("email_demographics_subject", languageCode)
  templateHtml = concerto.template.insertParams(
    concerto$globals$easi$lib$translate("email_demographics_body", languageCode),
    list(
      url=linkUrl,
      languageCode=languageCode
    ),
    F
  )
  vars = list()
  body = list()

  processedNum = 0
  leftNum = nrow(participants)
  for(i in leftNum:1) {
    participant = participants[i,]
    vars[[as.character(participant$email)]] = list(
      id=participant$id,
      demographicsToken=as.character(participant$demographicsToken)
    )
    body = append(body, list(
      to = participant$email
    ))

    processedNum = processedNum + 1
    participants = participants[-i,]
    if(processedNum == 1000) { break }
  }

  url = paste0(mailgunApiUrl,"/",mailgunDomain,"/messages")

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
}
