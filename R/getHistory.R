
#' Determines which persons in the cohort have a history of the given concepts.
#' Type is either 'condition', 'procedure' or 'drug'.
#' Returns a vector of 1 and 0.
#' IMPORTANT: relies on sorting on person_id for returning in the same order as dataframe.
getHistory_ <- function( type, concept_ids, connectionDetails,
                         target_schema, target_table,
                         days_interval_before_index = NULL, days_interval_after_index = NULL){
  # Default for history. 250+ years before index date up to 1 day before index date.
  if( is.null(days_interval_before_index) ){
    days_interval_before_index = '99999'
  }
  if( is.null(days_interval_after_index) ){
    days_interval_after_index = '-1' # exclude on index date
  }

  # Parse the concept codes and choose sql file
  if ( type== 'condition' ){
    concept_ids_string <- paste(concept_ids,collapse = ",")
    sql_file_name <- "history_condition_parameterized.sql"

  } else if ( type == 'procedure' ){
    concept_ids_string <- paste(concept_ids,collapse = ",")
    sql_file_name <- "history_procedure_parameterized.sql"

  } else if ( type == 'drug' ){
    atc_codes_string <- paste( concept_ids, collapse = "' OR atc.concept_code LIKE '" )
    concept_ids_string <- paste( "(atc.concept_code LIKE '",atc_codes_string,"')", sep="" )
    sql_file_name <- "history_drug_parameterized.sql"
  }

  sql <- loadRenderTranslateSql2(sql_file_name,"OHDSIDeriveVariables",
                                 dbms = connectionDetails$dbms,
                                 cdm_schema = connectionDetails$schema,
                                 target_schema = target_schema,
                                 target_table = target_table,
                                 concept_ids = concept_ids_string,
                                 days_before_index = days_interval_before_index,
                                 days_after_index = days_interval_after_index)

  connection <- connect(connectionDetails)
  result_df <- querySql(connection, sql)

  #TODO: extra check that the vector is returned in the right order?
  return( result_df$CONCEPT_HISTORY )
}

#' History, all days before index date (not including index date)
getConditionHistory <- function( concept_ids, connectionDetails, target_schema, target_table ){
  return ( getHistory_('condition', concept_ids, connectionDetails, target_schema, target_table ) )
}

getProcedureHistory <- function( concept_ids, connectionDetails, target_schema, target_table ){
  return ( getHistory_('procedure', concept_ids, connectionDetails, target_schema, target_table ) )
}

getDrugHistoryByATC <- function( atcCodes, connectionDetails, target_schema, target_table ) {
  return ( getHistory_('drug', atcCodes, connectionDetails, target_schema, target_table ) )
}

#' Custiom specified interval to get a user-defined baseline. Interval is specified in days before and after index date.
getConditionBaseline <- function( atcCodes, days_interval_before_index, days_interval_after_index, connectionDetails, target_schema, target_table ) {
  return ( getHistory_('condition', atcCodes, connectionDetails, target_schema, target_table, days_interval_before_index, days_interval_after_index ) )
}

getProcedureBaseline <- function( concept_ids, days_interval_before_index, days_interval_after_index, connectionDetails, target_schema, target_table ) {
  return ( getHistory_('procedure', concept_ids, connectionDetails, target_schema, target_table, days_interval_before_index, days_interval_after_index ) )
}

getDrugBaselineByATC <- function( concept_ids, days_interval_before_index, days_interval_after_index, connectionDetails, target_schema, target_table ) {
  return ( getHistory_('drug', concept_ids, connectionDetails, target_schema, target_table, days_interval_before_index, days_interval_after_index ) )
}



