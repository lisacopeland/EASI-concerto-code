tests = concerto.table.query("SELECT * FROM EASI_tests")
for(i in 1:nrow(tests)) {
  test = tests[i,]
  concerto.test.run("EASI-script-test-schema", list(test=test))
}
