getEnvOrFail <- function(name) {
  value <- Sys.getenv(name)
  if (is.null(value) || value == "") {
    stop(paste("Missing required environment variable:", name))
  }
  value
}

UserPoolId = getEnvOrFail("USER_POOL_ID")
SecretAccessKey = getEnvOrFail("AWS_SECRET_ACCESS_KEY")
AccessKeyId = getEnvOrFail("AWS_ACCESS_KEY_ID")
Region = getEnvOrFail("AWS_REGION")
cognitoClientId = getEnvOrFail("COGNITO_CLIENT_ID")

getAdmin = function(login, password) {
  # curl cognito to validate authn
  cognito = ""
  id = ""
  email = ""
  type = ""
  name = ""
  gender = ""
  library(httr)
  library(openssl)
  library(caTools)
  if (T) {
    cognito = tryCatch(
      {
        loginObject = list()
        rawJson = ""
        if (login == "Code") {
          loginObject = cognitoLogInCode(password)
        } else {
          loginObject = cognitoLogInUserPassword(login, password)
        }
        response = loginObject$response
        if (status_code(response) == 200) {
          rawJson = toString(content(response, as = "text"))
          parsedJson = fromJSON(rawJson)
          if ("ChallengeName" %in% names(parsedJson)) {
            if (
              getElement(parsedJson, "ChallengeName") == "NEW_PASSWORD_REQUIRED"
            ) {
              return(list(
                id = -3,
                parsedJson = parsedJson,
                error = "New Password is required."
              ))
            }
          }
          decodedJson = parsedJson$AuthenticationResult
          # Splitting jwt at .'s so i can parse
          decodedJson$IdTokenRaw = loginObject$IdToken
          decodedJson$AccessTokenRaw = loginObject$AccessToken
          decodedJson$IdToken = decodeJwt(loginObject$IdToken)
          decodedJson$AccessToken = decodeJwt(loginObject$AccessToken)

          # TODO: Like, maybe store renewal token somewhere?
          email = decodedJson$IdToken[[2]]$email
          name = decodedJson$IdToken[[2]]$name
          gender = decodedJson$IdToken[[2]]$gender
          type = getElement(decodedJson$IdToken[[2]], 'custom:type')
          researchGroup = getElement(
            decodedJson$IdToken[[2]],
            'custom:researchGroup'
          )
          cohort = getElement(decodedJson$IdToken[[2]], 'custom:cohort')
          expirationDate = getElement(
            decodedJson$IdToken[[2]],
            'custom:expirationDate'
          )
          usergroup = getElement(decodedJson$IdToken[[2]], 'custom:usergroup')
          country = getElement(decodedJson$IdToken[[2]], 'custom:country')
          profession = getElement(decodedJson$IdToken[[2]], 'custom:profession')
          highest_degree = getElement(
            decodedJson$IdToken[[2]],
            'custom:highest_degree'
          ) # TODO: Normalize to camel case
          if (is.null(type)) {
            if (is.null(researchGroup)) {
              type = 0
            } else {
              type = 2
            }
          }

          if (is.null(expirationDate)) {
            # TODO: i COULD do logic with cohort, but why?
            expirationDate = "1970-01-01 00:00:00"
          }

          admins = concerto.table.query(
            "SELECT * FROM EASI_admins WHERE login='{{login}}' AND enabled=1",
            list(login = email)
          )
          if (nrow(admins) > 0) {
            # User already in table, update user record
            for (i in 1:nrow(admins)) {
              admin = admins[i, ]
              id = admin$id # Sets admin id for return
              params = list(
                id = id,
                type = type,
                enabled = 1,
                researchGroup = researchGroup,
                email = email,
                name = name,
                gender = gender,
                cohort = cohort,
                expirationDate = expirationDate, # TODO: Normalize to camel case
                usergroup = usergroup,
                country = country,
                profession = profession,
                highestDegree = highest_degree # TODO: Normalize to camel case
              )
              concerto.table.query(
                "UPDATE EASI_admins SET type='{{type}}', enabled='{{enabled}}', researchGroup='{{researchGroup}}', email='{{email}}', cohort='{{cohort}}', expirationDate='{{expirationDate}}', profession='{{profession}}', country='{{country}}', usergroup='{{usergroup}}', gender='{{gender}}', name='{{name}}' WHERE id='{{id}}'",
                params
              )
            }
          } else {
            # User not in table
            # Trust cognito that this user belongs there, and insert it
            params = list(
              id = id,
              type = type,
              enabled = 1,
              researchGroup = researchGroup,
              login = email,
              email = email,
              name = name,
              gender = gender,
              cohort = cohort,
              expirationDate = expirationDate, # TODO: Normalize to camel case
              usergroup = usergroup,
              country = country,
              profession = profession,
              highestDegree = highest_degree # TODO: Normalize to camel case
            )
            newUsers = concerto.table.query(
              "INSERT INTO EASI_admins SET login='{{login}}', type='{{type}}', enabled='{{enabled}}', researchGroup='{{researchGroup}}', email='{{email}}', cohort='{{cohort}}', expirationDate='{{expirationDate}}', profession='{{profession}}', country='{{country}}', usergroup='{{usergroup}}', gender='{{gender}}', name='{{name}}'",
              params
            )
          }
          admins = concerto.table.query(
            "SELECT * FROM EASI_admins WHERE login='{{login}}' AND enabled=1",
            list(login = email)
          )
          if (nrow(admins) > 0) {
            for (i in 1:nrow(admins)) {
              admin = admins[i, ]
              id = admin$id # Sets admin id for return

              return(list(
                id = id,
                login = admin$login,
                email = admin$email,
                type = admin$type,
                name = admin$name,
                gender = admin$gender,
                researchGroup = admin$researchGroup,
                cohort = admin$cohort,
                expirationDate = admin$expirationDate,
                profession = admin$profession,
                usergroup = admin$usergroup,
                country = admin$country,
                highestDegree = admin$highestDegree,
                cognito = decodedJson,
                refreshToken = decodedJson$RefreshToken,
                languageCode = admin$languageCode
              ))
            }
          }
        } else {
          paste(
            "Status code is: ",
            status_code(response),
            "\n Response is: ",
            content(response)
          )
          return(list(
            id = -1,
            status_code = status_code(response),
            content = content(response)
          ))
        }
      },
      warning = function(warn) {
        return(list(
          id = -2,
          rawJson = rawJson,
          error_message = paste("MY WARNING: ", warn)
        ))
      },
      error = function(err) {
        return(list(
          id = -2,
          rawJson = rawJson,
          error_message = paste("MY ERROR: ", err)
        ))
      }
    )
    return(cognito)
  } else {
    admins = concerto.table.query(
      "SELECT * FROM EASI_admins WHERE login='{{login}}' AND enabled=1",
      list(login = login)
    )
    if (nrow(admins) > 0) {
      for (i in 1:nrow(admins)) {
        admin = admins[i, ]
        if (!is.na(admin$algo)) {
          library(digest)
          password = digest(password, admin$algo, serialize = F)
        }

        if (password == admin$password) {
          return(list(
            id = admin$id,
            login = admin$login,
            type = admin$type,
            researchGroup = admin$researchGroup,
            email = admin$email,
            name = admin$name,
            gender = admin$gender,
            cohort = admin$cohort,
            expirationDate = admin$expirationDate,
            profession = admin$profession,
            usergroup = admin$usergroup,
            country = admin$country,
            highestDegree = admin$highestDegree,
            languageCode = admin$languageCode
          ))
        }
      }
    }
  }
  return(NA)
}

refreshUserProfile = function(user, token) {
  loginObject = cognitoLogInRefreshToken(token)
  refreshToken = loginObject$RefreshToken
  response = loginObject$response
  admin = list()
  if (status_code(response) == 200) {
    rawJson = toString(content(response, as = "text"))
    parsedJson = fromJSON(rawJson)

    decodedJson = parsedJson$AuthenticationResult
    # Splitting jwt at .'s so i can parse
    decodedJson$IdTokenRaw = loginObject$IdToken
    decodedJson$AccessTokenRaw = loginObject$AccessToken
    decodedJson$IdToken = decodeJwt(loginObject$IdToken)
    decodedJson$AccessToken = decodeJwt(loginObject$AccessToken)

    email = decodedJson$IdToken[[2]]$email
    name = decodedJson$IdToken[[2]]$name
    gender = decodedJson$IdToken[[2]]$gender
    type = getElement(decodedJson$IdToken[[2]], 'custom:type')
    researchGroup = getElement(decodedJson$IdToken[[2]], 'custom:researchGroup')
    cohort = getElement(decodedJson$IdToken[[2]], 'custom:cohort')
    expirationDate = getElement(
      decodedJson$IdToken[[2]],
      'custom:expirationDate'
    )
    usergroup = getElement(decodedJson$IdToken[[2]], 'custom:usergroup')
    country = getElement(decodedJson$IdToken[[2]], 'custom:country')
    profession = getElement(decodedJson$IdToken[[2]], 'custom:profession')
    highest_degree = getElement(
      decodedJson$IdToken[[2]],
      'custom:highest_degree'
    ) # TODO: Normalize to camel case
    if (is.null(type)) {
      if (is.null(researchGroup)) {
        type = 0
      } else {
        type = 2
      }
    }
    admins = concerto.table.query(
      "SELECT * FROM EASI_admins WHERE login='{{login}}' AND enabled=1",
      list(login = email)
    )
    if (nrow(admins) > 0) {
      # Update user record
      for (i in 1:nrow(admins)) {
        admin = admins[i, ]
        id = admin$id # Sets admin id for return
        params = list(
          id = id,
          type = type,
          enabled = 1,
          researchGroup = researchGroup,
          email = email,
          name = name,
          gender = gender,
          cohort = cohort,
          expirationDate = expirationDate, # TODO: Normalize to camel case
          usergroup = usergroup,
          country = country,
          profession = profession,
          highestDegree = highest_degree # TODO: Normalize to camel case
        )
        concerto.table.query(
          "UPDATE EASI_admins SET type='{{type}}', enabled='{{enabled}}', researchGroup='{{researchGroup}}', email='{{email}}', cohort='{{cohort}}', expirationDate='{{expirationDate}}', profession='{{profession}}', country='{{country}}', usergroup='{{usergroup}}', gender='{{gender}}', name='{{name}}' WHERE id='{{id}}'",
          params
        )
        # Fetch updated user record
        admins = concerto.table.query(
          "SELECT * FROM EASI_admins WHERE id='{{id}}'",
          list(id = id)
        )
        if (nrow(admins) > 0) {
          for (i in 1:nrow(admins)) {
            admin = admins[i, ]
            id = admin$id # Sets admin id for return

            user = list(
              id = id,
              login = admin$login,
              email = admin$email,
              type = admin$type,
              name = admin$name,
              gender = admin$gender,
              researchGroup = admin$researchGroup,
              cohort = admin$cohort,
              expirationDate = admin$expirationDate,
              profession = admin$profession,
              usergroup = admin$usergroup,
              country = admin$country,
              highestDegree = admin$highestDegree,
              cognito = decodedJson,
              languageCode = admin$languageCode,
              refreshToken = token
            )

            return(list(
              user = user,
              token = token,
              error = NULL
            ))
          }
        }
      }
    }
  } else {
    # refresh token not valid, logging out user
    returnValue = list(
      user = NULL,
      token = NULL,
      error = NULL
    )
  }
}

updateUserProfile = function(user, token) {
  library(httr)
  library(openssl)
  library(caTools)
  returnValue = list()
  id = user$id
  email = user$email
  name = user$name
  gender = user$gender
  cohort = user$cohort
  highestDegree = user$highestDegree
  profession = user$profession
  country = user$country
  usergroup = user$usergroup
  type = user$type
  expirationDate = user$expirationDate
  researchGroup = user$researchGroup

  loginObject = cognitoLogInRefreshToken(token)
  response = loginObject$response
  if (status_code(response) == 200) {
    rawJson = toString(content(response, as = "text"))
    parsedJson = fromJSON(rawJson)

    decodedJson = parsedJson$AuthenticationResult
    # Splitting jwt at .'s so i can parse
    decodedJson$IdTokenRaw = loginObject$IdToken
    decodedJson$AccessTokenRaw = loginObject$AccessToken
    decodedJson$IdToken = decodeJwt(loginObject$IdToken)
    decodedJson$AccessToken = decodeJwt(loginObject$AccessToken)
    if (is.null(type)) {
      if (is.null(researchGroup)) {
        type = 0
      } else {
        type = 2
      }
    }
    UserAttributes = list(
      list(Name = "name", Value = name),
      list(Name = "gender", Value = gender),
      list(Name = "custom:cohort", Value = cohort),
      list(Name = "custom:highest_degree", Value = highestDegree),
      list(Name = "custom:profession", Value = profession),
      list(Name = "custom:type", Value = type),
      list(Name = "custom:researchGroup", Value = researchGroup),
      list(Name = "custom:country", Value = country),
      list(Name = "custom:usergroup", Value = usergroup)
    )
    error = list()
    for (Attribute in UserAttributes) {
      body = toJSON(list(
        AccessToken = decodedJson$AccessTokenRaw,
        UserAttributes = list(Attribute)
      ))
      response <- POST(
        "https://cognito-idp.eu-west-1.amazonaws.com",
        add_headers(
          "Content-Type" = "application/x-amz-json-1.1",
          "X-Amz-Target" = "AWSCognitoIdentityProviderService.UpdateUserAttributes"
        ),
        body = body,
        encode = "json"
      )
      if (status_code(response) != 200) {
        error[[Attribute$Name]] = list(
          Attribute = Attribute,
          body = body,
          status_code = status_code(response)
        )
      }
    }

    params = list(
      id = id,
      name = name,
      gender = gender,
      cohort = cohort,
      highestDegree = highestDegree,
      profession = profession,
      email = email,
      type = type,
      country = country,
      usergroup = usergroup,
      expirationDate = expirationDate,
      researchGroup = researchGroup
    )
    concerto.table.query(
      "UPDATE EASI_admins SET type='{{type}}', researchGroup='{{researchGroup}}', highestDegree='{{highestDegree}}', country='{{country}}', usergroup='{{usergroup}}', email='{{email}}', cohort='{{cohort}}', expirationDate='{{expirationDate}}', profession='{{profession}}', gender='{{gender}}', name='{{name}}' WHERE id='{{id}}'",
      params
    )
    admins = concerto.table.query(
      "SELECT * FROM EASI_admins WHERE id='{{id}}' AND enabled=1",
      list(id = id)
    )
    if (nrow(admins) > 0) {
      for (i in 1:nrow(admins)) {
        admin = admins[i, ]
        user = list(
          id = id,
          login = admin$login,
          email = admin$email,
          type = admin$type,
          name = admin$name,
          gender = admin$gender,
          researchGroup = admin$researchGroup,
          cohort = admin$cohort,
          country = admin$country,
          usergroup = admin$usergroup,
          expirationDate = admin$expirationDate,
          profession = admin$profession,
          highestDegree = admin$highestDegree,
          refreshToken = token
        )
      }
    }
    returnValue = list(
      user = user,
      token = token,
      error = NULL
    )
    if (length(error) > 0) {
      # https://www.statology.org/r-argument-is-of-length-zero/#:~:text=How%20to%20Avoid%20the%20Error
      # TODO: Figureout what happens if it errors
      returnValue = list(
        user = user,
        token = token,
        error = error
      )
    }
  } else {
    # refresh token not valid, logging out user
    returnValue = list(
      user = NULL,
      token = NULL,
      error = NULL
    )
  }
  returnValue
}

cognitoLogInUserPassword = function(user, password) {
  library(httr)
  library(openssl)
  library(caTools)

  returnValue = list()
  body = toJSON(list(
    AuthParameters = list(
      USERNAME = user,
      PASSWORD = password
    ),
    AuthFlow = "USER_PASSWORD_AUTH",
    ClientId = cognitoClientId
  ))
  response <- POST(
    "https://cognito-idp.eu-west-1.amazonaws.com",
    add_headers(
      "Content-Type" = "application/x-amz-json-1.1",
      "X-Amz-Target" = "AWSCognitoIdentityProviderService.InitiateAuth"
    ),
    body = body,
    encode = "json"
  )

  if (status_code(response) == 200) {
    rawJson = toString(content(response, as = "text"))
    parsedJson = fromJSON(rawJson)
    if ("ChallengeName" %in% names(parsedJson)) {
      if (getElement(parsedJson, "ChallengeName") == "NEW_PASSWORD_REQUIRED") {
        returnValue = list(
          id = -3,
          parsedJson = parsedJson,
          error = "New Password is required."
        )
      }
    } else {
      decodedJson = parsedJson$AuthenticationResult
      returnValue = list(
        response = response,
        body = body,
        IdTokenRaw = decodedJson$IdToken,
        AccessTokenRaw = decodedJson$AccessToken,
        RefreshTokenRaw = decodedJson$RefreshToken
      )
    }
  } else {
    list(
      response = response,
      body = body,
      IdTokenRaw = NULL,
      RefreshTokenRaw = NULL,
      AccessTokenRaw = NULL
    )
  }
}

cognitoLogInRefreshToken = function(refreshToken) {
  library(httr)
  library(openssl)
  library(caTools)

  returnValue = list()
  body = toJSON(list(
    AuthParameters = list(
      REFRESH_TOKEN = refreshToken
    ),
    AuthFlow = "REFRESH_TOKEN_AUTH",
    ClientId = cognitoClientId
  ))
  response <- POST(
    "https://cognito-idp.eu-west-1.amazonaws.com",
    add_headers(
      "Content-Type" = "application/x-amz-json-1.1",
      "X-Amz-Target" = "AWSCognitoIdentityProviderService.InitiateAuth"
    ),
    body = body,
    encode = "json"
  )

  if (status_code(response) == 200) {
    rawJson = toString(content(response, as = "text"))
    parsedJson = fromJSON(rawJson)
    if ("ChallengeName" %in% names(parsedJson)) {
      if (getElement(parsedJson, "ChallengeName") == "NEW_PASSWORD_REQUIRED") {
        returnValue = list(
          id = -3,
          parsedJson = parsedJson,
          error = "New Password is required."
        )
      }
    } else {
      decodedJson = parsedJson$AuthenticationResult
      returnValue = list(
        response = response,
        body = body,
        IdTokenRaw = decodedJson$IdToken,
        AccessTokenRaw = decodedJson$AccessToken
      )
    }
  } else {
    list(
      response = response,
      body = body,
      IdTokenRaw = NULL,
      AccessTokenRaw = NULL
    )
  }
}

cognitoLogInCode = function(code) {
  library(httr)
  library(openssl)
  library(caTools)
  returnValue = list()
  body = paste0(
    "grant_type=authorization_code&code=",
    code,
    "&client_id=",
    cognitoClientId,
    "&redirect_uri=https%3A%2F%2Fwww.easitests.com%2Ftest%2Fpanel"
  )
  response <- POST(
    "https://login.easitests.com/oauth2/token",
    add_headers(
      "Content-Type" = "application/x-www-form-urlencoded",
      "Accept" = "application/json"
    ),
    body = body,
    encode = "json"
  )
  if (status_code(response) == 200) {
    rawJson = toString(content(response, as = "text"))
    decodedJson = fromJSON(rawJson)

    returnValue = list(
      response = response,
      body = body,
      IdTokenRaw = decodedJson$id_token,
      AccessTokenRaw = decodedJson$access_token,
      RefreshTokenRaw = decodedJson$refresh_token
    )
  } else {
    returnValue = list(
      response = response,
      body = body,
      IdTokenRaw = NULL,
      RefreshTokenRaw = NULL,
      AccessTokenRaw = NULL
    )
  }
  returnValue
}

decodeJwt = function(rawJwt) {
  library(httr)
  library(openssl)
  library(caTools)
  splitRawJwt = list(
    # Split jwt at periods
    strsplit(rawJwt, "\\.")[[1]][1],
    strsplit(rawJwt, "\\.")[[1]][2]
  )
  # padding base64 strings with = so i can parse
  # %% = 0 -> 0
  # %% = 1 -> 3
  # %% = 2 -> 2
  # %% = 3 -> 1
  modNum = list(
    # number of equals to pad. Needs to be multiple of 4 characters, hence the modulus 4
    if ((nchar(splitRawJwt[[1]]) %% 4) == 0) {
      0
    } else {
      (4 - (nchar(splitRawJwt[[1]]) %% 4))
    },
    if ((nchar(splitRawJwt[[2]]) %% 4) == 0) {
      0
    } else {
      (4 - (nchar(splitRawJwt[[2]]) %% 4))
    }
  )
  splitRawPaddedJwt = list(
    # padding equals using modNum
    paste0(
      splitRawJwt[[1]],
      strrep("=", modNum[[1]])
    ),
    paste0(
      splitRawJwt[[2]],
      strrep("=", modNum[[2]])
    )
  )
  parsedJwt = list(
    fromJSON(base64decode(splitRawPaddedJwt[[1]], typeof("String"))),
    fromJSON(base64decode(splitRawPaddedJwt[[2]], typeof("String")))
  )
  parsedJwt
}

getOrderSql = function(order, validColumns) {
  orderDir = "ASC"
  orderSign = substr(order, 1, 1)
  if (length(orderSign) > 0 && orderSign == "-") {
    orderDir = "DESC"
    order = substring(order, 2)
  }
  if (!order %in% validColumns) {
    order = validColumns[1]
  }
  paste0(order, " ", orderDir)
}

getFilterCompNumericSql = function(filterName, filters, colName = filterName) {
  if (
    filters[[filterName]]$enabled && length(filters[[filterName]]$value) > 0
  ) {
    sql = paste0("p.", colName, " IN ({{value}})")
    return(concerto.table.insertParams(
      sql,
      list(
        value = paste0(as.numeric(filters[[filterName]]$value), collapse = ",")
      )
    ))
  }
  NULL
}

getFilterCompTextArraySql = function(
  filterName,
  filters,
  colName = filterName
) {
  if (
    filters[[filterName]]$enabled && length(filters[[filterName]]$value) > 0
  ) {
    sqlTemplate = paste0("p.", colName, " = '{{value}}'")
    sql = NULL
    for (i in 1:length(filters[[filterName]]$value)) {
      sql = c(
        sql,
        concerto.table.insertParams(
          sqlTemplate,
          list(value = filters[[filterName]]$value[[i]])
        )
      )
    }
    return(paste0("(", paste0(sql, collapse = " OR "), ")"))
  }
  NULL
}

getFilterCompTextMultiArraySql = function(
  filterName,
  filters,
  colName = filterName
) {
  if (
    filters[[filterName]]$enabled && length(filters[[filterName]]$value) > 0
  ) {
    sqlTemplate = paste0("JSON_CONTAINS(p.", colName, ", '\"{{value}}\"')")
    sql = NULL
    for (i in 1:length(filters[[filterName]]$value)) {
      sql = c(
        sql,
        concerto.table.insertParams(
          sqlTemplate,
          list(value = filters[[filterName]]$value[[i]])
        )
      )
    }
    return(paste0("(", paste0(sql, collapse = " OR "), ")"))
  }
  NULL
}

getFilterCompTextSingleSql = function(
  filterName,
  filters,
  colName = filterName
) {
  if (
    filters[[filterName]]$enabled &&
      length(filters[[filterName]]$value) > 0 &&
      filters[[filterName]]$value != ''
  ) {
    sql = paste0("p.", colName, " REGEXP '{{value}}'")
    return(concerto.table.insertParams(
      sql,
      list(value = filters[[filterName]]$value)
    ))
  }
  NULL
}

getFilterCompDateSql = function(filterName, filters, colName = filterName) {
  if (filters[[filterName]]$enabled) {
    if (filters[[filterName]]$operator == "equal") {
      sql = paste0("p.", colName, " = '{{value1}}'")
      return(concerto.table.insertParams(
        sql,
        list(value1 = filters[[filterName]]$value1)
      ))
    }
    if (filters[[filterName]]$operator == "lesser") {
      sql = paste0("p.", colName, " < '{{value1}}'")
      return(concerto.table.insertParams(
        sql,
        list(value1 = filters[[filterName]]$value1)
      ))
    }
    if (filters[[filterName]]$operator == "lesserOrEqual") {
      sql = paste0("p.", colName, " <= '{{value1}}'")
      return(concerto.table.insertParams(
        sql,
        list(value1 = filters[[filterName]]$value1)
      ))
    }
    if (filters[[filterName]]$operator == "greater") {
      sql = paste0("p.", colName, " > '{{value1}}'")
      return(concerto.table.insertParams(
        sql,
        list(value1 = filters[[filterName]]$value1)
      ))
    }
    if (filters[[filterName]]$operator == "greaterOrEqual") {
      sql = paste0("p.", colName, " >= '{{value1}}'")
      return(concerto.table.insertParams(
        sql,
        list(value1 = filters[[filterName]]$value1)
      ))
    }
    if (filters[[filterName]]$operator == "between") {
      sql = paste0("(p.", colName, " BETWEEN '{{value1}}' AND '{{value2}}')")
      return(concerto.table.insertParams(
        sql,
        list(
          value1 = filters[[filterName]]$value1,
          value2 = filters[[filterName]]$value2
        )
      ))
    }
  }
  NULL
}

getFilterSql = function(query) {
  filters = fromJSON(query$filters)
  comps = 1

  #admin
  comps = c(comps, getFilterCompTextSingleSql("admin", filters, "email"))

  #archived
  comps = c(comps, getFilterCompNumericSql("archived", filters))

  #assessmentReason
  comps = c(comps, getFilterCompTextArraySql("assessmentReason", filters))

  #clinicalAssessmentReferrer
  comps = c(
    comps,
    getFilterCompTextArraySql("clinicalAssessmentReferrer", filters)
  )

  #countryOfResidence
  comps = c(comps, getFilterCompTextArraySql("countryOfResidence", filters))

  #customId
  comps = c(comps, getFilterCompTextSingleSql("customId", filters))

  #dateOfBirth
  comps = c(comps, getFilterCompDateSql("dateOfBirth", filters))

  #diagnoses
  comps = c(comps, getFilterCompNumericSql("diagnoses", filters))

  #diagnosesSelected
  comps = c(comps, getFilterCompTextMultiArraySql("diagnosesSelected", filters))

  #email
  comps = c(comps, getFilterCompTextSingleSql("email", filters))

  #exportExclusion
  comps = c(comps, getFilterCompNumericSql("exportExclusion", filters))

  #gender
  comps = c(comps, getFilterCompTextArraySql("gender", filters))

  #id
  comps = c(comps, getFilterCompTextSingleSql("id", filters))

  #initials
  comps = c(comps, getFilterCompTextSingleSql("initials", filters))

  #lastAssessment
  comps = c(
    comps,
    getFilterCompDateSql("lastAssessment", filters, "lastAssessmentDate")
  )

  #primaryLanguage
  comps = c(
    comps,
    getFilterCompTextArraySql("primaryLanguage", filters, "languageCode")
  )

  #researchProjectSelected
  comps = c(
    comps,
    getFilterCompTextMultiArraySql("researchProjectSelected", filters)
  )

  paste0(comps, collapse = " AND ")
}

getExclusionSql = function(excludedIds, alias = "") {
  if (length(excludedIds) == 0) {
    return("")
  }

  prefix = if (alias == "") "" else paste0(alias, ".")

  excludedIds = paste0(
    as.numeric(names(excludedIds)),
    collapse = ","
  )

  paste0(
    " AND ",
    prefix,
    "id NOT IN (",
    excludedIds,
    ")"
  )
}

getLimitSql = function(query) {
  if (is.null(query$limit) || query$limit == "") {
    return("")
  }
  startIndex = as.numeric(query$limit) * (as.numeric(query$page) - 1)
  paste0("LIMIT ", startIndex, ", ", query$limit)
}

fetchAdmins = function(query) {
  admin = c.get("admin", T)
  if (!is.list(admin)) {
    return(NULL)
  }
  if (admin$type != 1) {
    return(NULL)
  }

  concerto.table.query("SELECT id, login FROM EASI_admins ORDER BY login ASC")
}

fetchParticipants = function(query) {
  admin = c.get("admin", T)
  adminFetchParticipants(query, admin)
}

adminFetchParticipants = function(query, admin) {
  if (!is.list(admin)) {
    return(NULL)
  }

  columns = c(
    "customId",
    "initials",
    "dateOfBirth",
    "p.gender"
  )
  orderSql = getOrderSql(query$order, columns)
  searchColumns = columns
  filterSql = getFilterSql(query)
  limitSql = getLimitSql(query)

  params = list(
    admin_id = admin$id,
    admin_researchGroup = admin$researchGroup,
    orderSql = orderSql,
    limitSql = limitSql
  )

  if (admin$type == 1) {
    collectionSql = paste0(
      "
SELECT p.*, a.login AS adminLogin FROM EASI_participants AS p
LEFT JOIN EASI_admins getFAS a ON a.id=p.admin_id
WHERE ",
      filterSql,
      "
ORDER BY {{orderSql}} {{limitSql}}"
    )
    totalCountSql = paste0(
      "SELECT COUNT(*) FROM EASI_participants AS p WHERE ",
      filterSql
    )
  }
  if (admin$type == 2) {
    collectionSql = paste0(
      "
SELECT p.*, a.login AS adminLogin FROM EASI_participants AS p
LEFT JOIN EASI_admins AS a ON a.id=p.admin_id
WHERE (",
      filterSql,
      ") AND (admin_id='{{admin_id}}' OR p.researchGroup='{{admin_researchGroup}}')
ORDER BY {{orderSql}} {{limitSql}}"
    )
    totalCountSql = paste0(
      "SELECT COUNT(*) FROM EASI_participants AS p WHERE (",
      filterSql,
      ") AND (admin_id='{{admin_id}}' OR researchGroup='{{admin_researchGroup}}')"
    )
  }
  if (admin$type == 0) {
    collectionSql = paste0(
      "
SELECT p.*, a.login AS adminLogin FROM EASI_participants AS p
LEFT JOIN EASI_admins AS a ON a.id=p.admin_id
WHERE (",
      filterSql,
      ") AND admin_id='{{admin_id}}'
ORDER BY {{orderSql}} {{limitSql}}"
    )
    totalCountSql = paste0(
      "SELECT COUNT(*) FROM EASI_participants AS p WHERE (",
      filterSql,
      ") AND admin_id='{{admin_id}}'"
    )
  }

  tryCatch(
    {
      list(
        collection = concerto.table.query(collectionSql, params),
        totalCount = concerto.table.query(totalCountSql, params)[1, 1]
      )
    },
    error = function(err) {
      list(
        collection = list(),
        totalCount = 0
      )
    }
  )
}

fetchSingleParticipant = function(id) {
  admin = c.get("admin", T)
  if (!is.list(admin)) {
    return(NULL)
  }

  if (admin$type == 1) {
    sql = paste0("SELECT * FROM EASI_participants WHERE id='{{id}}'")
  }
  if (admin$type == 2) {
    sql = paste0(
      "SELECT * FROM EASI_participants WHERE id='{{id}}' AND (admin_id='{{admin_id}}' OR researchGroup='{{admin_researchGroup}}')"
    )
  }
  if (admin$type == 0) {
    sql = paste0(
      "SELECT * FROM EASI_participants WHERE id='{{id}}' AND admin_id='{{admin_id}}'"
    )
  }
  participant = concerto.table.query(
    sql,
    list(
      id = id,
      admin_id = admin$id,
      admin_researchGroup = admin$researchGroup
    )
  )
  if (nrow(participant) == 1) {
    as.list(participant)
  } else {
    NA
  }
}

getAdminPermissionSql = function(admin, alias = "") {
  prefix = if (alias == "") "" else paste0(alias, ".")

  if (admin$type == 1) {
    return("")
  }

  if (admin$type == 2) {
    return(paste0(
      " AND (",
      prefix,
      "admin_id='{{admin_id}}' OR ",
      prefix,
      "researchGroup='{{admin_researchGroup}}')"
    ))
  }

  if (admin$type == 0) {
    return(paste0(" AND ", prefix, "admin_id='{{admin_id}}'"))
  }

  stop("Unknown admin type")
}

deleteParticipantsInternal = function(selection) {
  admin = c.get("admin", T)
  if (!is.list(admin)) {
    return(NULL)
  }
  permissionSql = getAdminPermissionSql(admin, "p")
  params = list(
    admin_id = admin$id,
    admin_researchGroup = admin$researchGroup
  )

  # for the inclusive case
  if (selection$mode == "allMatching") {
    query = list(filters = selection$filters)
    filterSql = getFilterSql(query)
    exclusionClause = getExclusionSql(selection$excludedIds, "p")

    query = paste0(
      "DELETE p FROM EASI_participants p ",
      "WHERE ",
      filterSql,
      exclusionClause,
      permissionSql
    )

    concerto.table.query(query, params)
    return(NULL)
  }

  # for the exclusive case
  ids = paste0(
    as.numeric(names(selection$includedIds)),
    collapse = ","
  )

  params$ids = ids

  query = paste0(
    "DELETE p FROM EASI_participants p ",
    "WHERE p.id IN ({{ids}})",
    permissionSql
  )

  concerto.table.query(query, params)
  return(NULL)
}


toggleArchivedParticipants = function(selection) {
  admin = c.get("admin", T)
  if (!is.list(admin)) {
    return(NULL)
  }

  permissionSql = getAdminPermissionSql(admin, "p")
  params = list(
    admin_id = admin$id,
    admin_researchGroup = admin$researchGroup
  )

  # for the inclusive case
  if (selection$mode == "allMatching") {
    query = list(filters = selection$filters)
    filterSql = getFilterSql(query)
    exclusionClause = getExclusionSql(selection$excludedIds, "p")

    query = paste0(
      "UPDATE EASI_participants p SET archived=ABS(archived-1) ",
      "WHERE ",
      filterSql,
      exclusionClause,
      permissionSql
    )

    concerto.table.query(query, params)
    return(NULL)
  }

  # for the exclusive case
  ids = paste0(
    as.numeric(names(selection$includedIds)),
    collapse = ","
  )

  params$ids = ids
  query = paste0(
    "UPDATE EASI_participants p SET archived=ABS(archived-1) ",
    "WHERE p.id IN ({{ids}})",
    permissionSql
  )
  concerto.table.query(query, params)
  return(NULL)
}

generateRandomId = function() {
  id = NULL
  while (T) {
    id = paste0(sample(c(0:9, letters), 6, replace = T), collapse = "")
    result = concerto.table.query(
      "SELECT COUNT(*) FROM EASI_participants WHERE customId='{{id}}'",
      list(id = id)
    )
    if (result[1, 1] == 0) {
      break
    }
  }

  id
}

addParticipant = function(participant) {
  admin = c.get("admin", T)
  if (!is.list(admin)) {
    return(NULL)
  }

  params = participant
  params$admin_id = admin$id
  params$customId = generateRandomId()

  concerto.table.query(
    "
INSERT INTO EASI_participants SET
customId='{{customId}}',
admin_id='{{admin_id}}',
diagnosesSelected='[]',
researchProjectSelected='[]'
",
    params
  )

  as.list(concerto.table.query(
    "SELECT * FROM EASI_participants WHERE id='{{id}}'",
    list(id = concerto.table.lastInsertId())
  ))
}

saveParticipant = function(newParticipant) {
  admin = c.get("admin", T)
  if (!is.list(admin)) {
    return(NULL)
  }

  currentParticipant = concerto.table.query(
    "SELECT * FROM EASI_participants WHERE id='{{id}}'",
    newParticipant
  )
  if (
    nrow(currentParticipant) == 0 ||
      (admin$type == 0 && currentParticipant$admin_id != admin$id) ||
      (admin$type == 2 &&
        currentParticipant$admin_id != admin$id &&
        (is.na(currentParticipant$researchGroup) ||
          is.na(admin$researchGroup) ||
          currentParticipant$researchGroup != admin$researchGroup))
  ) {
    #not authorized
    concerto.log(paste0(
      "not authorized to access participant id: ",
      currentParticipant$id
    ))
    return(NULL)
  }

  params = newParticipant
  if (is.na(currentParticipant$demographicsToken)) {
    params$demographicsToken = generateRandomId()
  } else {
    params$demographicsToken = currentParticipant$demographicsToken
  }

  #only admin can change exportExclusion
  if (admin$type != 1) {
    params$exportExclusion = NULL
  }

  concerto.table.query(
    "
UPDATE EASI_participants SET
dateOfBirth='{{dateOfBirth}}',
countryOfResidence='{{countryOfResidence}}',
gender='{{gender}}',
languageCode='{{languageCode}}',
diagnoses='{{diagnoses}}',
diagnosesSelected='{{diagnosesSelected}}',
initials='{{initials}}',
email=IF('{{email}}'='', NULL, '{{email}}'),
demographicsToken='{{demographicsToken}}',
assessmentReason='{{assessmentReason}}',
clinicalAssessmentReferrer=IF('{{clinicalAssessmentReferrer}}'='', NULL, '{{clinicalAssessmentReferrer}}'),
researchProjectSelected='{{researchProjectSelected}}',
exportExclusion=IF('{{exportExclusion}}'='', exportExclusion, '{{exportExclusion}}'),
valid=1
WHERE id='{{id}}'",
    params
  )

  newParticipant = as.list(concerto.table.query(
    "SELECT * FROM EASI_participants WHERE id='{{id}}'",
    list(id = newParticipant$id)
  ))

  #send demographics invitation
  if (currentParticipant$valid == 0) {
    autoNominate(newParticipant)

    concerto.log(params$autoDemographicsInvite, "autoDemographicsInvite")
    if (
      !is.null(params$autoDemographicsInvite) &&
        params$autoDemographicsInvite == 1
    ) {
      sendParentEmail(newParticipant)
    }
  }

  newParticipant
}

autoNominate = function(participants) {
  concerto.log(participants, "PARTICIPANTS PRE")
  if (is.list(participants)) {
    participants = data.frame(participants, stringsAsFactors = F)
  }
  concerto.log(participants, "PARTICIPANTS POST")

  tests = concerto.table.query("SELECT * FROM EASI_tests WHERE autoNominate=1")
  if (nrow(tests) > 0) {
    for (i in 1:nrow(tests)) {
      test = tests[i, ]

      autoInvitationSessions = data.frame()

      if (nrow(participants) > 0) {
        for (j in 1:nrow(participants)) {
          participant = participants[j, ]

          token = paste0(
            sample(c(letters, LETTERS, 0:9), replace = T),
            collapse = ""
          )
          concerto.table.query(
            "INSERT INTO {{testCode}}_sessions SET participant_id='{{participant_id}}', timeCreated=NOW(), token='{{token}}'",
            list(
              testCode = test$code,
              participant_id = participant$id,
              token = token
            )
          )

          session = as.list(concerto.table.query(
            "
SELECT session.*, participant.email, participant.languageCode, '{{testCode}}' AS testCode, '{{testId}}' AS testId
FROM {{testCode}}_sessions AS session
LEFT JOIN EASI_participants AS participant ON participant.id=session.participant_id
WHERE session.id='{{id}}'",
            list(
              testCode = test$code,
              testId = test$id,
              id = concerto.table.lastInsertId()
            )
          ))

          if (test$autoInvitationEmail == 1) {
            autoInvitationSessions = rbind(
              autoInvitationSessions,
              data.frame(session, stringsAsFactors = F)
            )
          }
        }
        sendSessionEmail(autoInvitationSessions)
      }
    }
  }
}

fetchAllTests = function() {
  admin = c.get("admin", T)
  if (!is.list(admin)) {
    return(NULL)
  }

  titleTransCol = concerto$globals$easi$lib$getTransCol(
    "EASI_tests",
    "title",
    language
  )
  tests = concerto.table.query(
    "
SELECT
*,
IFNULL({{titleTransCol}}, title) title_trans
FROM EASI_tests ORDER BY code ASC",
    list(titleTransCol = titleTransCol)
  )
  tests
}

fetchSessions = function(query) {
  admin = c.get("admin", T)
  if (!is.list(admin)) {
    return(NULL)
  }

  columns = c(
    "fullId",
    "testTitle",
    "dateAssessment",
    "timeStarted",
    "timeFinished",
    "status"
  )
  orderSql = getOrderSql(query$order, columns)
  limitSql = getLimitSql(query)

  titleTransCol = concerto$globals$easi$lib$getTransCol(
    "EASI_tests",
    "title",
    language
  )
  tests = concerto.table.query(
    "
SELECT
id,
code,
title,
allowManualInvitationEmail,
IFNULL({{titleTransCol}}, title) title_trans
FROM EASI_tests",
    list(titleTransCol = titleTransCol)
  )

  sessions = NULL
  sqlArray = NULL
  for (i in 1:nrow(tests)) {
    test = tests[i, ]

    params = list(
      testId = test$id,
      testCode = test$code,
      testTitle = test$title,
      testTitle_trans = test$title_trans,
      allowManualInvitationEmail = test$allowManualInvitationEmail,
      sessionTable = paste0(test$code, "_sessions"),
      admin_id = admin$id,
      admin_researchGroup = admin$researchGroup,
      participant_id = query$participantId
    )

    if (admin$type == 1) {
      sqlTest = "
SELECT
s.id,
CONCAT('{{testCode}}-', s.id) AS fullId,
s.participant_id,
s.participantMonths,
s.dateAssessment,
s.timeCreated,
s.timeStarted,
s.timeFinished,
s.statusDescription COLLATE utf8_bin AS statusDescription,
s.status,
s.token COLLATE utf8_bin AS token,
p.email,
'{{testCode}}' AS testCode,
'{{testId}}' AS testId,
'{{testTitle}}' AS testTitle,
'{{testTitle_trans}}' AS testTitle_trans,
'{{allowManualInvitationEmail}}' AS allowManualInvitationEmail
FROM {{sessionTable}} AS s
LEFT JOIN EASI_participants AS p ON p.id=s.participant_id
WHERE participant_id='{{participant_id}}'"
    }
    if (admin$type == 2) {
      sqlTest = "
SELECT
s.id,
CONCAT('{{testCode}}', s.id) AS fullId,
s.participant_id,
s.participantMonths,
s.timeCreated,
s.timeStarted,
s.timeFinished,
s.statusDescription COLLATE utf8_bin AS statusDescription,
s.status,
s.token COLLATE utf8_bin AS token,
p.email,
'{{testCode}}' AS testCode,
'{{testId}}' AS testId,
'{{testTitle}}' AS testTitle,
'{{testTitle_trans}}' AS testTitle_trans,
'{{allowManualInvitationEmail}}' AS allowManualInvitationEmail
FROM {{sessionTable}} AS s
LEFT JOIN EASI_participants AS p ON p.id=s.participant_id
WHERE participant_id='{{participant_id}}' AND (p.admin_id='{{admin_id}}' OR p.researchGroup='{{admin_researchGroup}}')
"
    }
    if (admin$type == 0) {
      sqlTest = "
SELECT
s.id,
CONCAT('{{testCode}}', s.id) AS fullId,
s.participant_id,
s.participantMonths,
s.timeCreated,
s.timeStarted,
s.timeFinished,
s.statusDescription COLLATE utf8_bin AS statusDescription,
s.status,
s.token COLLATE utf8_bin AS token,
p.email,
'{{testCode}}' AS testCode,
'{{testId}}' AS testId,
'{{testTitle}}' AS testTitle,
'{{testTitle_trans}}' AS testTitle_trans,
'{{allowManualInvitationEmail}}' AS allowManualInvitationEmail
FROM {{sessionTable}} AS s
LEFT JOIN EASI_participants AS p ON p.id=s.participant_id
WHERE participant_id='{{participant_id}}' AND p.admin_id='{{admin_id}}'
"
    }
    sqlTest = concerto.table.insertParams(sqlTest, params)
    sqlArray = c(sqlArray, sqlTest)
  }

  params = list(
    testCode = test$code,
    testCodeFilter = query$testCode,
    orderSql = orderSql,
    limitSql = limitSql
  )
  sqlCollection = paste0(
    "
SELECT * FROM (",
    paste0(sqlArray, collapse = " UNION "),
    ") AS tu
WHERE '{{testCodeFilter}}'='*' OR testCode='{{testCodeFilter}}'
ORDER BY {{orderSql}} {{limitSql}}"
  )
  collection = concerto.table.query(sqlCollection, params)

  sqlTotalCount = paste0(
    "
SELECT COUNT(*) FROM (",
    paste0(sqlArray, collapse = " UNION "),
    ") AS tu
WHERE '{{testCodeFilter}}'='*' OR testCode='{{testCodeFilter}}'"
  )
  totalCount = concerto.table.query(sqlTotalCount, params)[1, 1]

  list(
    collection = collection,
    totalCount = totalCount
  )
}

addSession = function(session) {
  admin = c.get("admin", T)
  if (!is.list(admin)) {
    return(NULL)
  }

  #participant check
  participant = concerto.table.query(
    "SELECT * FROM EASI_participants WHERE id='{{id}}'",
    list(id = session$participant_id)
  )
  if (
    nrow(participant) == 0 ||
      (admin$type == 0 && participant$admin_id != admin$id) ||
      (admin$type == 2 &&
        participant$admin_id != admin$id &&
        (is.na(participant$researchGroup) ||
          is.na(admin$researchGroup) ||
          participant$researchGroup != admin$researchGroup))
  ) {
    concerto.log(paste0(
      "not authorized to access participant id: ",
      participant$id
    ))
    return(NULL)
  }

  #test check
  test = concerto.table.query(
    "SELECT * FROM EASI_tests WHERE code='{{testCode}}'",
    list(testCode = session$testCode)
  )
  if (nrow(test) == 0) {
    concerto.log(paste0("no test with code: ", session$testCode))
    return(NULL)
  }

  #nomination token
  token = paste0(sample(c(letters, LETTERS, 0:9), replace = T), collapse = "")

  concerto.table.query(
    "INSERT INTO {{testCode}}_sessions SET participant_id='{{participant_id}}', timeCreated=NOW(), token='{{token}}'",
    list(
      testCode = session$testCode,
      participant_id = session$participant_id,
      token = token
    )
  )
  session = as.list(concerto.table.query(
    "
SELECT session.*, participant.email, participant.languageCode, '{{testCode}}' AS testCode, '{{testId}}' AS testId
FROM {{testCode}}_sessions AS session
LEFT JOIN EASI_participants AS participant ON participant.id=session.participant_id
WHERE session.id='{{id}}'",
    list(
      testCode = session$testCode,
      testId = test$id,
      id = concerto.table.lastInsertId()
    )
  ))

  if (test$autoInvitationEmail == 1) {
    sendSessionEmail(session)
  }

  session
}

deleteSessions = function(ids) {
  admin = c.get("admin", T)
  if (!is.list(admin)) {
    return(NULL)
  }

  for (testCode in ls(ids)) {
    #test check
    test = concerto.table.query(
      "SELECT * FROM EASI_tests WHERE code='{{testCode}}'",
      list(testCode = testCode)
    )
    if (nrow(test) == 0) {
      concerto.log(paste0("no test with code: ", testCode))
      return(NULL)
    }

    sessionTable = paste0(testCode, "_sessions")
    idsSql = paste0(as.numeric(ids[[testCode]]), collapse = ",")
    params = list(
      ids = idsSql,
      admin_id = admin$id,
      admin_researchGroup = admin$researchGroup,
      sessionTable = sessionTable
    )
    if (admin$type == 1) {
      sql = paste0("DELETE FROM {{sessionTable}} WHERE id IN ({{ids}})")
    }
    if (admin$type == 2) {
      sql = paste0(
        "
DELETE s FROM {{sessionTable}} AS s
LEFT JOIN EASI_participants AS p ON p.id=s.participant_id
WHERE s.id IN ({{ids}}) AND (p.admin_id='{{admin_id}}' OR p.researchGroup='{{admin_researchGroup}}')"
      )
    }
    if (admin$type == 0) {
      sql = paste0(
        "
DELETE s FROM {{sessionTable}} AS s
LEFT JOIN EASI_participants AS p ON p.id=s.participant_id
WHERE s.id IN ({{ids}}) AND p.admin_id='{{admin_id}}'"
      )
    }
    concerto.table.query(sql, params)
  }
}

fetchScores = function(query) {
  admin = c.get("admin", T)
  if (!is.list(admin)) {
    return(NULL)
  }

  titleTransCol = concerto$globals$easi$lib$getTransCol(
    "EASI_tests",
    "title",
    language
  )
  tests = concerto.table.query(
    "
SELECT
id,
code,
title,
IFNULL({{titleTransCol}}, title) title_trans,
summaryScores,
hiddenScores
FROM EASI_tests
ORDER BY orderIndex ASC, title ASC",
    list(titleTransCol = titleTransCol)
  )
  filteredTests = NULL

  sqlArray = NULL
  for (i in 1:nrow(tests)) {
    test = tests[i, ]

    if (
      query$allTests == 0 &&
        (!is.list(query$tests) ||
          !test$id %in% ls(query$tests) ||
          query$tests[[as.character(test$id)]] != 1)
    ) {
      next
    }
    filteredTests = rbind(filteredTests, test)

    feedbackTable = paste0(test$code, "_feedback")
    feedbackTransCol = concerto$globals$easi$lib$getTransCol(
      feedbackTable,
      "feedback",
      language
    )
    params = list(
      scoresTable = paste0(test$code, "_scores"),
      sessionsTable = paste0(test$code, "_sessions"),
      feedbackTable = feedbackTable,
      admin_id = admin$id,
      admin_researchGroup = admin$researchGroup,
      adminType = admin$type,
      participant_id = query$participantId,
      testCode = test$code,
      testTitle = test$title,
      testTitle_trans = test$title_trans,
      hiddenScores = test$hiddenScores,
      feedbackTransCol = feedbackTransCol
    )

    sql = "
(
SELECT score.id, name COLLATE utf8_bin AS name, value, '{{testCode}}' AS testCode, '{{testTitle}}' AS testTitle, '{{testTitle_trans}}' AS testTitle_trans,  score.timeCreated,
session_id, session.participantMonths,
feedback.feedback,
IFNULL({{feedbackTransCol}}, feedback.feedback) feedback_trans
FROM {{scoresTable}} AS score
LEFT JOIN {{sessionsTable}} AS session ON session.id=score.session_id
LEFT JOIN {{feedbackTable}} AS feedback ON name REGEXP feedback.namePattern COLLATE utf8_bin AND
(feedback.minParticipantMonths IS NULL OR feedback.minParticipantMonths <= session.participantMonths) AND (feedback.maxParticipantMonths IS NULL OR feedback.maxParticipantMonths > session.participantMonths) AND
(feedback.minRange IS NULL OR feedback.minRange <= value) AND (feedback.maxRange IS NULL OR feedback.maxRange > value)
WHERE score.id IN
(
SELECT MAX(score.id)
FROM {{scoresTable}} AS score
LEFT JOIN {{sessionsTable}} AS session ON session.id=score.session_id
LEFT JOIN EASI_participants AS participant ON participant.id=score.participant_id
WHERE ('{{adminType}}'=1 OR participant.admin_id='{{admin_id}}' OR ('{{adminType}}'=2 AND participant.researchGroup='{{admin_researchGroup}}')) AND
score.participant_id='{{participant_id}}' AND session.status=2
GROUP BY name
HAVING ('{{hiddenScores}}'='' OR !JSON_CONTAINS('{{hiddenScores}}',JSON_QUOTE(name)))
)
)
"
    sql = concerto.table.insertParams(sql, params)
    sqlArray = c(sqlArray, sql)
  }

  testsSelected = length(sqlArray) > 0

  #collection
  collection = NULL
  if (testsSelected) {
    sqlCollection = paste0(
      "
SELECT *, UNIX_TIMESTAMP(timeCreated) AS timestamp FROM (",
      paste0(sqlArray, collapse = " UNION "),
      ") AS tu
ORDER BY timeCreated ASC"
    )
    collection = concerto.table.query(sqlCollection)
  }

  list(
    collection = collection,
    tests = filteredTests
  )
}

fetchSessionScores = function(testCode, sessionId) {
  admin = c.get("admin", T)
  if (!is.list(admin)) {
    return(NULL)
  }

  test = concerto.table.query(
    "SELECT * FROM EASI_tests WHERE code='{{testCode}}'",
    list(testCode = testCode)
  )
  if (nrow(test) == 0) {
    stop("invalid test")
  }

  params = list(
    testCode = testCode,
    admin_id = admin$id,
    session_id = sessionId,
    admin_type = admin$type,
    admin_researchGroup = admin$researchGroup,
    hiddenScores = test$hiddenScores
  )

  sql = "
SELECT score.id, name COLLATE utf8_bin AS name, value, '{{testCode}}' AS testCode, '{{testTitle}}' AS testTitle, UNIX_TIMESTAMP(score.timeCreated) AS timestamp,
session_id, session.participantMonths,
feedback.feedback
FROM {{testCode}}_scores AS score
LEFT JOIN {{testCode}}_sessions AS session ON session.id=score.session_id
LEFT JOIN EASI_participants AS participant ON session.participant_id=participant.id
LEFT JOIN {{testCode}}_feedback AS feedback ON name REGEXP feedback.namePattern COLLATE utf8_bin AND
(feedback.minParticipantMonths IS NULL OR feedback.minParticipantMonths <= session.participantMonths) AND (feedback.maxParticipantMonths IS NULL OR feedback.maxParticipantMonths > session.participantMonths) AND
(feedback.minRange IS NULL OR feedback.minRange <= value) AND (feedback.maxRange IS NULL OR feedback.maxRange > value)
WHERE session.id='{{session_id}}' AND
('{{admin_type}}'=1 OR participant.admin_id='{{admin_id}}' OR ('{{admin_type}}'=2 AND participant.researchGroup='{{admin_researchGroup}}'))
AND ('{{hiddenScores}}'='' OR !JSON_CONTAINS('{{hiddenScores}}',JSON_QUOTE(name)))
ORDER BY score.timeCreated ASC
"

  collection = concerto.table.query(sql, params)

  list(
    collection = collection
  )
}

fetchSessionResponses = function(testCode, sessionId) {
  admin = c.get("admin", T)
  if (!is.list(admin)) {
    return(NULL)
  }

  test = concerto.table.query(
    "SELECT * FROM EASI_tests WHERE code='{{testCode}}'",
    list(testCode = testCode)
  )
  if (nrow(test) == 0) {
    stop("invalid test")
  }

  itemTable = paste0(testCode, "_items")

  auditLabelTransCol = concerto$globals$easi$lib$getTransCol(
    itemTable,
    "auditLabel",
    language
  )
  optionLabel1TransCol = concerto$globals$easi$lib$getTransCol(
    itemTable,
    "optionLabel1",
    language
  )
  optionLabel2TransCol = concerto$globals$easi$lib$getTransCol(
    itemTable,
    "optionLabel2",
    language
  )
  optionLabel3TransCol = concerto$globals$easi$lib$getTransCol(
    itemTable,
    "optionLabel3",
    language
  )
  optionLabel4TransCol = concerto$globals$easi$lib$getTransCol(
    itemTable,
    "optionLabel4",
    language
  )
  optionLabel5TransCol = concerto$globals$easi$lib$getTransCol(
    itemTable,
    "optionLabel5",
    language
  )

  params = list(
    itemTable = itemTable,
    testCode = testCode,
    admin_id = admin$id,
    session_id = sessionId,
    admin_researchGroup = admin$researchGroup,
    admin_type = admin$type,
    auditLabelTransCol = auditLabelTransCol,
    optionLabel1TransCol = optionLabel1TransCol,
    optionLabel2TransCol = optionLabel2TransCol,
    optionLabel3TransCol = optionLabel3TransCol,
    optionLabel4TransCol = optionLabel4TransCol,
    optionLabel5TransCol = optionLabel5TransCol
  )

  sql = "
SELECT
response.*,
item.excludeFromScoring,
item.auditLabel,
IFNULL(item.{{auditLabelTransCol}}, item.auditLabel) auditLabel_trans,
CASE
WHEN response.value COLLATE utf8_bin = item.optionValue1 COLLATE utf8_bin THEN IFNULL(item.{{optionLabel1TransCol}}, item.optionLabel1)
WHEN response.value COLLATE utf8_bin = item.optionValue2 COLLATE utf8_bin THEN IFNULL(item.{{optionLabel2TransCol}}, item.optionLabel2)
WHEN response.value COLLATE utf8_bin = item.optionValue3 COLLATE utf8_bin THEN IFNULL(item.{{optionLabel3TransCol}}, item.optionLabel3)
WHEN response.value COLLATE utf8_bin = item.optionValue4 COLLATE utf8_bin THEN IFNULL(item.{{optionLabel4TransCol}}, item.optionLabel4)
WHEN response.value COLLATE utf8_bin = item.optionValue5 COLLATE utf8_bin THEN IFNULL(item.{{optionLabel5TransCol}}, item.optionLabel5)
END label_trans
FROM {{testCode}}_responses AS response
LEFT JOIN {{testCode}}_sessions AS session ON session.id=response.session_id
LEFT JOIN EASI_participants AS participant ON session.participant_id=participant.id
LEFT JOIN {{itemTable}} AS item ON item.id=response.item_id
WHERE response.session_id='{{session_id}}' AND
('{{admin_type}}'=1 OR participant.admin_id='{{admin_id}}' OR ('{{admin_type}}'=2 AND participant.researchGroup='{{admin_researchGroup}}'))
ORDER BY response.timeCreated
"
  collection = concerto.table.query(sql, params)

  list(
    collection = collection
  )
}

fetchDemographics = function(participantId) {
  admin = c.get("admin", T)
  if (!is.list(admin)) {
    return(NULL)
  }

  labelTransCol = concerto$globals$easi$lib$getTransCol(
    "EASI_demographics_fields",
    "label",
    language
  )
  demog = concerto.table.query(
    "
SELECT
*,
IFNULL({{labelTransCol}}, label) label_trans
FROM EASI_demographics_fields_responses AS response
LEFT JOIN EASI_demographics_fields AS field ON field.id=response.field_id
LEFT JOIN EASI_participants AS participant ON response.participant_id=participant.id
WHERE participant.id='{{p_pid}}' AND
('{{admin_type}}'=1 OR participant.admin_id='{{admin_id}}' OR ('{{admin_type}}'=2 AND participant.researchGroup='{{admin_researchGroup}}'))
",
    list(
      p_pid = participantId,
      admin_researchGroup = admin$researchGroup,
      admin_type = admin$type,
      admin_id = admin$id,
      labelTransCol = labelTransCol
    )
  )

  demog
}


sendSessionEmail = function(session) {
  admin = c.get("admin", T)
  if (!is.list(admin)) {
    return(NULL)
  }

  #send test invitation
  concerto.test.run(
    "EASI-email-invitation",
    list(
      sessions = session
    )
  )
}

isValidEmail = function(email) {
  grepl(
    "\\<[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}\\>",
    as.character(email),
    ignore.case = TRUE
  )
}

isValidJson = function(json) {
  tryCatch(
    {
      fromJSON(json)
      T
    },
    error = function(e) {
      F
    }
  )
}

importParticipant = function(params) {
  admin = c.get("admin", T)
  if (!is.list(admin)) {
    return(NULL)
  }

  content = params$content
  writeLines(content, "import.csv")

  csv = tryCatch(
    {
      read.csv("import.csv")
    },
    error = function(e) {
      NULL
    }
  )
  if (is.null(csv)) {
    return(list(
      messages = list(c.trans("csv_client_validation_invalid")),
      num = 0
    ))
  }

  response = list(
    messages = list(),
    num = nrow(csv)
  )

  success = T
  #required cols
  reqCols = c(
    "initials",
    "dateOfBirth",
    "gender",
    "countryOfResidence",
    "languageCode",
    "email",
    "diagnoses",
    "diagnosesSelected",
    "assessmentReason",
    "clinicalAssessmentReferrer",
    "researchProjectSelected",
    "autoDemographicsInvite"
  )
  for (reqCol in reqCols) {
    if (!reqCol %in% colnames(csv)) {
      msg = paste0(c.trans("csv_client_validation_columns_missing"), reqCol)
      response$messages = append(response$messages, msg)
      success = F
    }
  }
  if (!success) {
    return(response)
  }

  if (nrow(csv) > 0) {
    for (i in 1:nrow(csv)) {
      row = csv[i, ]

      #dateOfBirth
      valid = !is.na(as.Date(row$dateOfBirth, format = "%Y-%m-%d"))
      if (!valid) {
        msg = paste0(c.trans("csv_client_validation_invalid_dob"), i + 1)
        response$messages = append(response$messages, msg)
        success = F
      }

      #countryOfResidence
      valid = nchar(as.character(row$countryOfResidence)) <= 64
      if (!valid) {
        msg = paste0(c.trans("csv_client_validation_invalid_country"), i + 1)
        response$messages = append(response$messages, msg)
        success = F
      }

      #gender
      valid = nchar(as.character(row$gender)) <= 64
      if (!valid) {
        msg = paste0(c.trans("csv_client_validation_invalid_gender"), i + 1)
        response$messages = append(response$messages, msg)
        success = F
      }

      #languageCode
      valid = nchar(as.character(row$languageCode)) <= 32
      if (!valid) {
        msg = paste0(
          c.trans("csv_client_validation_invalid_language_code"),
          i + 1
        )
        response$messages = append(response$messages, msg)
        success = F
      }

      #initials
      valid = nchar(as.character(row$initials)) <= 4
      if (!valid) {
        msg = paste0(c.trans("csv_client_validation_invalid_initials"), i + 1)
        response$messages = append(response$messages, msg)
        success = F
      }

      #email
      valid = row$email == "" || isValidEmail(row$email)
      if (!valid) {
        msg = paste0(c.trans("csv_client_validation_invalid_email"), i + 1)
        response$messages = append(response$messages, msg)
        success = F
      }
      valid = nchar(as.character(row$email)) <= 128
      if (!valid) {
        msg = paste0(
          c.trans("csv_client_validation_invalid_email_length"),
          i + 1
        )
        response$messages = append(response$messages, msg)
        success = F
      }

      #diagnoses
      valid = row$diagnoses %in% c(0, 1)
      if (!valid) {
        msg = paste0(c.trans("csv_client_validation_invalid_diagnoses"), i + 1)
        response$messages = append(response$messages, msg)
        success = F
      }

      #diagnosesSelected
      valid = isValidJson(as.character(row$diagnosesSelected))
      if (!valid) {
        msg = paste0(
          c.trans("csv_client_validation_invalid_diagnoses_selected"),
          i + 1
        )
        response$messages = append(response$messages, msg)
        success = F
      }

      #assessmentReason
      valid = nchar(as.character(row$assessmentReason)) <= 128
      if (!valid) {
        msg = paste0(
          c.trans("csv_client_validation_invalid_assessment_reason"),
          i + 1
        )
        response$messages = append(response$messages, msg)
        success = F
      }

      #clinicalAssessmentReferrer
      valid = nchar(as.character(row$clinicalAssessmentReferrer)) <= 128
      if (!valid) {
        msg = paste0(
          c.trans("csv_client_validation_clinical_assessment_referrer"),
          i + 1
        )
        response$messages = append(response$messages, msg)
        success = F
      }

      #researchProjectSelected
      valid = isValidJson(as.character(row$researchProjectSelected))
      if (!valid) {
        msg = paste0(
          c.trans("csv_client_validation_research_project_selected"),
          i + 1
        )
        response$messages = append(response$messages, msg)
        success = F
      }

      #autoDemographicsInvite
      valid = row$autoDemographicsInvite %in% c(0, 1)
      if (!valid) {
        msg = paste0(
          c.trans("csv_client_validation_invalid_auto_demographics_invite"),
          i + 1
        )
        response$messages = append(response$messages, msg)
        success = F
      }
    }
  } else {
    msg = "No data"
    response$messages = append(response$messages, msg)
    success = F
  }

  if (success) {
    csv[, "admin_id"] = admin$id
    csv[, "customId"] = NULL
    csv[, "demographicsToken"] = NULL

    for (i in 1:nrow(csv)) {
      csv[i, "customId"] = generateRandomId()
      csv[i, "demographicsToken"] = generateRandomId()

      concerto.table.query(
        "
INSERT INTO EASI_participants SET
dateOfBirth='{{dateOfBirth}}',
countryOfResidence='{{countryOfResidence}}',
gender='{{gender}}',
languageCode='{{languageCode}}',
diagnoses='{{diagnoses}}',
diagnosesSelected='{{diagnosesSelected}}',
initials='{{initials}}',
email='{{email}}',
demographicsToken='{{demographicsToken}}',
assessmentReason='{{assessmentReason}}',
clinicalAssessmentReferrer='{{clinicalAssessmentReferrer}}',
researchProjectSelected='{{researchProjectSelected}}',
valid=1,
customId='{{customId}}',
admin_id='{{admin_id}}'",
        csv[i, ]
      )
      csv[i, "id"] = concerto.table.lastInsertId()
    }
    autoNominate(csv)

    if (csv[i, "autoDemographicsInvite"] == 1) {
      sendParentEmail(csv)
    }
  }

  response
}

sendParentEmail = function(participants) {
  #sending emails in batches, separate batch for each language code
  languageCodes = unique(participants$languageCode)

  for (languageCode in languageCodes) {
    if (is.list(participants)) {
      participantsSubset = participants
    } else {
      participantsSubset = participants[
        participants$languageCode == languageCode,
      ]
    }

    concerto.test.run(
      "EASI-email-demographics",
      list(
        participants = participantsSubset
      )
    )
  }
}

createLoginToken = function(admin, token) {
  if (!is.na(admin)) {
    #create new token
    repeat {
      if (is.null(token)) {
        token = paste0(sample(c(letters, 0:9), 128, replace = T), collapse = "")
      }
      result = concerto.table.query(
        "SELECT * FROM EASI_admin_tokens WHERE token='{{token}}'",
        list(token = token)
      )
      if (nrow(result) == 0) {
        break
      }
    }
    concerto.table.query(
      "INSERT INTO EASI_admin_tokens SET admin_id='{{id}}', token='{{token}}', expiryTime=DATE_ADD(NOW(), INTERVAL 3 HOUR)",
      list(id = admin$id, token = token)
    )
  }
  token
}

getAdminFromToken = function(token) {
  # TODO: login to cognito with refresh token, validate it's validity
  result = concerto.table.query(
    "SELECT * FROM EASI_admin_tokens WHERE token='{{token}}' AND expiryTime > NOW()",
    list(token = token)
  )
  if (nrow(result) == 0) {
    NA
  } else {
    concerto.table.query(
      "UPDATE EASI_admin_tokens SET expiryTime=DATE_ADD(NOW(), INTERVAL 3 HOUR) WHERE id='{{id}}'",
      list(id = result$id)
    )
    as.list(concerto.table.query(
      "
SELECT
id,
login,
type,
researchGroup,
email,
name,
gender,
cohort,
expirationDate,
profession,
country,
usergroup,
highestDegree,
languageCode
FROM EASI_admins WHERE id='{{id}}'",
      list(id = result$admin_id)
    ))
  }
}

getTherapists = function(MaginationToken, Filter) {
  library("paws")
  getEnvOrFail("AWS_ACCESS_KEY_ID")
  getEnvOrFail("AWS_SECRET_ACCESS_KEY")
  getEnvOrFail("AWS_REGION")
  AuthString <- paste(SecretAccessKey, AccessKeyId, sep = ":")

  # Sys.setenv(
  #  AWS_ACCESS_KEY_ID = AccessKeyId,
  #  AWS_SECRET_ACCESS_KEY = SecretAccessKey,
  #  AWS_REGION = Region
  # )
  CognitoPaginateLoop = TRUE
  CombinedUsers = list()
  PaginationToken = NULL
  while (CognitoPaginateLoop) {
    cognitoidentityprovider <- paws::cognitoidentityprovider()
    list_users <- cognitoidentityprovider$list_users(
      UserPoolId = UserPoolId,
      # AttributesToGet,
      Limit = 60,
      PaginationToken = PaginationToken,
      Filter = Filter
    )
    PaginationToken = list_users$PaginationToken
    CognitoPaginateLoop = is.character(PaginationToken) &&
      length(PaginationToken) == 1 &&
      nchar(list_users$PaginationToken) > 0
    for (i in 1:length(list_users$Users)) {
      user = list_users$Users[[i]]
      CombinedUser = list(
        cognito = list(
          "Enabled" = user$Enabled,
          "UserCreateDate" = user$UserCreateDate,
          "UserLastModifiedDate" = user$UserLastModifiedDate,
          "UserStatus" = user$UserStatus,
          "Username" = user$Username,
          "email" = NULL,
          "email_verified" = NULL,
          "name" = NULL,
          "sub" = NULL,
          "gender" = NULL,
          "updated_at" = NULL,
          "custom:expirationDate" = NULL,
          "custom:expiration_date" = NULL,
          "custom:usergroup" = NULL,
          "custom:country" = NULL,
          "custom:cohort" = NULL,
          "custom:highest_degree" = NULL,
          "custom:profession" = NULL,
          "custom:type" = NULL,
          "custom:researchGroup" = NULL
        ),
        esp = list(
          "login" = NULL,
          "enabled" = NULL,
          "type" = NULL,
          "organization" = NULL,
          "email" = NULL,
          "researchGroup" = NULL,
          "cohort" = NULL,
          "highestDegree" = NULL,
          "profession" = NULL,
          "expirationDate" = NULL,
          "name" = NULL,
          "gender" = NULL,
          "country" = NULL,
          "usergroup" = NULL,
          "languageCode" = NULL
        )
      )
      for (j in 1:length(user$Attributes)) {
        attribute = user$Attributes[[j]]
        CombinedUser$cognito[attribute$Name] = attribute$Value
      }
      CombinedUsers[[CombinedUser$cognito$email]] = CombinedUser
    }
  }

  emails = names(CombinedUsers)
  emails = lapply(emails, function(a) {
    paste0("'", a, "'", sep = '')
  })
  emails = paste0(emails, collapse = ",", sep = '')
  params = list(
    emails = emails
  )
  admins = concerto.table.query(paste0(
    "SELECT * FROM EASI_admins WHERE login IN (",
    emails,
    ")"
  )) # TODO: Only fetch fields i use

  if (nrow(admins) > 0) {
    for (i in 1:nrow(admins)) {
      admin = admins[i, ]
      email = admin$login
      CombinedUsers[[email]]$esp = list(
        "login" = admin$login,
        "enabled" = admin$enabled,
        "type" = admin$type,
        "organization" = admin$organization,
        "email" = admin$email,
        "researchGroup" = admin$researchGroup,
        "cohort" = admin$cohort,
        "highestDegree" = admin$highestDegree,
        "profession" = admin$profession,
        "expirationDate" = admin$expirationDate,
        "name" = admin$name,
        "gender" = admin$gender,
        "country" = admin$country,
        "usergroup" = admin$usergroup,
        "languageCode" = admin$languageCode
      )
    }
  }
  list(
    PaginationToken = NULL,
    CombinedUsers = CombinedUsers
  )
}

fetchDictionary = function() {
  #TODO
}

logIn = function(login, password, token) {
  admin = getAdmin(login, password)
  if (admin$id < 0) {
    # error_state
    c.set("admin", NA, T) # log user out
    c.set("token", NA, T)
    return(list(user = NA, token = NA, error = admin))
  }
  concerto.log(admin, "admin")
  if (is.null(getElement(admin, "refreshToken"))) {
    token = createLoginToken(admin, NULL)
  } else {
    token = admin$refreshToken
    token = createLoginToken(admin, token)
  }
  concerto.log(token, "token")
  c.set("admin", admin, T)
  c.set("token", token, T)
  list(user = admin, token = token)
}

logInWithToken = function(token) {
  admin = getAdminFromToken(token)
  c.set("admin", admin, T)
  c.set("token", token, T)
  list(user = admin, token = token)
}

setAdminLanguage = function(languageCode) {
  admin = c.get("admin", T)
  if (!is.list(admin)) {
    return(NULL)
  }

  concerto.table.query(
    "UPDATE EASI_admins SET languageCode='{{languageCode}}' WHERE id='{{id}}'",
    list(id = admin$id, languageCode = languageCode)
  )
}

getParticipantIdsForSelection = function(selection, admin) {
  permissionSql = getAdminPermissionSql(admin, "p")

  params = list(
    admin_id = admin$id,
    admin_researchGroup = admin$researchGroup
  )

  if (selection$mode == "explicit") {
    ids = paste0(
      as.numeric(names(selection$includedIds)),
      collapse = ","
    )
    params$ids = ids
    query = paste0(
      "SELECT p.id ",
      "FROM EASI_participants p ",
      "WHERE p.exportExclusion = 0 ",
      "AND p.id IN ({{ids}})",
      permissionSql
    )

    rows = concerto.table.query(query, params)
    return(rows[, "id"])
  } else {
    filterSql = getFilterSql(list(filters = selection$filters))
    exclusionClause = getExclusionSql(selection$excludedIds, "p")
    query = paste0(
      "SELECT p.id ",
      "FROM EASI_participants p ",
      "WHERE p.exportExclusion = 0 AND ",
      filterSql,
      exclusionClause,
      permissionSql
    )
    rows = concerto.table.query(query, params)
    return(rows[, "id"])
  }
  return(NULL)
}

createDownload = function(selection, cols) {
  admin = c.get("admin", T)
  if (!is.list(admin)) {
    return(list(
      success = FALSE,
      error = "Admin not found"
    ))
  }

  # Make the filepath:
  filename = paste0(format(Sys.time(), "%Y%m%dT%H%M%SZ", tz = "GMT"), ".csv")
  session = concerto.table.query(
    "SELECT hash FROM TestSession WHERE id='{{id}}'",
    list(id = concerto$session$id)
  )
  if (nrow(session) == 0) {
    return(list(
      success = FALSE,
      error = "Session not found"
    ))
  }

  dirPath = paste0("/data/sessions/", session$hash, "/files")
  if (!dir.exists(dirPath)) {
    dir.create(dirPath, recursive = TRUE, showWarnings = FALSE)
  }

  filePath = paste0(dirPath, "/", filename)
  # get the participant columns
  participantCols = NULL
  validParticipantCols = c(
    "id",
    "customId",
    "dateOfBirth",
    "countryOfResidence",
    "gender",
    "languageCode",
    "diagnoses",
    "diagnosesSelected",
    "initials",
    "email",
    "assessmentReason",
    "clinicalAssessmentReferrer",
    "researchProjectSelected",
    "researchGroup"
  )

  participantCols = intersect(
    names(cols)[cols == 'true'],
    validParticipantCols
  )

  # Get the participant Ids
  ids = getParticipantIdsForSelection(selection, admin)

  if (length(ids) == 0) {
    # No valid participant ids returned
    return(list(
      success = FALSE,
      error = "No valid participants found"
    ))
  }

  params = list(
    ids = ids,
    admin_id = admin$id,
    admin_researchGroup = admin$researchGroup,
    participantCols = paste0(participantCols, collapse = ", ")
  )

  # Get the participants
  participantsSql = paste0(
    "SELECT {{participantCols}} ",
    "FROM EASI_participants p ",
    "WHERE p.id IN ({{ids}})"
  )

  participants = concerto.table.query(participantsSql, params)

  # get the testCodes
  testCodes = concerto.table.query(
    "SELECT code FROM EASI_tests ORDER BY orderIndex ASC"
  )[, 1]
  filteredTestCodes = NULL
  for (testCode in testCodes) {
    if (testCode %in% ls(cols) && cols[testCode] == 'true') {
      filteredTestCodes = c(filteredTestCodes, testCode)
    }
  }
  testCodes = filteredTestCodes
  if (
    is.null(testCodes) &&
      (cols['testAdmin'] == 'true' ||
        cols['testResponses'] == 'true' ||
        cols['testScores'] == 'true')
  ) {
    return(list(
      success = FALSE,
      error = "No test codes specified"
    ))
  }

  # Get the scores
  scores = data.frame()
  if (cols['testAdmin'] == 'true' || cols['testScores'] == 'true') {
    scoresSql = paste0(
      "SELECT '",
      testCodes,
      "' COLLATE utf8_bin AS testCode, session_id, s.name COLLATE utf8_bin AS name, value COLLATE utf8_bin AS value, s.participant_id, a.id AS admin_id, a.login AS admin_login
    FROM ",
      testCodes,
      "_scores AS s 
    LEFT JOIN ",
      testCodes,
      "_sessions AS se ON se.id=s.session_id
    LEFT JOIN EASI_admins AS a ON a.id=se.admin_id
    WHERE s.participant_id IN ({{ids}}) AND session_id = (SELECT MAX(session_id) FROM ",
      testCodes,
      "_scores WHERE participant_id=s.participant_id)"
    )
    scoresSql = paste0(
      "SELECT * FROM (",
      paste0(scoresSql, collapse = " UNION ALL "),
      ") t ORDER BY testCode, name"
    )
    scores = concerto.table.query(scoresSql, params)
    if (nrow(scores) == 0) {
      scores = data.frame()
    }
  }
  # now get responses
  responses = data.frame()
  if (cols['testResponses'] == 'true') {
    responsesSql = paste0(
      "SELECT '",
      testCodes,
      "' COLLATE utf8_bin AS testCode, 
      r.session_id, 
      r.item_id, 
      CASE
      WHEN r.value COLLATE utf8_bin = i.optionValue1 COLLATE utf8_bin THEN i.optionLabel1 COLLATE utf8_bin
      WHEN r.value COLLATE utf8_bin = i.optionValue2 COLLATE utf8_bin THEN i.optionLabel2 COLLATE utf8_bin
      WHEN r.value COLLATE utf8_bin = i.optionValue3 COLLATE utf8_bin THEN i.optionLabel3 COLLATE utf8_bin
      WHEN r.value COLLATE utf8_bin = i.optionValue4 COLLATE utf8_bin THEN i.optionLabel4 COLLATE utf8_bin
      WHEN r.value COLLATE utf8_bin = i.optionValue5 COLLATE utf8_bin THEN i.optionLabel5 COLLATE utf8_bin
      END label,
      r.score, 
      r.skipped, 
      se.participant_id
      FROM ",
      testCodes,
      "_responses AS r 
      LEFT JOIN ",
      testCodes,
      "_sessions AS se ON se.id=r.session_id
      LEFT JOIN ",
      testCodes,
      "_items AS i ON i.id=r.item_id
      WHERE se.participant_id IN ({{ids}}) AND session_id = (SELECT MAX(session_id) FROM ",
      testCodes,
      "_responses LEFT JOIN ",
      testCodes,
      "_sessions as ses on ses.id=session_id WHERE ses.participant_id=se.participant_id)"
    )
    responsesSql = paste0(
      "SELECT * FROM (",
      paste0(responsesSql, collapse = " UNION ALL "),
      ") t ORDER BY testCode, item_id"
    )
    responses = concerto.table.query(responsesSql, params)
  } else {
    responses = data.frame()
  }

  # now do the R stuff
  dfi = list()
  for (name in ls(participants)) {
    dfi[[name]] = participants[[name]]
  }

  cellDefault = NA
  colIndex = length(dfi)
  adminColIndexOffset = 0
  lastTestCode = ''
  lastScoreName = ''
  lastItemId = 0

  if (
    (cols['testAdmin'] == 'true' || cols['testScores'] == 'true') &&
      nrow(scores) > 0
  ) {
    for (i in seq_len(nrow(scores))) {
      score = scores[i, ]
      participantIndex = which(participants$id == score$participant_id)

      if (score$testCode != lastTestCode) {
        if (cols['testAdmin'] == 'true') {
          dfi[[paste0(score$testCode, ": admin_id")]] = rep(
            cellDefault,
            nrow(participants)
          )
          dfi[[paste0(score$testCode, ": admin_login")]] = rep(
            cellDefault,
            nrow(participants)
          )

          colIndex = colIndex + 2
          adminColIndexOffset = 0
        }

        lastTestCode = score$testCode
      }

      if (score$name != lastScoreName) {
        if (cols['testScores'] == 'true') {
          dfi[[paste0(score$testCode, ": ", score$name)]] = rep(
            cellDefault,
            nrow(participants)
          )

          colIndex = colIndex + 1
          adminColIndexOffset = adminColIndexOffset + 1
        }

        lastScoreName = score$name
      }

      if (cols['testAdmin'] == 'true') {
        dfi[[colIndex - adminColIndexOffset - 1]][[
          participantIndex
        ]] = score$admin_id
        dfi[[colIndex - adminColIndexOffset]][[
          participantIndex
        ]] = score$admin_login
      }
      if (cols['testScores'] == 'true') {
        dfi[[colIndex]][[participantIndex]] = score$value
      }
    }
  }

  if ((cols['testResponses'] == 'true') && (nrow(responses) > 0)) {
    for (i in 1:nrow(responses)) {
      response = responses[i, ]
      participantIndex = which(participants$id == response$participant_id)

      if (response$testCode != lastTestCode || response$item_id != lastItemId) {
        dfi[[paste0(
          response$testCode,
          ": item #",
          response$item_id,
          " response label"
        )]] = rep(cellDefault, nrow(participants))
        dfi[[paste0(
          response$testCode,
          ": item #",
          response$item_id,
          " response score"
        )]] = rep(cellDefault, nrow(participants))
        dfi[[paste0(
          response$testCode,
          ": item #",
          response$item_id,
          " response skipped"
        )]] = rep(cellDefault, nrow(participants))

        colIndex = colIndex + 3
        lastTestCode = response$testCode
        lastItemId = response$item_id
      }

      dfi[[colIndex - 2]][[participantIndex]] = response$label
      dfi[[colIndex - 1]][[participantIndex]] = response$score
      dfi[[colIndex]][[participantIndex]] = response$skipped
    }
  }

  result = data.frame(dfi, check.rows = F, check.names = F, fix.empty.names = F)

  write.csv(result, filePath, row.names = F, na = "")
  return(list(
    success = TRUE,
    filename = filename,
    url = filePath
  ))
}

queueExportGenerationVoid = function(selection, cols) {
  admin = c.get("admin", T)
  if (!is.list(admin)) {
    return(NULL)
  }

  filename = paste0(format(Sys.time(), "%Y%m%dT%H%M%SZ", tz = "GMT"), ".csv")
  args = toJSON(list(participants = ids, cols = cols))
  concerto.table.query(
    "INSERT INTO EASI_export_queue SET
    session_id='{{p_session_id}}',
    timestamp=CURRENT_TIMESTAMP,
    args='{{p_args}}',
    status=0,
    filename='{{p_filename}}',
    admin_id='{{p_admin_id}}'",
    list(
      p_session_id = concerto$session$id,
      p_args = args,
      p_filename = filename,
      p_admin_id = admin$id
    )
  )
  insertId = concerto.table.lastInsertId()
  list(
    status = 0,
    id = concerto.table.lastInsertId()
  )
}

checkExportGeneration = function(id) {
  as.list(concerto.table.query(
    "SELECT id, status, filename FROM EASI_export_queue WHERE id='{{p_id}}' AND session_id='{{p_session_id}}'",
    list(
      p_id = id,
      p_session_id = concerto$session$id
    )
  ))
}

list(
  logIn = function(response) {
    logIn(response$login, response$password, response$token)
  },
  logInWithToken = function(response) {
    logInWithToken(response$token)
  },
  logInWithCode = function(response) {
    logIn("Code", response$code, response$token) # TODO: Potentially unsafe
  },
  logOut = function(response) {
    c.set("admin", NA, T)
    c.set("token", NA, T)
  },
  fetchAdmins = function(response) {
    fetchAdmins(response)
  },
  fetchParticipants = function(response) {
    fetchParticipants(response)
  },
  adminFetchParticipants = function(response) {
    adminFetchParticipants(response$query, response$admin)
  },
  fetchSingleParticipant = function(response) {
    list(participant = fetchSingleParticipant(response$id))
  },
  deleteParticipants = function(response) {
    deleteParticipantsInternal(response$selection)
  },
  toggleArchivedParticipants = function(response) {
    toggleArchivedParticipants(response$selection)
  },
  queueExportGeneration = function(response) {
    createDownload(response$selection, response$cols)
  },
  checkExportGeneration = function(response) {
    checkExportGeneration(response$id)
  },
  addParticipant = function(response) {
    result = addParticipant(response$participant)
    list(participant = result)
  },
  saveParticipant = function(response) {
    result = saveParticipant(response$participant)
    list(participant = result)
  },
  fetchAllTests = function(response) {
    result = fetchAllTests()
    list(tests = result)
  },
  fetchSessions = function(response) {
    fetchSessions(response)
  },
  addSession = function(response) {
    result = addSession(response$session)
    list(session = result)
  },
  deleteSessions = function(response) {
    deleteSessions(response$ids)
  },
  fetchScores = function(response) {
    result = fetchScores(response)
  },
  fetchSessionScores = function(response) {
    result = fetchSessionScores(response$testCode, response$sessionId)
  },
  fetchSessionResponses = function(response) {
    result = fetchSessionResponses(response$testCode, response$sessionId)
  },
  fetchDemographics = function(response) {
    result = fetchDemographics(response$participantId)
    list(demographics = result)
  },
  emailSession = function(response) {
    sendSessionEmail(response$session)
  },
  importParticipant = function(response) {
    importParticipant(response)
  },
  sendParentEmail = function(response) {
    sendParentEmail(response$participant)
  },
  updateUserProfile = function(response) {
    profileOutput = updateUserProfile(response$user, response$token)

    if (is.null(profileOutput$token)) {
      # error_state
      c.set("admin", NA, T) # log user out
      c.set("token", NA, T)
      return(list(user = NA, token = NA, error = profileOutput))
    }
    list(
      user = profileOutput$user,
      token = response$token,
      error = profileOutput$error
    )
  },
  refreshUserProfile = function(response) {
    profileOutput = refreshUserProfile(response$user, response$token)

    if (is.null(profileOutput$token)) {
      # error_state
      c.set("admin", NA, T) # log user out
      c.set("token", NA, T)
      return(list(user = NA, token = NA, error = profileOutput))
    }
    list(
      user = profileOutput$user,
      token = response$token,
      error = profileOutput$error
    )
  },
  getTherapists = function(response) {
    getTherapists(response$PaginationToken, response$Filter)
  },
  fetchDictionary = function(response) {
    fetchDictionary()
  },
  setAdminLanguage = function(response) {
    setAdminLanguage(response$languageCode)
  }
)
