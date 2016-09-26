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
  result_df$INDEX_DRUG_STRING <- as.factor( result_df$INDEX_DRUG )
  levels( result_df$INDEX_DRUG_STRING ) <- list('Warfarin + Phenprocoumon'=0, 'Rivaroxaban'=1)

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
  # Replace NA by 0. Mapping functions do not work on NA
  result_df$BACKGROUND[is.na(result_df$BACKGROUND)] <- 0

  result_df$BACKGROUND_STRING <- as.factor(result_df$BACKGROUND)
  levels(result_df$BACKGROUND_STRING) <- list('Native'=43021808,'Immigrant'=0)

  return(result_df)
}
