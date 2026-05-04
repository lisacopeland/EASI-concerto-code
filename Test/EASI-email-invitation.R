#assumes that all participants are of same language

#SETTINGS START
mailgunDomain = Sys.getenv("MAILGUN_DOMAIN")
mailgunApiKey = Sys.getenv("MAILGUN_API_KEY")
mailgunApiUrl = Sys.getenv("MAILGUN_API_URL")
platformUrl = Sys.getenv("CONCERTO_PLATFORM_URL") #ends with /

from = "EASI Tests <invitation@easitests.com>"
#SETTINGS END

concerto.log(mailgunApiKey, "mailgunApiKey")

library(httr)
success = T

if(is.list(sessions)) {
  sessions = data.frame(sessions, stringsAsFactors=F)
}
sessions = sessions[!is.na(sessions$email),]

if(nrow(sessions) > 0) {
  languageCode = sessions[1, "languageCode"]
  #languageCode is not part of session so it's not guaranteed that it's going to be available here
  if(is.null(languageCode)) {
    languageCode = concerto.table.query("SELECT languageCode FROM EASI_participants WHERE id='{{participant_id}}' LIMIT 1", list(
      participant_id=sessions[1, "participant_id"]
    ))[1,1]
  }
  concerto.log(languageCode, "languageCode")

  while(nrow(sessions) > 0) {
    linkUrl = paste0(platformUrl, "test/start")
    subject = concerto$globals$easi$lib$translate("email_invitation_default_subject", languageCode)

    params = list(
      url=linkUrl,
      languageCode=languageCode
    )

    templateHtml = concerto.template.insertParams(
      concerto$globals$easi$lib$translate('email_invitation_default_body', languageCode),
      params,
      F
    )
    vars = list()
    body = list()

    processedNum = 0
    leftNum = nrow(sessions)
    for(i in leftNum:1) {
      session = sessions[i,]
      vars[[session$email]] = list(
        testId=session$testId,
        sessionId=session$id,
        sessionToken=session$token
      )
      body = append(body, list(
        to = session$email
      ))

      processedNum = processedNum + 1
      sessions = sessions[-i,]
      if(processedNum == 1000) { break }
    }

    url = paste0(mailgunApiUrl,"/",mailgunDomain,"/messages")

    #test overrides
    test = concerto.table.query("SELECT * FROM EASI_tests WHERE id='{{id}}'", list(id=session$testId))
    test = concerto$globals$easi$lib$transDF(test, languageCode, c("invitationEmailBody", "invitationEmailSubject"))  
    if(!is.na(test$invitationEmailSubject_trans)) {
      subject = concerto.template.insertParams(
        concerto$globals$easi$lib$translate(test$invitationEmailSubject_trans, languageCode),
        params,
        F
      )
    }
    if(!is.na(test$invitationEmailBody_trans)) {
      templateHtml = concerto.template.insertParams(
        concerto$globals$easi$lib$translate(test$invitationEmailBody_trans, languageCode),
        params,
        F
      )
    }

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
}
