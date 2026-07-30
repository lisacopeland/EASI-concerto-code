concerto.log("Hi from response processing")

getItemResponseLabel <- function(item, itemResponse) {
  if (itemResponse$skipped) {
    return(" ")
  }
  if (is.na(item$scoreMapType)) {
    return(getDefaultMapLabel(item, itemResponse))
  }

  switch(item$scoreMapType,
    getDefaultMapLabel(item, itemResponse)
  )
}

getDefaultMapLabel <- function(item, itemResponse) {
  value <- getItemResponseScorableValue(item, itemResponse)
  for (i in 1:5) {
    valueProp <- paste0("optionValue", i)
    labelProp <- paste0("optionLabel", i)
    if (!is.na(item[[valueProp]]) && !is.null(value)) {
      if (item[[valueProp]] == value) {
        return(item[[labelProp]])
      }
    } else {
      break
    }
  }

  NULL
}

# gets single numeric representation of response value
getItemResponseScorableValue <- function(item, itemResponse) {
  switch(item$type,
    subtract = getSubtractScorableValue(item, itemResponse),
    itemResponse$value
  )
}

getSubtractScorableValue <- function(item, itemResponse) {
  if (is.null(itemResponse$value)) {
    return(NULL)
  }
  as.numeric(itemResponse$value[1]) - as.numeric(itemResponse$value[2])
}

getItemResponseSerializableValue <- function(item, itemResponse) {
  if (itemResponse$skipped) {
    return(0)
  }
  switch(item$type,
    subtract = getSubtractSerializableValue(item, itemResponse),
    itemResponse$value
  )
}

getSubtractSerializableValue <- function(item, itemResponse) {
  if (is.null(itemResponse$value)) {
    return(NULL)
  }
  toJSON(c(as.numeric(itemResponse$value[1]), as.numeric(itemResponse$value[2])))
}

getItemScore <- function(item, itemResponse) {
  if (
    is.null(itemResponse) ||
      item$excludeFromScoring == 1 ||
      itemResponse$skipped == 1
  ) {
    return(NA)
  }
  if (is.na(item$scoreMapType)) {
    newScore <- getDefaultMapScore(item, itemResponse)
    return(newScore)
  }

  switch(item$scoreMapType,
    range = getRangeTypeScore(item, itemResponse),
    getDefaultMapScore(item, itemResponse)
  )
}

getDefaultMapScore <- function(item, itemResponse) {
  score <- NA
  value <- getItemResponseScorableValue(item, itemResponse)
  if (!is.null(value)) {
    score <- as.numeric(value)
  }
  for (i in 1:5) {
    valueProp <- paste0("optionValue", i)
    scoreProp <- paste0("optionScore", i)
    if (!is.na(item[[valueProp]]) && !is.null(value)) {
      if (item[[valueProp]] == value) {
        return(item[[scoreProp]])
      }
    } else {
      break
    }
  }

  score
}

getRangeTypeScore <- function(item, itemResponse) {
  score <- NA
  responseValue <- getItemResponseScorableValue(item, itemResponse)
  if (!is.null(responseValue)) {
    responseValue <- as.numeric(responseValue)
  }

  if (!is.null(responseValue)) {
    for (i in 1:5) {
      valueProp <- paste0("optionValue", i)
      scoreProp <- paste0("optionScore", i)
      rangeStart <- as.numeric(item[[valueProp]])
      rangeScore <- as.numeric(item[[scoreProp]])
      if (i == 1 && is.na(rangeStart) && !is.na(rangeScore)) {
        score <- rangeScore
      }
      if (!is.na(rangeStart) && responseValue >= rangeStart) {
        score <- rangeScore
      }
    }
  }

  score
}

getItemResponse <- function(item, itemResponses) {
  if (length(itemResponses) > 0) {
    for (i in seq_along(itemResponses)) {
      if (itemResponses[[i]]$item_id == item$id) {
        return(itemResponses[[i]])
      }
    }
  }

  NULL
}

createResponseList <- function(responses, items, ageExcludedItemIds = NULL) {
  responses <- vector("list", nrow(items))
  for (i in seq_len(nrow(items))) {
    item <- items[i, ]

    # if (is.null(itemResponse)) {
    #  stop(
    #    paste0(
    #      "No response found for item ",
    #      item$id
    #    )
    #  )
    # }

    if (!is.null(ageExcludedItemIds) &&
      item$id %in% ageExcludedItemIds) {
      responses[[i]] <- list(
        # item is age excluded
        item = item,
        item_id = item$id,
        trait = item$trait,
        value = 0,
        score = 0,
        label = "",
        skipped = 0,
        skipReason = " ",
        scoreStatus = "scored"
      )
    } else {
      itemResponse <- getItemResponse(item, responses)
      score <- getItemScore(item, itemResponse)
      responses[[i]] <- list(
        item = item,
        item_id = item$id,
        trait = item$trait,
        value = getItemResponseSerializableValue(
          item,
          itemResponse
        ),
        score = score,
        label = getItemResponseLabel(
          item,
          itemResponse
        ),
        skipped = itemResponse$skipped,
        skipReason = itemResponse$skipReason,
        scoreStatus = if (!is.na(score)) {
          "scored"
        } else {
          "not scored"
        }
      )
    }
  }
  responses
}

createSql <- function(response, selectedItems, test, session, settings, responseTable) {
  # direction
  direction <- 0
  if (response$buttonPressed == "next") {
    direction <- 1
  }
  if (settings$cangoback == 1 && response$buttonPressed == "previous") {
    direction <- -1
  }

  responseList <- createResponseList(response$responseList, selectedItems, settings$ageExcludedItemsIds)
  insertSql <- concerto.table.insertParams("INSERT INTO {{responseTable}} (session_id, item_id, label, value, score, timeTaken, trait, timeCreated, submitted, skipped) VALUES ", list(responseTable = responseTable))
  responseSqlArray <- NULL
  for (i in seq_len(nrow(responseList))) {
    itemResponse <- responseList[i, ]
    # here, you will see if the item was skipped and if so if it should get a 0 or a NS
    responseSql <- "('{{session_id}}', '{{item_id}}', IF('{{label}}'='', NULL, '{{label}}'), IF('{{value}}'='', NULL, '{{value}}'), IF('{{score}}'='', NULL, '{{score}}'), '{{timeTaken}}', '{{trait}}', NOW(), '{{submitted}}', '{{skipped}}', '{{scoreStatus}}' {{skipReason}})"
    responseSql <- concerto.table.insertParams(responseSql, list(
      session_id = session$id,
      item_id = itemResponse$item$id,
      value = itemResponse$value,
      score = itemResponse$score,
      label = itemResponse$label,
      timeTaken = response$timeTaken,
      trait = itemResponse$item$trait,
      submitted = if (direction == 1) {
        1
      } else {
        0
      },
      skipped = itemResponse$skipped,
      scoreStatus = itemResponse$scoreStatus,
      skipReason = itemResponse$skipReason
    ))
    responseSqlArray <- c(responseSqlArray, responseSql)
  }
  
  insertSql <- paste0(insertSql, paste0(responseSqlArray, collapse = ","))
  insertSql
}

# call createSql with the provided data
responseTable <- paste0(test$code, "_responses")
insertSql <- createSql(response, selectedItems, test, session, settings, responseTable)

concerto.table.query("DELETE FROM {{responseTable}} WHERE session_id='{{session_id}}' AND item_id IN ({{item_ids}})", list(
  responseTable = responseTable,
  session_id = session$id,
  item_ids = item_ids
))

# call the query to insert the responses
concerto.table.query(insertSql)

# reading responses
responses <- concerto.table.query("SELECT * FROM {{responseTable}} WHERE session_id='{{session_id}}'", list(responseTable = responseTable, session_id = session$id))
