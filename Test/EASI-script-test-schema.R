tableCheck = function(name) {
  concerto.table.query("CREATE TABLE IF NOT EXISTS {{table}} (
id BIGINT AUTO_INCREMENT PRIMARY KEY
)", list(table=name))

  tables = concerto.table.query("SELECT * FROM DataTable WHERE name='{{name}}'", list(name=name))
  if(nrow(tables) == 0) {
    concerto.table.query("INSERT INTO DataTable SET name='{{name}}', description='', updated=NOW(), updatedBy='-', created=NOW(), accessibility=2, groups='', archived=0, starterContent=0, tags=''", list(name=name))
  }
}

colsCheck = function(table, cols) {
  fields = concerto.table.query("SHOW FIELDS IN {{table}}", list(table=table))
  for(col in cols) {
    name = col$Field
    type = col$Type
    null = if(col$Null == "NO") { "NOT NULL" } else { "NULL" }
    field = fields[fields$Field == name,]

    newDefault = col$Default
    if(is.na(newDefault)) { 
      newDefault = "" 
    } else {
      newDefault = paste0("DEFAULT ", newDefault)
    }

    if(nrow(field) == 0) {
      sql = "ALTER TABLE {{table}} ADD COLUMN {{name}} {{type}} {{null}}"
      sql = paste0(sql, " ", newDefault)
      concerto.table.query(sql, list(table=table, name=name, type=type, null=null))
    } else {
      curDefault = field$Default
      if(is.na(curDefault)) { 
        curDefault = "" 
      } else {
        curDefault = paste0("DEFAULT ", curDefault)
      }

      if(type != field$Type || col$Null != field$Null || curDefault != newDefault) {
        sql = "ALTER TABLE {{table}} MODIFY COLUMN {{name}} {{type}} {{null}}"
        sql = paste0(sql, " ", newDefault)
        concerto.table.query(sql, list(table=table, name=name, type=type, null=null))
      }
    }
  }
}

foreignIndexCheck = function(table, idxs) {
  indices = concerto.table.query("
SELECT rc.CONSTRAINT_NAME, rc.TABLE_NAME, COLUMN_NAME, rc.REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME, UPDATE_RULE, DELETE_RULE
FROM information_schema.REFERENTIAL_CONSTRAINTS AS rc
LEFT JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS kcu ON kcu.CONSTRAINT_NAME=rc.CONSTRAINT_NAME
WHERE rc.TABLE_NAME='{{table}}'", list(table=table))

  for(idx in idxs) {
    index = indices[tolower(indices$TABLE_NAME) == tolower(table) & tolower(indices$COLUMN_NAME) == tolower(idx$column),]
    if(nrow(index) == 0) {
      concerto.table.query("
ALTER TABLE {{table}} 
ADD CONSTRAINT FK_{{table}}_{{column}}
FOREIGN KEY ({{column}}) REFERENCES {{refTable}}({{refColumn}}) ON UPDATE {{update}} ON DELETE {{delete}}
", list(table=table, column=idx$column, refTable=idx$refTable, refColumn=idx$refColumn, update=idx$update, delete=idx$delete))
    } else {
      if(tolower(index$REFERENCED_TABLE_NAME) != tolower(idx$refTable) || tolower(index$REFERENCED_COLUMN_NAME) != tolower(idx$refColumn) || tolower(index$UPDATE_RULE) != tolower(idx$update) || tolower(index$DELETE_RULE) != tolower(idx$delete)) {
        concerto.table.query("ALTER TABLE {{table}} DROP FOREIGN KEY {{keyName}}", list(table=table, keyName=index$CONSTRAINT_NAME))
        concerto.table.query("
ALTER TABLE {{table}} 
ADD CONSTRAINT FK_{{table}}_{{column}}
FOREIGN KEY ({{column}}) REFERENCES {{refTable}}({{refColumn}}) ON UPDATE {{update}} ON DELETE {{delete}}
", list(table=table, column=idx$column, refTable=idx$refTable, refColumn=idx$refColumn, update=idx$update, delete=idx$delete))
      }
    }
  }
}

indexCheck = function(table, column) {
  indices = concerto.table.query("SHOW INDEX IN {{table}} WHERE Column_name='{{column}}'", list(
    table=table,
    column=column
  ))

  if(nrow(indices) == 0) {
    concerto.table.query("ALTER TABLE {{table}} ADD INDEX {{column}} ({{column}})", list(
      table=table,
      column=column
    ))
  }
}

#items
table = paste0(test$code, "_items")
tableCheck(table)
cols = list(
  list(Field="enabled", Type="tinyint(1)", Null="NO", Default=0),
  list(Field="type", Type="varchar(16)", Null="NO", Default="''"),
  list(Field="scoreMapType", Type="varchar(16)", Null="YES", Default=NA),
  list(Field="trait", Type="varchar(64)", Null="YES", Default=NA),
  list(Field="stem", Type="longtext", Null="YES", Default=NA),
  list(Field="question", Type="longtext", Null="NO", Default=NA),
  list(Field="p1", Type="double", Null="YES", Default=NA),
  list(Field="p2", Type="double", Null="YES", Default=NA),
  list(Field="p3", Type="double", Null="YES", Default=NA),
  list(Field="p4", Type="double", Null="YES", Default=NA),
  list(Field="optionLabel1", Type="varchar(128)", Null="YES", Default=NA),
  list(Field="optionValue1", Type="varchar(128)", Null="YES", Default=NA),
  list(Field="optionScore1", Type="double", Null="YES", Default=NA),
  list(Field="optionLabel2", Type="varchar(128)", Null="YES", Default=NA),
  list(Field="optionValue2", Type="varchar(128)", Null="YES", Default=NA),
  list(Field="optionScore2", Type="double", Null="YES", Default=NA),
  list(Field="optionLabel3", Type="varchar(128)", Null="YES", Default=NA),
  list(Field="optionValue3", Type="varchar(128)", Null="YES", Default=NA),
  list(Field="optionScore3", Type="double", Null="YES", Default=NA),
  list(Field="optionLabel4", Type="varchar(128)", Null="YES", Default=NA),
  list(Field="optionValue4", Type="varchar(128)", Null="YES", Default=NA),
  list(Field="optionScore4", Type="double", Null="YES", Default=NA),
  list(Field="optionLabel5", Type="varchar(128)", Null="YES", Default=NA),
  list(Field="optionValue5", Type="varchar(128)", Null="YES", Default=NA),
  list(Field="optionScore5", Type="double", Null="YES", Default=NA),
  list(Field="extraSettings", Type="json", Null="YES", Default=NA),
  list(Field="required", Type="tinyint(1)", Null="NO", Default=1),
  list(Field="excludeFromScoring", Type="tinyint(1)", Null="NO", Default=0),
  list(Field="auditLabel", Type="varchar(256)", Null="YES", Default=NA),
  list(Field="skippable", Type="tinyint(1)", Null="NO", Default=0)
)
colsCheck(table, cols)

#responses
table = paste0(test$code, "_responses")
tableCheck(table)
cols = list(
  list(Field="session_id", Type="bigint(20)", Null="NO", Default=0),
  list(Field="item_id", Type="bigint(20)", Null="NO", Default=0),
  list(Field="value", Type="varchar(1024)", Null="YES", Default=NA),
  list(Field="score", Type="double", Null="YES", Default=NA),
  list(Field="timeTaken", Type="double", Null="NO", Default=0),
  list(Field="trait", Type="varchar(64)", Null="YES", Default=NA),
  list(Field="timeCreated", Type="datetime", Null="NO", Default="CURRENT_TIMESTAMP"),
  list(Field="submitted", Type="tinyint(1)", Null="NO", Default=0),
  list(Field="skipped", Type="tinyint(1)", Null="NO", Default=0)
)
colsCheck(table, cols)
indexCheck(table, "item_id")

#scores
table = paste0(test$code, "_scores")
tableCheck(table)
cols = list(
  list(Field="session_id", Type="bigint(20)", Null="NO", Default=0),
  list(Field="name", Type="varchar(128)", Null="NO", Default="''"),
  list(Field="value", Type="double", Null="YES", Default=NA),
  list(Field="timeCreated", Type="datetime", Null="NO", Default="CURRENT_TIMESTAMP"),
  list(Field="participant_id", Type="bigint(20)", Null="NO", Default=NA)
)
colsCheck(table, cols)

#scores feedback
table = paste0(test$code, "_feedback")
tableCheck(table)
cols = list(
  list(Field="namePattern", Type="varchar(256)", Null="NO", Default="''"),
  list(Field="minRange", Type="double", Null="YES", Default=NA),
  list(Field="maxRange", Type="double", Null="YES", Default=NA),
  list(Field="minParticipantMonths", Type="smallint(6)", Null="YES", Default=NA),
  list(Field="maxParticipantMonths", Type="smallint(6)", Null="YES", Default=NA),
  list(Field="feedback", Type="text", Null="NO", Default=NA)
)
colsCheck(table, cols)

#sessions
table = paste0(test$code, "_sessions")
tableCheck(table)
cols = list(
  list(Field="participant_id", Type="bigint(20)", Null="NO", Default=0),
  list(Field="participantMonths", Type="int(11)", Null="YES", Default=NA),
  list(Field="timeCreated", Type="datetime", Null="NO", Default="CURRENT_TIMESTAMP"),
  list(Field="timeStarted", Type="datetime", Null="YES", Default=NA),
  list(Field="timeFinished", Type="datetime", Null="YES", Default=NA),
  list(Field="dateAssessment", Type="date", Null="YES", Default=NA),
  list(Field="statusDescription", Type="varchar(64)", Null="YES", Default=NA),
  list(Field="status", Type="smallint(6)", Null="NO", Default=0),
  list(Field="token", Type="varchar(128)", Null="NO", Default="''"),
  list(Field="admin_id", Type="bigint(20)", Null="YES", Default=NA)
)
colsCheck(table, cols)

#settings
table = paste0(test$code, "_settings")
tableCheck(table)
cols = list(
  list(Field="minParticipantMonths", Type="smallint(6)", Null="YES", Default=NA),
  list(Field="maxParticipantMonths", Type="smallint(6)", Null="YES", Default=NA),
  list(Field="name", Type="varchar(256)", Null="NO", Default="''"),
  list(Field="value", Type="longtext", Null="YES", Default=NA)
)
colsCheck(table, cols)

#responses indices
table = paste0(test$code, "_responses")
idxs = list(
  list(column="session_id", refTable=paste0(test$code, "_sessions"), refColumn="id", update="RESTRICT", delete="CASCADE")
)
foreignIndexCheck(table, idxs)

#scores indices
table = paste0(test$code, "_scores")
idxs = list(
  list(column="session_id", refTable=paste0(test$code, "_sessions"), refColumn="id", update="RESTRICT", delete="CASCADE"),
  list(column="participant_id", refTable="EASI_participants", refColumn="id", update="RESTRICT", delete="CASCADE")
)
foreignIndexCheck(table, idxs)

#sessions indices
table = paste0(test$code, "_sessions")
idxs = list(
  list(column="participant_id", refTable="EASI_participants", refColumn="id", update="RESTRICT", delete="CASCADE"),
  list(column="admin_id", refTable="EASI_admins", refColumn="id", update="RESTRICT", delete="SET NULL")
)
foreignIndexCheck(table, idxs)