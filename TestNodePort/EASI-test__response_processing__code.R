concerto.log("Hi from response processing")

getItemResponseLabel <- function(item, itemResponse) {
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
  if (is.na(itemResponse) || item$excludeFromScoring == 1 || itemResponse$skipped == 1) {
    return(NA)
  }
  if (is.na(item$scoreMapType)) {
    return(getDefaultMapScore(item, itemResponse))
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
    for (i in 1:length(itemResponses)) {
      if (itemResponses[[i]]$item_id == item$id) {
        return(itemResponses[[i]])
      }
    }
  }
  NA
}

# direction
direction <- 0
if (response$buttonPressed == "next") {
  direction <- 1
}
if (settings$cangoback == 1 && response$buttonPressed == "previous") {
  direction <- -1
}

# scoring and saving response
responseTable <- paste0(test$code, "_responses")
insertSql <- concerto.table.insertParams("INSERT INTO {{responseTable}} (session_id, item_id, label, value, score, timeTaken, trait, timeCreated, submitted, skipped) VALUES ", list(responseTable = responseTable))
responseSqlArray <- NULL
# selected Items will not include any ageExcluded Items
for (i in 1:nrow(selectedItems)) {
  item <- selectedItems[i, ]

  itemResponse <- getItemResponse(item, response$itemResponses)

  # here, you will see if the item was skipped and if so if it should get a 0 or a NS
  if (itemResponse$skipped) {
    label <- ""
    value <- 0
    score <- 0
    if (itemResponse$skipReason == "gimme a 0") {
      scoreStatus <- "scored"
    } else {
      scoreStatus <- "not scored"
    }
    # if the skip reason is X then scoreStatus = "not scored" else scoreStatus is scored and score is 0
  } else {
    scoreStatus <- "scored"
    label <- getItemResponseLabel(item, itemResponse)
    score <- getItemScore(item, itemResponse)
  }

  responseSql <- "('{{session_id}}', '{{item_id}}', IF('{{label}}'='', NULL, '{{label}}'), IF('{{value}}'='', NULL, '{{value}}'), IF('{{score}}'='', NULL, '{{score}}'), '{{timeTaken}}', '{{trait}}', NOW(), '{{submitted}}', '{{skipped}}', '{{scoreStatus}}' {{skipReason}})"
  responseSql <- concerto.table.insertParams(responseSql, list(
    session_id = session$id,
    item_id = item$id,
    value = getItemResponseSerializableValue(item, itemResponse),
    score = score,
    label = label,
    timeTaken = response$timeTaken,
    trait = item$trait,
    submitted = if (direction == 1) {
      1
    } else {
      0
    },
    skipped = if (itemResponse$skipped == 1) {
      1
    } else {
      0
    },
    itemResponse$scoreStatus,
    itemResponse$skipReason
    # Now add the skipped reason
  ))
  responseSqlArray <- c(responseSqlArray, responseSql)
}


insertSql <- paste0(insertSql, paste0(responseSqlArray, collapse = ","))

# Now see if there are ageExcludedItems:
ageExcludedItemIds <- settings$ageExcludedItemIds

if (is.null(ageExcludedItemIds)) {
  ageExcludedItemIds <- integer(0)
} else if (length(ageExcludedItemIds) > 0) {
  ageExcludedItems <- items[
    items$id %in% ageExcludedItemIds,
  ]
  for (i in seq_len(nrow(ageExcludedItems))) {
    item <- ageExcludedItems[i, ]

    responseSql <- "(
    '{{session_id}}',
    '{{item_id}}',
    IF('{{label}}'='', NULL, '{{label}}'),
    IF('{{value}}'='', NULL, '{{value}}'),
    IF('{{score}}'='', NULL, '{{score}}'),
    '{{timeTaken}}',
    '{{trait}}',
    NOW(),
    '{{submitted}}',
    '{{skipped}}',
    '{{scoreStatus}}'
  )"

    responseSql <- concerto.table.insertParams(
      responseSql,
      list(
        session_id = session$id,
        item_id = item$id,
        label = "",
        value = 0,
        score = 0,
        timeTaken = response$timeTaken,
        trait = item$trait,
        submitted = if (direction == 1) 1 else 0,
        skipped = 0,
        scoreStatus = "scored"
      )
    )

    responseSqlArray <- c(responseSqlArray, responseSql)
  }
}

# remove previous responses before inserting the new ones
concerto.table.query("DELETE FROM {{responseTable}} WHERE session_id='{{session_id}}' AND item_id IN ({{item_ids}})", list(
  responseTable = responseTable,
  session_id = session$id,
  item_ids = paste0(selectedItems$id, collapse = ",")
))

concerto.table.query(insertSql)

# reading responses
responses <- concerto.table.query("SELECT * FROM {{responseTable}} WHERE session_id='{{session_id}}'", list(responseTable = responseTable, session_id = session$id))
