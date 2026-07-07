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

  scoreableResponses <- scoringResponses[
    scoringResponses$item_id %in% scoreableItemIds,
  ]

  scoreableResponses
}

getMeasure <- function(rawScore, measureLookupJson) {
  measureLookup <- jsonlite::fromJSON(measureLookupJson)
  measureLookup[[as.character(rawScore)]]
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
