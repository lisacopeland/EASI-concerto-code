isValid <- function(trait) {
  !is.null(trait) && !is.na(trait) && length(trait) > 0
}

getPropName <- function(trait, name, includeTraitInScoreName = FALSE) {
  if (isValid(trait) && includeTraitInScoreName) {
    paste0(trait, " - ", name)
  } else {
    name
  }
}

getScorableItems <- function(responses, items, trait = NULL) {

scoringResponses <- if (
  is.null(trait) ||
  length(trait) == 0 ||
  is.na(trait) ||
  !nzchar(trait)
) {
    responses
  } else {
    responses[responses$trait == trait, ]
  }
  
  scoreableItems <- items[
    is.na(items$excludeFromScoring) |
      items$excludeFromScoring != 1, ,
    drop = FALSE
  ]



  responseKeys <- paste(
    scoringResponses$test,
    scoringResponses$item_id
  )

  itemKeys <- paste(
    scoreableItems$test,
    scoreableItems$id
  )

  scoreableResponses <- scoringResponses[
    responseKeys %in% itemKeys &
      scoringResponses$scoreStatus == "scored",
  ]

  scoreableResponses
}

getScoreRange <- function(responses, items) {
  rawScore <- sum(responses$score)

  minimumScore <- 0
  maximumScore <- 0

  for (i in seq_len(nrow(responses))) {
    item <- items[
      items$id == responses$item_id[i] &
        items$test == responses$test[i], ,
      drop = FALSE
    ]

    optionScores <- c(
      item$optionScore1,
      item$optionScore2,
      item$optionScore3,
      item$optionScore4,
      item$optionScore5
    )

    optionScores <- optionScores[!is.na(optionScores)]

    minimumScore <- minimumScore + min(optionScores)
    maximumScore <- maximumScore + max(optionScores)
  }

  adjustedScore <- rawScore

  isMinimumScore <- FALSE
  isMaximumScore <- FALSE

  if (rawScore == minimumScore) {
    adjustedScore <- minimumScore + 0.5
    isMinimumScore <- TRUE
  } else if (rawScore == maximumScore) {
    adjustedScore <- maximumScore - 0.5
    isMaximumScore <- TRUE
  }

  list(
    rawScore = rawScore,
    adjustedScore = adjustedScore,
    minimumScore = minimumScore,
    maximumScore = maximumScore,
    isMinimumScore = isMinimumScore,
    isMaximumScore = isMaximumScore
  )
}

getMeasure <- function(responses, items, scoreRange) {
  itemCount <- nrow(responses)
  initialEstimate <- 0
  convergenceTolerance <- 0.01
  maxIterations <- 100
  minUpdateDivisor <- 1
  maxChange <- 1.0

  previousPreviousEstimate <- initialEstimate
  previousEstimate <- initialEstimate
  currentEstimate <- initialEstimate

  updateDivisor <- 0
  iterationCount <- 0
  converged <- FALSE

  repeat {
    outputMath <- calculateExpectedScore(
      responses,
      items,
      currentEstimate
    )
    if (is.null(outputMath)) {
      return(NULL)
    }
    modelVariance <- outputMath$modelVariance
    expectedScore <- outputMath$expectedScore

    if (!is.finite(modelVariance) || modelVariance <= 0) {
      concerto.log(paste0("Invalid model variance: ", modelVariance))
      return(NULL)
    }
    # todo: maybe this should be if first time... or
    if (!hasOverShotEstimate(
      previousPreviousEstimate,
      previousEstimate,
      currentEstimate
    )
    ) {
      updateDivisor <- modelVariance
    } else {
      updateDivisor <- max(
        updateDivisor * 2,
        minUpdateDivisor
      )
    }

    change <-
      (scoreRange$adjustedScore - expectedScore) / updateDivisor

    change <- max(
      -maxChange,
      min(maxChange, change)
    )

    previousPreviousEstimate <- previousEstimate
    previousEstimate <- currentEstimate
    currentEstimate <- previousEstimate + change

    iterationCount <- iterationCount + 1

    if (!is.finite(currentEstimate)) {
      concerto.log(paste0("Ability estimate became non-finite", currentEstimate))
      return(NULL)
    }

    converged <- abs(currentEstimate - previousEstimate) < convergenceTolerance

    if ((converged) || (iterationCount >= maxIterations)) {
      break
    }
  } # bottom of the do-while

  if (!converged || (iterationCount >= maxIterations)) {
    concerto.log(paste0("failure to converge after ", iterationCount))
    return(NULL)
  }

  # Recalculate once at the final estimate so modelVariance,
  # residuals, infit, and outfit all correspond to the returned
  # currentEstimate.

  outputMath <- calculateExpectedScore(
    responses,
    items,
    currentEstimate
  )
  if (is.null(outputMath)) {
    return(NULL)
  }
  modelVariance <- outputMath$modelVariance

  outfitMeanSquare <-
    outputMath$outfitMeanSquareNumerator / itemCount

  infitMeanSquare <-
    outputMath$infitMeanSquareNumerator / outputMath$infitMeanSquareDivisor

  outfitMeanSquare <- min(outfitMeanSquare, 9.9)

  list(
    currentEstimate = currentEstimate,
    modelVariance = modelVariance,
    outfitMeanSquare = outfitMeanSquare,
    infitMeanSquare = infitMeanSquare,
    iterationCount = iterationCount,
    converged = converged
  )
}

# Iterate thru the scores and return expectedScore, modelVariance, rawScore,
# outfitMeanSquareNumerator, infitMeanSquareNumerator, infitMeanSquareDivisor
calculateExpectedScore <- function(responses, items, abilityEstimate) {
  expectedScore <- 0
  modelVariance <- 0
  outfitMeanSquareNumerator <- 0
  infitMeanSquareNumerator <- 0
  infitMeanSquareDivisor <- 0

  for (i in seq_len(nrow(responses))) {
    response <- responses[i, ]

    responseKey <- paste(response$test, response$item_id, sep = "_")
    itemKeys <- paste(items$test, items$id, sep = "_")

    itemIndex <- match(responseKey, itemKeys)

    if (is.na(itemIndex)) {
      concerto.log(
        paste0(
          "No item found for response test/item_id ",
          response$test,
          "/",
          response$item_id
        )
      )
      return(NULL)
    }

    itemDifficulty <- items$itemDifficulty[itemIndex]
    stepDifficulty <- jsonlite::fromJSON(items$stepDifficulty[itemIndex])
    perItemResults <- perItemMath(
      itemDifficulty,
      abilityEstimate,
      response$score,
      stepDifficulty
    )

    expectedScore <- expectedScore + perItemResults$expectation
    modelVariance <- modelVariance + perItemResults$variance
    outfitMeanSquareNumerator <- outfitMeanSquareNumerator + perItemResults$itemOutfitMeanSquareNumerator
    infitMeanSquareNumerator <- infitMeanSquareNumerator + perItemResults$itemInfitMeanSquareNumerator
    infitMeanSquareDivisor <- infitMeanSquareDivisor + perItemResults$itemInfitMeanSquareDivisor
  }
  modelVariance <- max(modelVariance, 0.00001)
  list(
    expectedScore = expectedScore,
    modelVariance = modelVariance,
    outfitMeanSquareNumerator = outfitMeanSquareNumerator,
    infitMeanSquareNumerator = infitMeanSquareNumerator,
    infitMeanSquareDivisor = infitMeanSquareDivisor
  )
}

perItemMath <- function(itemDifficulty, abilityEstimate, responseScore, stepDifficulty) {
  # Item difficulty is per the item
  # Ability estimate initially 0 and then gets updated over time with the
  # inputData is the score for this item
  # step difficulty is the array of step difficulty for the test
  # iterating thru settings$stepDifficulty
  logit <- abilityEstimate - itemDifficulty
  normalizer <- 0
  expectation <- 0
  sumSquare <- 0
  currentLogit <- 0
  remark <- ""
  for (i in seq_along(stepDifficulty)) {
    stepIndex <- i - 1
    currentLogit <- currentLogit + logit - stepDifficulty[i]
    value <- exp(currentLogit)
    normalizer <- normalizer + value
    expectation <- expectation + stepIndex * value
    sumSquare <- sumSquare + stepIndex * stepIndex * value
  }
  expectation <- expectation / normalizer
  variance <- (sumSquare / normalizer) - (expectation * expectation)
  residual <- responseScore - expectation
  standardizedResidual <- residual / sqrt(variance)
  if (standardizedResidual > 2) {
    remark <- "Unexpectedly high rating"
  } else if (standardizedResidual < -2) {
    remark <- "Unexpectedly low rating"
  }

  itemOutfitMeanSquareNumerator <- standardizedResidual * standardizedResidual
  itemInfitMeanSquareNumerator <- residual * residual
  itemInfitMeanSquareDivisor <- variance

  list(
    expectation = expectation,
    variance = variance,
    itemOutfitMeanSquareNumerator = itemOutfitMeanSquareNumerator,
    itemInfitMeanSquareNumerator = itemInfitMeanSquareNumerator,
    itemInfitMeanSquareDivisor = itemInfitMeanSquareDivisor,
    remark = remark
  )
}

hasOverShotEstimate <- function(prevprev, prev, curr) {
  peaked <- prevprev < prev && curr < prev
  dipped <- prevprev > prev && curr > prev

  peaked || dipped
}


createScores <- function(
  trait,
  measure,
  rawScore,
  includeTraitInScoreName,
  age,
  b0,
  b1,
  b2,
  b3,
  sd
) {
  rawScoreProp <- getPropName(trait, "raw score", includeTraitInScoreName)
  zScoreProp <- getPropName(trait, "z score", includeTraitInScoreName)
  percentileProp <- getPropName(trait, "percentile", includeTraitInScoreName)
  meanProp <- getPropName(trait, "predicted mean", includeTraitInScoreName)
  sdProp <- getPropName(trait, "sd", includeTraitInScoreName)
  measureProp <- getPropName(trait, "measure", includeTraitInScoreName)

  predictedMean <- b0 +
    b1 * age +
    b2 * age^2 +
    b3 * age^3

  zScore <- (measure - predictedMean) / sd
  scores <- list()
  scores[[rawScoreProp]] <- rawScore
  scores[[zScoreProp]] <- zScore
  scores[[meanProp]] <- predictedMean
  scores[[percentileProp]] <- round(100 * pnorm(zScore))
  scores[[sdProp]] <- sd
  scores[[measureProp]] <- measure
  scores
}


runScoring <- function(responses, items, settings) {

  allScores <- list()
  for (scoreSetting in settings$scoreSettings) {
    trait <- scoreSetting$trait
    scorableResponses <- getScorableItems(responses, items, trait)

    
    scoreRange <- getScoreRange(scorableResponses, items)
    newMeasure <- getMeasure(scorableResponses, items, scoreRange)

    concerto.log("from newMeasure: ")
    concerto.log(
      jsonlite::toJSON(newMeasure, pretty = TRUE, auto_unbox = TRUE)
    )
    if (is.null(newMeasure) || is.null(newMeasure$currentEstimate)) {
      scores <- list()
      scores[["error"]] <- "Measure calculation failed"
      return(scores)
    }

    # newMeasure$currentEstimate instead of measure here
    scores <- createScores(
      trait,
      newMeasure$currentEstimate,
      scoreRange$rawScore,
      scoreSetting$includetraitinscorename,
      settings$childsAge,
      scoreSetting$b0,
      scoreSetting$b1,
      scoreSetting$b2,
      scoreSetting$b3,
      scoreSetting$sd
    )
    allScores <- c(allScores, scores)
  }
  scores <- allScores
}

scores <- runScoring(responses, items, settings)
