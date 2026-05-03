library(catR)

scores = list()
params = as.matrix(items[items$id %in% responses$item_id, c("p1", "p2", "p3", "p4")])
x = responses$score

method = "BM"
if(is.character(settings$method)) { method = settings$method }

scores$theta = thetaEst(params, x, method=method)
scores$sem = semTheta(scores$theta, params, x, method=method)