# Simple wrapper for easy formatted printing to screen. outer invisible may be unnecessary (http://stackoverflow.com/questions/13023274/how-to-do-printf-in-r)
printf <- function(...) invisible(print(sprintf(...)))

createCohort <- function(connection, connectionDetails, cdm_schema, target_schema, target_table){

  # Input the ids
  riva_ids <- c(40244445,40241331,40241332,40241333,40244446,40244447,40244443,40241334,40244448,40241335,40244444,40244449,40241337,40241336,40244450)
  warf_ids <- c(44663115,44556166,44562589,44621649,44643120,40163553,44557985,40163549,44547357,44581120,44611173,40163535,44604212,44605858,44645771,44678256,40163537,40163528,44580621,44579352,40163560,44560351,40163539,44549319,44561018,44611705,44578601,40163519,44611547,44587179,44663782,44674155,44618390,44607893,44644567,40163550,44549318,44655361,44679336,40163534,44674600,44586763,44662517,40163511,44653078,44599599,44643067,44632766,40163554,44632290,40163564,40163514,44610278,40093134,40163567,44642416,44627226,40163507,40093131,40163558,44552268,40163518,44559160,44670738,40121983,40163527,44571574,40163559,40163536,40121984,44604248,44647604,44667136,44616988,40163523,44645391,40163525,40163515,40163520,40163517,40163557,44604598,44556575,44631436,44644475,44657905,44630908,40163569,44667448,40163551,44635583,44622848,44622849,40163533,40163555,44547738,40163547,40163566,40163516,44626965,40163532,40163568,40163548,44667174,44612008,44579230,40163565,40093132,44617776,44631830,44601988,44647884,44662478,44603265,40163570,40163552,44574108,40163541,40163513,44545243,44551746,40163561,44563518,40163530,40093130,44560746,44622752,40163543,44605424,44614948,44650425,44570203,44617269,40163529,44583471,44676840,40163509,44605024,44622055,44611706,1310149,40163531,44665175,44665051,40163526,40163512,40163563,40163562,44677342,40163524,40163556,44556574,40163522,40163542,44674154,40163546,44672367,44595885,40163538,44607132,44578361,44643066,40163510,40163508,44658031,44589399,44611597,44562846,44548797,44602298,40163521,40163540,40093133,44616175,44546930,40163544,44563271,44548604,44587502,44550692,44656985,44569040,40163545,44637417,44625675,44626589)
  phen_ids <- c(19035344,40078200,19079272,19081825)
  dabi_ids <- c(40228152)
  apix_ids <- c(43013024)

  sql <- loadRenderTranslateSql2("createCohort_parameterized.sql","OHDSIDeriveVariables",
                                cdm_schema = cdm_schema,
                                dbms = connectionDetails$dbms,
                                target_schema = target_schema,
                                target_table = target_table,
                                study_start_yyyymmdd = '20111201',
                                study_end_yyyymmdd = '20141231',
                                riva_ids = paste(riva_ids,collapse=","),
                                warf_ids = paste(warf_ids,collapse=","),
                                phen_ids = paste(phen_ids,collapse=","),
                                dabi_ids = paste(dabi_ids,collapse=","),
                                apix_ids = paste(apix_ids,collapse=",")
                                )

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
                                 concept_ids = concept_ids_string)

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

getConditionConcomitant <- function(condition_ids, connectionDetails, target_schema, target_table ){
    ## Boolean conditions 'at index': occurrence both before and after index
    ## Implementation using exiting functions instead of new sql

    # Get all histories of this condition
    occurrenceBeforeIndex <- getPriorConditionBool(condition_ids, connectionDetails, target_schema, target_table)

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
