addScores <- function(responses, scores, trait = NULL) {
  rawScoreProp <- concerto$globals$easi$lib$getPropName(trait, "raw score")
  zScoreProp <- concerto$globals$easi$lib$getPropName(trait, "z score")
  percentileProp <- concerto$globals$easi$lib$getPropName(trait, "percentile")
  meanProp <- tolower(concerto$globals$easi$lib$getPropName(trait, "mean"))
  sdProp <- tolower(concerto$globals$easi$lib$getPropName(trait, "sd"))

  rawScoreMethod <- "sum"
  if (concerto$globals$easi$lib$isValid(settings$rawscoremethod)) {
    rawScoreMethod <- settings$rawscoremethod
  }
  rawScore <- switch(rawScoreMethod,
    sum = sum(responses$score, na.rm = T),
    mean = mean(responses$score, na.rm = T),
    sum(responses$score, na.rm = T)
  )

  scores[[rawScoreProp]] <- rawScore
  scores[[zScoreProp]] <- (scores[[rawScoreProp]] - as.numeric(settings[[meanProp]])) / as.numeric(settings[[sdProp]])
  if (!concerto$globals$easi$lib$isValid(scores[[zScoreProp]])) {
    scores[[zScoreProp]] <- NA
  }
  scores[[percentileProp]] <- 100 * pnorm(scores[[zScoreProp]])
  scores[[percentileProp]] <- min(99, max(1, round(scores[[percentileProp]])))
  scores
}

if (concerto$globals$easi$lib$isValid(settings$splittraits) && settings$splittraits == 1) {
  traits <- unique(responses$trait)
  for (trait in traits) {
    responseIndices <- if (is.na(trait)) {
      is.na(responses$trait)
    } else {
      responses$trait == trait
    }
    traitResponses <- responses[responseIndices, ]
    scores <- addScores(traitResponses, scores, trait)
  }
} else {
  scores <- addScores(responses, scores)
}
