getPropName = function(trait, name) {
  if(isValid(trait)) { paste0(trait, " - ", name) } else { name }
}

isValid = function(trait) {
  !is.null(trait) && !is.na(trait) && length(trait) > 0
}

addScores = function(responses, scores, trait=NULL) {
  rawScoreProp = getPropName(trait, "raw score")
  zScoreProp = getPropName(trait, "z score")
  percentileProp = getPropName(trait, "percentile")
  meanProp = tolower(getPropName(trait, "mean"))
  sdProp = tolower(getPropName(trait, "sd"))

  rawScoreMethod = "sum"
  if(isValid(settings$rawscoremethod) ) { rawScoreMethod = settings$rawscoremethod }
  rawScore = switch(rawScoreMethod,
                    sum = sum(responses$score, na.rm=T),
                    mean = mean(responses$score, na.rm=T),
                    sum(responses$score, na.rm=T))

  scores[[rawScoreProp]] = rawScore
  scores[[zScoreProp]] = (scores[[rawScoreProp]] - as.numeric(settings[[meanProp]])) / as.numeric(settings[[sdProp]])
  if(!isValid(scores[[zScoreProp]])) { scores[[zScoreProp]] = NA }
  scores[[percentileProp]] = 100 * pnorm(scores[[zScoreProp]])
  scores[[percentileProp]] = min(99, max(1, round(scores[[percentileProp]])))
  scores
}

if(isValid(settings$splittraits) && settings$splittraits == 1) {
  traits = unique(responses$trait)
  for(trait in traits) {
    responseIndices = if(is.na(trait)) { is.na(responses$trait) } else { responses$trait == trait}
    traitResponses = responses[responseIndices,]
    scores = addScores(traitResponses, scores, trait)
  }
} else {
  scores = addScores(responses, scores)
}
