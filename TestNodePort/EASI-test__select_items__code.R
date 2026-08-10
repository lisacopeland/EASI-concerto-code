concerto.log("Hi from select items")

makeItemsSafe <- function(items) {
  for (i in 1:5) {
    items[[paste0("optionScore", i)]] <- NULL
  }

  items
}

assignResponses <- function(items, responses) {

  if (is.null(items) || nrow(items) == 0) {
    stop("assignResponses received no assessment items")
  }

  if (is.null(responses) || nrow(responses) == 0) {
    return(items)
  }
  items$value <- rep(NA_character_, nrow(items))
items$skipped <- rep(NA_integer_, nrow(items))
items$skipReason <- rep(NA_character_, nrow(items))
  if (nrow(responses) > 0) {
    for (i in seq_len(nrow(responses))) {

      response <- as.list(responses[i, , drop = FALSE])

      itemId <- as.integer(response$item_id[[1]])
      itemIndex <- match(itemId, as.integer(items$id))

      if (is.na(itemIndex)) {
        concerto.log(
          paste0(
            "assignResponses: response item_id ",
            itemId,
            " was not found in items"
          )
        )
        next
      }

      skipReason <- response$skipReason[[1]]

      if (
        is.null(skipReason) ||
        length(skipReason) == 0 ||
        is.na(skipReason)
      ) {
        skipReason <- NA_character_
      }

  items$value[itemIndex] <- responses$value[[i]]
  items$skipped[itemIndex] <- responses$skipped[[i]]
  items$skipReason[itemIndex] <- skipReason
    }
  }

  items
}

maxPages <- ceiling(nrow(items) / as.numeric(settings$itemsperpage))
if (is.na(page)) {
  page <- 1

  # to determine page, we're only checking submitted responses
  responsesNum <- nrow(responses[responses$submitted == 1, ])
  if (responsesNum > 0) {
    page <- floor(responsesNum / as.numeric(settings$itemsperpage)) + 1
    page <- min(page, maxPages)
  }
} else {
  page <- page + direction
  page <- max(1, page)
}

.branch <- "iteration"
if (page > maxPages) {
  .branch <- "end"
  endReason <- "all items administered"
} else {
  # stop algorithm
  if (!is.na(settings$stopalgo)) {
    algoName <- paste0("EASI-stop-", settings$stopalgo)
    result <- concerto.test.run(algoName, list(
      items = items,
      responses = responses,
      scores = scores,
      settings = settings
    ))

    if (!is.null(result$stopReason)) {
      .branch <- "end"
      endReason <- result$stopReason
    }
  }

  if (.branch == "iteration") {
    itemsStartIndex <- 1 + as.numeric(settings$itemsperpage) * (page - 1)
    itemsEndIndex <- min(as.numeric(settings$itemsperpage) * page, nrow(items))

    # item selection algorithm
    if (!is.na(settings$itemselectionalgo)) {
      algoName <- paste0("EASI-itemSelection-", settings$itemselectionalgo)
      result <- concerto.test.run(algoName, list(
        items = items,
        responses = responses,
        scores = scores,
        settings = settings,
        direction = direction,
        page = page,
        itemStartIndex = itemsStartIndex,
        itemEndIndex = itemEndIndex
      ))

      selectedItems <- result$selectedItems
    } else {
      # default linear algo
      childsAge <- settings$childsAge
      isAgeApplicable <-
        (is.na(items$minimumAge) | items$minimumAge <= childsAge) &
          (is.na(items$maximumAge) | items$maximumAge >= childsAge)
      selectedItems <- items[isAgeApplicable, ]
      settings$ageExcludedItemIds <- items$id[!isAgeApplicable]
      selectedItems = items[itemsStartIndex:itemsEndIndex,]
    }

    # safe items
    safeSelectedItems <- makeItemsSafe(selectedItems)
    safeSelectedItems <- assignResponses(safeSelectedItems, responses)

  }
}
