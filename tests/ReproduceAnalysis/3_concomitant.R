
########### Setup Environment ############
library(SqlRender)
library(DatabaseConnector)
source('getDataFunctions.R')
source('performAnalysisFunctions.R')
# setwd("~/Google Drive/Bedrijf/Projects/Bayer OHDSI/2 Execution/R scripts/Data_Analysis")

cdmDatabaseSchema <- 'cdm5'
# New schema that is made when executing study cohort creation
cohortDatabaseSchema <- 'study'
cohortTableName <- 'masterfile'

connectionDetails <- createConnectionDetails(dbms="postgresql",
                                             server="localhost/ohdsi",
                                             user="postgres", password="",
                                             port=5432,
                                             schema=cdmDatabaseSchema)
connection <- connect(connectionDetails)

############### Get Cohort ##################
# Get the study cohort as a dataframe (studyPop)

studyPop <- getCohort(connection, cdmDatabaseSchema, cohortDatabaseSchema, cohortTableName)
# View(studyPop)
studySize <- nrow(studyPop)

################ Analysis ##############
## Diabetes Concomitant Morbidity ##
diabetes_ids <- c(195771,201254,201820,201826,4058243,44793114,4193704)
#diabetes_ids <- c(320128,4108832)
studyPop$diabetesAtIndex <- getConditionConcomitant(diabetes_ids,
                                                    connectionDetails,
                                                    cohortDatabaseSchema,
                                                    cohortTableName)

cont_table <- table(studyPop$diabetesAtIndex, studyPop$RIVA_OR_VKA_STRING)
print("Diabetes at index")
prop.table(cont_table, margin=2)
chisq.test(cont_table, correct = FALSE)

## Pacemaker Concomitant Morbidity ##
pacemaker_ids <- c(4018842,4035447,4048988,4049399,4050574,4051939,4085558,4099402,4125933,4140992,4142917,4144921,4179363,4183537,4199841,4203562,4204395,4216345,4242529,4243335,4244395,4246210,4281670,4286047,4296792,4331222,4332099,40481942,40487117,42709991,44782661,44783080,44783089,44790298,44790432,44790501,44811732)
studyPop$pacemakerImplanted <- getProcedureHistory(pacemaker_ids,
                                                   connectionDetails,
                                                   cohortDatabaseSchema,
                                                   cohortTableName)

cont_table_pm <-  table(studyPop$pacemakerImplanted, studyPop$RIVA_OR_VKA_STRING)
print("Pacemaker Implanted before index")
prop.table(cont_table_pm, margin=2)
chisq.test(cont_table_pm, correct = FALSE)

