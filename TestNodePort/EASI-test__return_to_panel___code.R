if(test$returnToPanel == 1) {
  concerto.log("hi from returning to panel!!!");
  url = paste0("/test/panel#!/participant/", participant$id, "/sessions")
  concerto.template.redirect(url)
}
