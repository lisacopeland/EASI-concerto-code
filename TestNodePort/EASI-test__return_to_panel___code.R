if(test$returnToPanel == 1) {
  url = paste0("/test/panel#!/participant/", participant$id, "/sessions?return=1")
  concerto.template.redirect(url)
}