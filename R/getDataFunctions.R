# Simple wrapper for easy formatted printing to screen. outer invisible may be unnecessary (http://stackoverflow.com/questions/13023274/how-to-do-printf-in-r)
printf <- function(...) invisible(print(sprintf(...)))

loadRenderTranslateSql2 <- function(sqlFilename, packageName, dbms = "sql server", ...,
                                   oracleTempSchema = NULL) {

  pathToSql <- system.file(paste("sql/", gsub(" ", "_", dbms),
                                 sep = ""), sqlFilename, package = packageName)
  mustTranslate <- !file.exists(pathToSql)
  if (mustTranslate) {
    pathToSql <- system.file(paste("sql/", "sql_server",
                                   sep = ""), sqlFilename, package = packageName)
  }
  parameterizedSql <- readChar(pathToSql, file.info(pathToSql)$size)
  renderedSql <- renderSql(parameterizedSql[1], ...)$sql
  if (mustTranslate)
    renderedSql <- translateSql(renderedSql, "sql server",
                                dbms, oracleTempSchema)$sql
  renderedSql
}

createCohort <- function(connection, connectionDetails, cdm_schema, target_schema, target_table){

  sql <- loadRenderTranslateSql2("createCohort_parameterized.sql","OHDSIDeriveVariables",
                                cdm_schema = cdm_schema,
                                dbms = connectionDetails$dbms,
                                target_schema = target_schema,
                                target_table = target_table,
                                study_start_yyyymmdd = '20111201',
                                study_end_yyyymmdd = '20141231')

  executeSql(connection, sql)
}

#'
getCohort <- function(connectionDetails, cdm_schema, target_schema, target_table){
    # pathToSql <- system.file(paste("sql/", gsub(" ", "_", connectionDetails$dbms),
    #                                sep = ""), "getCohort_parameterized.sql", package = "DrugAnalysis")
    # print(pathToSql)
    # mustTranslate <- !file.exists(pathToSql)
    # print(mustTranslate)
    # print(file.info(pathToSql))
    # print(list.files())
    # sql <- readSql("inst/sql/sql_server/getCohort_parameterized.sql")
    # print(sql)

    ## Get dataframe with the study cohort
    sql <- loadRenderTranslateSql2("getCohort_parameterized.sql","OHDSIDeriveVariables",
                     cdm_schema = connectionDetails$schema,
                     dbms = connectionDetails$dbms,
                     target_schema = target_schema,
                     target_table = target_table)

    connection <- connect(connectionDetails)
    result_df <- querySql(connection, sql)

    ## Translations from index to names
    # Riva or VKA to human readable classifications.
    result_df$RIVA_OR_VKA_STRING <- as.factor( result_df$RIVA_OR_VKA )
    levels( result_df$RIVA_OR_VKA_STRING ) <- list('Warfarin + Phenprocoumon'=0, 'Rivaroxaban'=1)

    # Naive/non-naive
    result_df$IS_NAIVE_STRING <- as.factor(result_df$IS_NAIVE)
    levels(result_df$IS_NAIVE_STRING) <- list('Non-naive'=0,'OAC Naive'=1)

    # TODO: translate by join to concept table (concept_name)
    # Switchto #todo: expande with other ids that can be used for these.
    result_df$SWITCHTO_STRING <- as.factor(result_df$SWITCHTO)
    levels( result_df$SWITCHTO_STRING ) <- list("Warfarin"=1310149,"Phenprocoumon"=19035344,"Dabigatran"=40228152,
                                              "Rivaroxaban"=40241331,"Apixaban"=43013024)
    # Gender
    result_df$GENDER_STRING <- as.factor(result_df$GENDER_CONCEPT_ID)
    levels(result_df$GENDER_STRING) <- list('Male'=8507,'Female'=8532,'Unknown'=8551)

    # Background
    result_df$BACKGROUND_STRING <- as.factor(result_df$BACKGROUND)
    levels(result_df$BACKGROUND_STRING) <- list('Native'=43021808,'Immigrant'=NA)

    return(result_df)
}

getAgeAtIndex <- function( studyPop ){
  # Calculate age at index from index date and year of birth.
  # This approximation can be a year less than the real age, because month and day fo birth ar missing.
  indexYear <- as.numeric( format(studyPop$INDEX_DATE, "%Y") )
  return( indexYear - as.numeric( studyPop$YEAR_OF_BIRTH ) )
}

getHistory_ <- function( type, concept_ids, connectionDetails,
                         target_schema, target_table ){
  ###
  # Determines which persons in the cohort have a history of the given concepts.
  # Type is either 'condition', 'procedure' or 'drug'.
  # Returns a vector of 1 and 0.
  # IMPORTANT: relies on sorting on person_id for returning in the same order as dataframe.
  ###

  # Parse the concept codes and choose sql file
  if ( type== 'condition' ){
    concept_ids_string <- paste(concept_ids,collapse = ",")
    sql <- readSql("sql/history_condition_parameterized.sql")

  } else if ( type == 'procedure' ){
    concept_ids_string <- paste(concept_ids,collapse = ",")
    sql <- readSql("sql/history_procedure_parameterized.sql")

  } else if ( type == 'drug' ){
    atc_codes_string <- paste( concept_ids, collapse = "' OR atc.concept_code LIKE '" )
    concept_ids_string <- paste( "(atc.concept_code LIKE '",atc_codes_string,"')", sep="" )
    sql <- readSql("sql/history_drug_parameterized.sql")
  }

  sql <- renderSql(sql,
                   cdm_schema = connectionDetails$schema,
                   target_schema = target_schema,
                   target_table = target_table,
                   concept_ids = concept_ids_string)$sql
  sql <- translateSql(sql, targetDialect = connectionDetails$dbms)$sql

  connection <- connect(connectionDetails)
  result_df <- querySql(connection, sql)

  #TODO: extra check that the vector is returned in the right order?
  return( result_df$CONCEPT_HISTORY )
}

getPriorConditionBool <- function( concept_ids, connectionDetails, target_schema, target_table ){
  return ( getHistory_('condition', concept_ids, connectionDetails, target_schema, target_table ) )
}

getProcedureHistory <- function( concept_ids, connectionDetails, target_schema, target_table ){
  return ( getHistory_('procedure', concept_ids, connectionDetails, target_schema, target_table ) )
}

getPriorDrugBool_byATC <- function( atcCodes, connectionDetails, target_schema, target_table ) {
  return ( getHistory_('drug', atcCodes, connectionDetails, target_schema, target_table ) )
}

getAtIndexDrugBool_byATC <- function(atcCodes, connectionDetails, cohortDatabaseSchema, cohortTableName, useIn = FALSE) {
  # Only set useIn to true if this gives a performance boost.
  # Parse the atc codes
  if (useIn){
    atc_codes_string <- paste(atcCodes,collapse = "','")
    atc_codes_string <- paste("atc.concept_code IN ('",atc_codes_string,"')", sep="")
  } else {
    atc_codes_string <- paste( atcCodes, collapse = "' OR atc.concept_code LIKE '" )
    atc_codes_string <- paste( "(atc.concept_code LIKE '",atc_codes_string,"')", sep="" )
  }

  sql <- readSql("sql/new_drug_parameterized.sql")
  sql <- renderSql(sql,
                   cdm_schema = connectionDetails$schema,
                   target_schema = cohortDatabaseSchema,
                   target_table = cohortTableName,
                   where_clause = atc_codes_string)$sql
  sql <- translateSql(sql, targetDialect = connectionDetails$dbms)$sql

  connection <- connect(connectionDetails)
  result_df <- querySql(connection, sql)

  #TODO: extra check that the vector is returned in the right order?
  return( result_df$DRUG_NEW )
}

getDaysAtRisk_ <- function(type, concept_ids, connectionDetails, target_schema, target_table,
                           days_correction = 30, study_end_yyyymmdd = '20141231') {

  if (type == 'death') {
     # Either main cause or a secondary cause of death.
     cause_ids_string <- paste(concept_ids, collapse = ",")
     where_string <- paste("(cause_concept_id IN (",cause_ids_string,
                               ") OR value_as_concept_id IN (",cause_ids_string,") )", sep="")
     sql <- readSql("sql/days_at_risk_death_parameterized.sql")

  } else if (type == 'condition') {
    concept_ids_string <- paste(concept_ids, collapse = ",")
    # Concept id in given ids AND
    # Not a Secondary condition (Primary and first place condition are allowed)
    where_string <- paste("condition_concept_id IN (", concept_ids_string,
                         ") AND condition_type_concept_id != 44786629", sep="")
    sql <- readSql("sql/days_at_risk_condition_parameterized.sql")

  } else {
    printf("%s days at risk is not supported", type)
    exit(1)
  }

  # If no vector is given (e.g. boolean), then all conepts are allowed.
  # This overwrites any where_string created
  if ( concept_ids[1] == FALSE ){
    where_string <- "True"
  }


  sql <- renderSql(sql,
                   cdm_schema = connectionDetails$schema,
                   target_schema = target_schema,
                   target_table = target_table,
                   where_clause = where_string,
                   days_correction = days_correction,
                   study_end_date = study_end_yyyymmdd)$sql
  sql <- translateSql(sql, targetDialect = connectionDetails$dbms)$sq
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

getConditionConcomitant <- function(condition_ids, connectionDetails, target_schema, target_table ){
    ## Boolean conditions 'at index': occurrence both before and after index
    ## Implementation using exiting functions instead of new sql

    # Get all histories of this condition
    occurrenceBeforeIndex <- getPriorConditionBool(condition_ids, connectionDetails, target_schema, target_table)

    # Get all after index of this condition
    conditionRisk <- getConditionDaysAtRisk(condition_ids, connectionDetails, target_schema, target_table,
                                            days_correction = 0)
    occurrenceAfterIndex <- conditionRisk$CENSOR

    # If a True if condition occurred both before and after index.
    result <- occurrenceBeforeIndex * occurrenceAfterIndex

    printf( "Total Number of patients with occurrences before index: %d", sum(occurrenceBeforeIndex) )
    printf( "Total Number of patients with occurrences after index: %d", sum(occurrenceAfterIndex) )
    printf( "Total Number of patients with occurrences before and after index: %d", sum(result) )

    return(result)
}
