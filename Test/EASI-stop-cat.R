stopReason = NULL

minSem = 0
if(!is.null(settings$minsem) && !is.na(minSem)) { minSem = as.numeric(settings$minsem) }

if(!is.null(scores$sem) && scores$sem < minSem) {
  stopReason = "min sem reached"
}
