#' Calculates age at index from index date and year of birth.
#' This approximation can be a year less than the real age, because month and day fo birth ar missing.
getAgeAtIndex <- function( studyPop ){
  indexYear <- as.numeric( format(studyPop$INDEX_DATE, "%Y") )
  return( indexYear - as.numeric( studyPop$YEAR_OF_BIRTH ) )
}

#' Retrieve drug at index. Drug is used at index if it is used 30 days after index,
#' but not in the year before.
#' Only set useIn to true if this gives a performance boost.
getDrugAtIndexByATC <- function(atcCodes, connectionDetails, cohortDatabaseSchema, cohortTableName, useIn = FALSE) {
  # Parse the atc codes
  if (useIn){
    atc_codes_string <- paste(atcCodes,collapse = "','")
    atc_codes_string <- paste("atc.concept_code IN ('",atc_codes_string,"')", sep="")
  } else {
    atc_codes_string <- paste( atcCodes, collapse = "' OR atc.concept_code LIKE '" )
    atc_codes_string <- paste( "(atc.concept_code LIKE '",atc_codes_string,"')", sep="" )
  }

  sql <- loadRenderTranslateSql2("new_drug_parameterized.sql","OHDSIDeriveVariables",
                                 dbms = connectionDetails$dbms,
                                 cdm_schema = connectionDetails$schema,
                                 target_schema = cohortDatabaseSchema,
                                 target_table = cohortTableName,
                                 where_clause = atc_codes_string)

  connection <- connect(connectionDetails)
  result_df <- querySql(connection, sql)

  #TODO: extra check that the vector is returned in the right order?
  return( result_df$DRUG_NEW )
}

getConditionConcomitant <- function(condition_ids, connectionDetails, target_schema, target_table ){
    ## Boolean conditions 'at index': occurrence both before and after index
    ## Implementation using exiting functions instead of new sql

    # Get all histories of this condition
    occurrenceBeforeIndex <- getConditionHistory(condition_ids, connectionDetails, target_schema, target_table)

    # Get all after index of this condition
    conditionRisk <- getConditionDaysAtRisk(condition_ids, connectionDetails, target_schema, target_table,
                                            days_correction = 0)
    occurrenceAfterIndex <- conditionRisk$CENSOR

    # True if condition occurred both before and after index.
    result <- occurrenceBeforeIndex * occurrenceAfterIndex

    printf( "Total Number of patients with occurrences before index: %d", sum(occurrenceBeforeIndex) )
    printf( "Total Number of patients with occurrences after index: %d", sum(occurrenceAfterIndex) )
    printf( "Total Number of patients with occurrences before and after index: %d", sum(result) )

    return(result)
}
