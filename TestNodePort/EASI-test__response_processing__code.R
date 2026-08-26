concerto.log("Hi from response processing")

getItemResponseLabel <- function(item, itemResponse) {

  if (!is.null(itemResponse$skipped) && itemResponse$skipped == "1") {
    value <- 0
  } else {
    value <- getItemResponseScorableValue(item, itemResponse)
  }

  if (is.null(value)) {
    return(NULL)
  }

  for (i in 1:5) {
    valueProp <- paste0("optionValue", i)
    labelProp <- paste0("optionLabel", i)

    if (is.na(item[[valueProp]])) {
      break
    }

    if (item[[valueProp]] == value) {
      return(item[[labelProp]])
    }
  }

  NULL
}

# gets single numeric representation of response value
getItemResponseScorableValue <- function(item, itemResponse) {
  if (
    (!is.null(itemResponse$skipped) && itemResponse$skipped == "1") &&
      itemResponse$skipReason == "Item exceeded the child's ability"
  ) {
    return(0)
  }
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

getSubtractSerializableValue <- function(item, itemResponse) {
  if (is.null(itemResponse$value)) {
    return(NULL)
  }
  toJSON(c(as.numeric(itemResponse$value[1]), as.numeric(itemResponse$value[2])))
}

getItemScore <- function(item, itemResponse) {
  if (is.na(item$scoreMapType)) {
    newScore <- getDefaultMapScore(item, itemResponse)
    return(newScore)
  }

  switch(item$scoreMapType,
    range = getRangeTypeScore(item, itemResponse),
    getDefaultMapScore(item, itemResponse)
  )
}

getItemScoringResult <- function(item, itemResponse) {
  if (is.null(itemResponse)) {
    return(list(
      score = NA_real_,
      value = NA_real_,
      label = NA_real_,
      scoreStatus = "not scored"
    ))
  }

if (!is.null(itemResponse$skipped) && (itemResponse$skipped == "1")) {
    if (itemResponse$skipReason == "Item exceeded the child's ability") {
      label <- getItemResponseLabel(item, itemResponse)
      return(list(
        score = 0,
        value = 0,
        label = label,
        scoreStatus = "scored"
      ))
    } else {
      return(list(
        score = NA_real_,
        value = NA_real_,
        label = NA_real_,
        scoreStatus = "not scored"
      ))
    }
  }
  
  score <- getItemScore(item, itemResponse)
  label <- getItemResponseLabel(item, itemResponse)

  list(
    score = score,
    value = itemResponse$value,
    scoreStatus = "scored",
    label = label
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

createResponseList <- function(itemResponses, items, ageExcludedItemIds = NULL) {
  responseList <- vector("list", nrow(items))
  for (i in seq_len(nrow(items))) {
    item <- items[i, ]

    if (!is.null(ageExcludedItemIds) &&
      item$id %in% ageExcludedItemIds) {
      responseList[[i]] <- data.frame(
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
      itemResponse <- getItemResponse(item, itemResponses)
      if (!is.null(itemResponse)) {
        scoringResult <- getItemScoringResult(item, itemResponse)

        skipReason <- itemResponse$skipReason
        skipStr <- "0"
        if ((!is.null(itemResponse$skipped) && itemResponse$skipped == "1")) {
          skipStr <- "1"
        }

        if (is.null(skipReason) || length(skipReason) == 0) {
          skipReason <- NA_character_
        }
        serializedValue <- if (item$type == "subtract") {
          getSubtractSerializableValue(item, itemResponse)
        } else {
          scoringResult$value
        }

        concerto.log(paste0(
          "item_id=", item$id,
          "; value =", serializedValue,
          "; score =", scoringResult$score,
          "; label =", scoringResult$label,
          "; skipped =", itemResponse$skipped,
          "; skipReason =", skipReason,
          "; scoreStatus ", scoringResult$scoreStatus
        ))
        responseList[[i]] <- data.frame(
          item_id = item$id,
          trait = item$trait,
          value = serializedValue,
          score = scoringResult$score,
          label = scoringResult$label,
          skipped = skipStr,
          skipReason = skipReason,
          scoreStatus = scoringResult$scoreStatus
        )
      }
    }
  }
  do.call(rbind, responseList)
}

createSql <- function(response, selectedItems, test, session, settings, responseTable) {
  responseList <- createResponseList(response$itemResponses, selectedItems, settings$ageExcludedItemIds)

  insertSql <- concerto.table.insertParams(
    paste0(
      "INSERT INTO {{responseTable}} ",
      "(session_id, item_id, label, value, score, timeTaken, ",
      "trait, timeCreated, submitted, skipped, skipReason, scoreStatus) VALUES "
    ),
    list(responseTable = responseTable)
  )
  responseSqlArray <- character(nrow(responseList))
  for (i in seq_len(nrow(responseList))) {
    processedResponse <- responseList[i, , drop = FALSE]

    responseSql <- paste0(
      "('{{session_id}}', '{{item_id}}', ",
      "IF('{{label}}'='', NULL, '{{label}}'), ",
      "IF('{{value}}'='', NULL, '{{value}}'), ",
      "IF('{{score}}'='', NULL, '{{score}}'), ",
      "'{{timeTaken}}', '{{trait}}', NOW(), ",
      "'{{submitted}}', '{{skipped}}', '{{skipReason}}', '{{scoreStatus}}')"
    )
    responseSqlArray[i] <- concerto.table.insertParams(
      responseSql,
      list(
        session_id = session$id,
        item_id = processedResponse$item_id[[1]],
        value = processedResponse$value[[1]],
        score = processedResponse$score[[1]],
        label = processedResponse$label[[1]],
        timeTaken = response$timeTaken,
        trait = processedResponse$trait[[1]],
        submitted = if (direction == 1) 1 else 0,
        skipped = processedResponse$skipped[[1]],
        skipReason = processedResponse$skipReason[[1]],
        scoreStatus = processedResponse$scoreStatus[[1]]
      )
    )
  }

  paste0(
    insertSql,
    paste(responseSqlArray, collapse = ",")
  )
}

# call createSql with the provided data
responseTable <- paste0(test$code, "_responses")

direction <- 0
if (response$buttonPressed == "next") {
  direction <- 1
}
if (settings$cangoback == 1 && response$buttonPressed == "previous") {
  direction <- -1
}
insertSql <- createSql(response, selectedItems, test, session, settings, responseTable)

concerto.table.query("DELETE FROM {{responseTable}} WHERE session_id='{{session_id}}'", list(
  responseTable = responseTable,
  session_id = session$id
))

# call the query to insert the responses
concerto.table.query(insertSql)

# reading responses
responses <- concerto.table.query("SELECT * FROM {{responseTable}} WHERE session_id='{{session_id}}'", list(responseTable = responseTable, session_id = session$id))
