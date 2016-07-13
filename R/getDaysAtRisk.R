
#'
getDaysAtRisk_ <- function(type, concept_ids, connectionDetails, target_schema, target_table,
                           days_correction = 30, study_end_yyyymmdd = '20141231') {

  if (type == 'death') {
    # Either main cause or a secondary cause of death.
    cause_ids_string <- paste(concept_ids, collapse = ",")
    where_string <- paste("(cause_concept_id IN (",cause_ids_string,
                          ") OR value_as_concept_id IN (",cause_ids_string,") )", sep="")
    sql_file_name <- "days_at_risk_death_parameterized.sql"

  } else if (type == 'condition') {
    concept_ids_string <- paste(concept_ids, collapse = ",")
    # Concept id in given ids AND
    # Not a Secondary condition (Primary and first place condition are allowed)
    where_string <- paste("condition_concept_id IN (", concept_ids_string,
                          ") AND condition_type_concept_id != 44786629", sep="")
    sql_file_name <- "days_at_risk_condition_parameterized.sql"

  } else {
    printf("%s days at risk is not supported", type)
    exit(1)
  }

  # If no vector is given (e.g. boolean), then all conepts are allowed.
  # This overwrites any where_string created
  if ( concept_ids[1] == FALSE ){
    where_string <- "True"
  }

  sql <- loadRenderTranslateSql2(sql_file_name,"OHDSIDeriveVariables",
                                 dbms = connectionDetails$dbms,
                                 cdm_schema = connectionDetails$schema,
                                 target_schema = target_schema,
                                 target_table = target_table,
                                 where_clause = where_string,
                                 days_correction = days_correction,
                                 study_end_date = study_end_yyyymmdd)

  connection <- connect(connectionDetails)

  result_df <- querySql(connection, sql)
  return( result_df )
}

getDeathDaysAtRisk <- function(cause_ids, connectionDetails, target_schema, target_table,
                               days_correction = 30, study_end_yyyymmdd = '20141231') {
  return( getDaysAtRisk_('death', cause_ids, connectionDetails, target_schema, target_table,
                         days_correction, study_end_yyyymmdd) )
}

getConditionDaysAtRisk <- function(condition_ids, connectionDetails, target_schema, target_table,
                                   days_correction = 30, study_end_yyyymmdd = '20141231') {
  return( getDaysAtRisk_('condition', condition_ids, connectionDetails, target_schema, target_table,
                         days_correction, study_end_yyyymmdd) )
}
