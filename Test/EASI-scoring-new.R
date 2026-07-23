# new scoring method

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

  scoringResponses <- if (is.null(trait)) {
    responses
  } else {
    responses[responses$trait == trait, ]
  }

  scoreableItemIds <- items$id[
    is.na(items$excludeFromScoring) |
      items$excludeFromScoring != 1
  ]

  scorableResponses <- scoringResponses[
    scoringResponses$item_id %in% scorableItemIds &
      scoringResponses$scoreStatus == "scored",
  ]

  scoreableResponses
}

getMeasure <- function(rawScore, measureLookupJson) {
  measureLookup <- jsonlite::fromJSON(measureLookupJson)
  measureLookup[[as.character(rawScore)]]
}

getMeasureNew <- function(responses, items, trait, stepDifficulty) {
  # first get scorable responses and the count
  scoreableResponses <- getScorableItems(responses, items, trait)
  itemCount <- nrow(scorableResponses);
  initialEstimate = 0
  convergenceTolerance = 0.01
  maxIterations = 100
  minUpdateDivisor = 1
  maxChange = 1.0

  previousPreviousEstimate = initialEstimate
  previousEstimate = initialEstimate
  currentEstimate = initialEstimate

  outputMath
  updateDivisor
  iterationCount = 0
  converged = false
  repeat {
    outputMath <- calculateExpectedScore(
        items,
        responses,
        currentEstimate
    )

    modelVariance <- outputMath$modelVariance
    expectedScore <- outputMath$expectedScore
    rawScore <- outputMath$rawScore

    if (!Number.isFinite(modelVariance) || modelVariance <= 0) {
        #`Invalid model variance: ${modelVariance}`
        
    }

    if (
        updateDivisor == undefined ||
        !hasOverShotEstimate(
            previousPreviousEstimate,
            previousEstimate,
            currentEstimate
        )
    ) {
        updateDivisor <- modelVariance
    }
    else {
        updateDivisor <- Math.max(
            updateDivisor * 2,
            minUpdateDivisor
        )
    }

    let change <-
        (rawScore - expectedScore) / updateDivisor

    change <- Math.max(
        -maxChange,
        Math.min(maxChange, change)
    )

    previousPreviousEstimate <- previousEstimate
    previousEstimate <- currentEstimate
    currentEstimate <- previousEstimate + change

    iterationCount <- iterationCount + 1

    if (!Number.isFinite(currentEstimate)) {
    # error "Ability estimate became non-finite"
    }

    converged =
        Math.abs(currentEstimate - previousEstimate) <
        convergenceTolerance

    if ((converged) || (iterationCount >= maxIterations)) {
      # error failure to converge
      break
    }

  } # bottom of the do-while

  concerto.log("after the while loop")
  if (!converged or iterationCount >= maxIterations) {
    #error
  }

  # Recalculate once at the final estimate so modelVariance,
  # residuals, infit, and outfit all correspond to the returned
  # currentEstimate.

  outputMath <- calculateExpectedScore(
          items,
          responses,
          currentEstimate
  )

  modelVariance <- outputMath.modelVariance
  rawScore <- outputMath.rawScore

  outfitMeanSquare <-
      outputMath.outfitMeanSquareNumerator / itemCount

  infitMeanSquare <-
      outputMath.infitMeanSquareNumerator /
      outputMath.infitMeanSquareDivisor

  outfitMeanSquare <- Math.min(outfitMeanSquare, 9.9)

  return {
      currentEstimate,
      modelVariance,
      rawScore,
      outfitMeanSquare,
      infitMeanSquare,
      iterationCount,
      converged
  }

}

# Iterate thru the scores and return expectedScore, modelVariance, rawScore, 
# outfitMeanSquareNumerator, infitMeanSquareNumerator, infitMeanSquareDivisor
calculateExpectedScore <- function(responses, items, abilityEstimate) {
  rawScore = 0 
  expectedScore = 0
  modelVariance = 0
  outfitMeanSquareNumerator = 0
  infitMeanSquareNumerator = 0 
  let infitMeanSquareDivisor = 0

  for (i in seq_len(nrow(responses))) {
    response <- responses[i, ]

    itemDifficulty <- items$itemDifficulty[
      items$id == response$item_id
    ][1]

    rawScore <- rawScore + response$value
    perItemResults <- perItemMath(itemDifficulty, abilityEstimate, Number(input.data.extent))
    expectedScore <- expectedScore + perItemResults.expectation
    modelVariance <- modelVariance + perItemResults.variance
    outfitMeanSquareNumerator <- outfitMeanSquareNumerator + perItemResults.itemOutfitMeanSquareNumerator
    infitMeanSquareNumerator <- infitMeanSquareNumerator + perItemResults.itemInfitMeanSquareNumerator
    infitMeanSquareDivisor <- infitMeanSquareDivisor + perItemResults.itemInfitMeanSquareDivisor
  }
  modelVariance = modelVariance < 0.00001 ? 0.00001 : modelVariance
  return { expectedScore, modelVariance, rawScore, outfitMeanSquareNumerator, infitMeanSquareNumerator, infitMeanSquareDivisor }
}

perItemMath <- function(itemDifficulty, abilityEstimate, inputData) {
    # Item difficulty is per the item
    # Ability estimate initially 0 and then gets updated over time with the (rawScore - expectedScore)/updateDivisor
    # inputData is the score for this item
    # step difficulty is the array of step difficulty for the test

    iterating thru settings$stepDifficulty
    const logit = abilityEstimate - itemDifficulty

    let normalizer = 0   // cumulative
    let expectation = 0 // cumulative
    let sumSquare = 0   // cumulative
    let currentLogit = 0 // cumulative
    let remark = ""

    for (let i = 1; i < stepDifficulty.length; i++) {
        currentLogit = currentLogit + logit - stepDifficulty[i];
        const value = Math.exp(currentLogit)
        normalizer = normalizer + value
        expectation = expectation + i * value
        sumSquare = sumSquare + i * i * value
    }
    expectation = expectation / normalizer
    const variance = (sumSquare / normalizer) - (expectation * expectation)
    const residual = inputData - expectation
    const standardizedResidual = residual / Math.sqrt(variance)
    if (standardizedResidual > 2) {
        remark = "Unexpectedly high rating"
    }
    else if (standardizedResidual < -2) {
        remark = "Unexpectedly low rating"
    }

    const itemOutfitMeanSquareNumerator = standardizedResidual * standardizedResidual
    const itemInfitMeanSquareNumerator = residual * residual
    const itemInfitMeanSquareDivisor = variance

    return { expectation, variance, itemOutfitMeanSquareNumerator, itemInfitMeanSquareNumerator, itemInfitMeanSquareDivisor, remark }
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

  predictedMean <- b0 +
    b1 * age +
    b2 * age^2 +
    b3 * age^3

  zScore <- (measure - predictedMean) / sd

  scores[[rawScoreProp]] <- rawScore
  scores[[zScoreProp]] <- zScore
  scores[[meanProp]] <- predictedMean
  scores[[percentileProp]] <- round(100 * pnorm(zScore))
  scores[[sdProp]] <- sd
  scores
}

concerto.log(
  jsonlite::toJSON(settings, pretty = TRUE, auto_unbox = TRUE)
)

concerto$globals$easi$lib$helloWorld()
allScores <- list()

for (scoreSetting in settings$scoreSettings) {
  trait <- scoreSetting$trait

  scorableResponses <- getScorableItems(responses, items, trait)

  rawScore <- sum(scorableResponses$score, na.rm = TRUE)

  measure <- getMeasure(
    rawScore,
    scoreSetting$measurelookup
  )
  if (is.null(measure)) {
    stop(
      paste(
        "No measure found for raw score",
        rawScore
      )
    )
  }
  scores <- createScores(
    trait,
    measure,
    rawScore,
    settings$includeTraitInScoreName,
    settings$childsAge,
    scoreSetting$b0,
    scoreSetting$b1,
    scoreSetting$b2,
    scoreSetting$b3,
    scoreSetting$sd
  )
  allScores <- c(allScores, scores)
}


concerto.log("scores:")
concerto.log(
  jsonlite::toJSON(allScores, pretty = TRUE, auto_unbox = TRUE)
)
scores <- allScores
