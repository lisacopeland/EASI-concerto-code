createScores <- function(
  trait,
  rawScore,
  responseMean,
  includeTraitInScoreName,
  age,
  b0,
  b1,
  sd
) {
  rawScoreProp <- concerto$globals$easi$lib$getPropName(trait, "raw score", includeTraitInScoreName)
  zScoreProp <- concerto$globals$easi$lib$getPropName(trait, "z score", includeTraitInScoreName)
  percentileProp <- concerto$globals$easi$lib$getPropName(trait, "percentile", includeTraitInScoreName)
  meanProp <- concerto$globals$easi$lib$getPropName(trait, "mean score", includeTraitInScoreName)
  sdProp <- concerto$globals$easi$lib$getPropName(trait, "sd", includeTraitInScoreName)
  predictedMeanProp <- concerto$globals$easi$lib$getPropName(trait, "predicted mean", includeTraitInScoreName)

  predictedMean <- b0 + b1 * age
  zScore <- (responseMean - predictedMean) / sd
  scores <- list()
  scores[[rawScoreProp]] <- rawScore
  scores[[zScoreProp]] <- zScore
  scores[[meanProp]] <- responseMean
  scores[[predictedMeanProp]] <- predictedMean
  scores[[percentileProp]] <- round(100 * pnorm(zScore))
  scores[[sdProp]] <- sd
  scores
}

runScoring <- function(responses, items, settings) {
  allScores <- list()
  for (scoreSetting in settings$scoreSettings) {
    trait <- scoreSetting$trait
    scorableResponses <- concerto$globals$easi$lib$getScorableItems(responses, items, trait)
    rawScore <- sum(c(scorableResponses$score))
    responseMean <- mean(c(scorableResponses$score))
    if (is.null(trait) || is.na(trait)) {
      trait <- "Combined"
    }
    traitScores <- createScores(
      trait,
      rawScore,
      responseMean,
      scoreSetting$includetraitinscorename,
      settings$childsAge,
      scoreSetting$b0,
      scoreSetting$b1,
      scoreSetting$sd
    )
    allScores <- c(allScores, traitScores)
  }
  scores <- allScores
}
scores <- runScoring(responses, items, settings)

scores
