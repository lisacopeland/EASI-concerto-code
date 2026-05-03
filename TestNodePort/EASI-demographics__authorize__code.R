participant = concerto.table.query("SELECT * FROM EASI_participants WHERE id='{{p_pid}}' AND demographicsToken='{{p_pt}}'", list(
  p_pid=pid,
  p_pt=pt
))

.branch = "unauthorized"
if(nrow(participant) > 0) {
  .branch = "authorized"
  participant = as.list(participant[1,])
}