concerto.table.query("DELETE FROM EASI_demographics_fields_responses WHERE participant_id='{{p_pid}}'", list(p_pid=participant$id))

for(i in 1:nrow(fields)) {
  field = fields[i,]

  value = response$responses[[field$name]]
  concerto.log(value, field$name)
  if(!is.null(value)) {
    concerto.table.query("INSERT INTO EASI_demographics_fields_responses SET participant_id='{{p_pid}}', field_id='{{p_fid}}', value='{{p_value}}'", list(
      p_pid=participant$id,
      p_fid=field$id,
      p_value=value
    ))
  }
}

concerto.table.query("UPDATE EASI_participants SET demographicsStatus=2 WHERE id='{{p_pid}}'", list(p_pid=participant$id))

concerto.test.run("EASI-email-demographics-completed", list(participant=participant))