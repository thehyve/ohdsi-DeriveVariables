
getPatientData <- function( person_id, from_date, connectionDetails ){
  #Create view with patient data from condition, procedure and drug table.
  view_name <- 'patientdata'
  createViewSql <- loadRenderTranslateSql2('createViewPatientData.sql',"OHDSIDeriveVariables",
                                            dbms = connectionDetails$dbms,
                                            cdm_schema = connectionDetails$schema,
                                            view_name = view_name)
  connection <- connect(connectionDetails)
  executeSql(connection, createViewSql)

  # Select data of this person
  sql <- "SELECT * FROM @view_name WHERE person_id = @person_id AND start_date > DATE '@from_date' ORDER BY start_date"
  sql <- renderSql(sql, view_name = view_name, person_id = person_id, from_date = from_date)$sql
  result_df <- querySql(connection, sql)

  return(result_df)
}
