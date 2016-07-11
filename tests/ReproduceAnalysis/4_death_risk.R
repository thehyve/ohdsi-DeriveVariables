
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

# Get the study cohort as a dataframe (studyPop)
studyPop <- getCohort(connection, cdmDatabaseSchema, cohortDatabaseSchema, cohortTableName)
# View(studyPop)
studySize <- nrow(studyPop)

########### Death ###########
# Get days at risk. Patients still alive will be given the days from index to end of study.
# getDeathDaysAtRisk returns a dataframe with $days_at_risk and $is_deceased.
deaths <- getDeathDaysAtRisk(FALSE, connectionDetails, cohortDatabaseSchema, cohortTableName)
studyPop$daysAtRiskAll <- deaths$DAYS_AT_RISK
studyPop$is_deceased <- deaths$CENSOR

ph.summary <- printSurvivalStatistics(studyPop$daysAtRiskAll, studyPop$is_deceased, studyPop$RIVA_OR_VKA_STRING)

# Proportional Hazards Regression with stratification for gender and age
studyPop$ageAtIndex <- getAgeAtIndex( studyPop )
ph.model.adjusted <- coxph(Surv(daysAtRiskAll,is_deceased) ~ RIVA_OR_VKA + strata(GENDER_STRING, ageAtIndex), studyPop)
summary(ph.model.adjusted)
