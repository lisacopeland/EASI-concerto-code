library(catR)

selectedItems = NULL
params = as.matrix(items[, c("p1", "p2", "p3", "p4")])
out = suppressWarnings(which(responses$item_id == items$id))
x = responses$score

theta = 0
if(!is.null(scores$theta)) { theta = scores$theta }
criterion = "MFI"
if(is.character(settings$criterion)) { criterion = settings$criterion }
method = "BM"
if(is.character(settings$method)) { method = settings$method }
randomesque = 1
if(!is.null(settings$randomesque) && !is.na(randomesque)) { randomesque = as.numeric(settings$randomesque) }

for(i in itemStartIndex:itemEndIndex) {
  if(nrow(responses) >= i) {
    itemIndex = which(items$id==responses[i, "item_id"])
	selectedItems = rbind(selectedItems, items[itemIndex,])
  } else {
    itemIndex = nextItem(params, theta=theta, out=out, x=x, criterion=criterion, method=method, randomesque=randomesque)$item
    selectedItems = rbind(selectedItems, items[itemIndex,])
    out = c(out, itemIndex)
    x = c(x, NA)
  }
}
