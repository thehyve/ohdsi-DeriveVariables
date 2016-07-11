
########### Setup Environment ############
library(SqlRender)
library(DatabaseConnector)
# TODO: set working directory in every file
setwd("~/Documents/Study_DrugAnalysis/R/Analysis_MM")
source('getDataFunctions.R')
source('performAnalysisFunctions.R')

cdmDatabaseSchema <- 'cdm5'
# New schema that is made when executing study cohort creation
cohortDatabaseSchema <- 'study'
cohortTableName <- 'masterfile'
############# ################

connectionDetails <- createConnectionDetails(dbms="postgresql",
                                             server="localhost/ohdsi",
                                             user="postgres", password="",
                                             port=5432,
                                             schema=cdmDatabaseSchema)
connection <- connect(connectionDetails)

### Step 1. Execute SQL that Creates study cohort ###
sql <- readSql("sql/createCohort_parameterized.sql")
sql <- renderSql(sql,
                 cdm_schema = cdmDatabaseSchema,
                 target_schema = cohortDatabaseSchema,
                 target_table = cohortTableName,
                 study_start_yyyymmdd = '20111201',
                 study_end_yyyymmdd = '20141231' )$sql #Study start/end are including ends
sql <- translateSql(sql, targetDialect = connectionDetails$dbms)$sql
executeSql(connection, sql)

# Get the study cohort as a dataframe (studyPop)
studyPop <- getCohort(connectionDetails, cdmDatabaseSchema, cohortDatabaseSchema, cohortTableName)
# View(studyPop)
studySize <- nrow(studyPop)

### Table 1. Identification of patients ###
# Get the string representation of the index drug (Rivaroxaban or Warfarin + phenprocoumon)
index_drug = studyPop$RIVA_OR_VKA_STRING
# Create a contigency table with the string variables (human readable)
table(index_drug, studyPop$IS_NAIVE_STRING)

### Table 7. Patients who switched from index drug to another OAC ##
# Create contigency table
switchTable <- table(index_drug, studyPop$SWITCHTO_STRING)
View(switchTable)
# TODO: As percentage of patients with that index drug
# Total percentage that switched
sprintf("Total percent switched: %.2f%%:", sum(switchTable)/studySize*100)
