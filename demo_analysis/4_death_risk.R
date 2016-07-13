# Load package
library(OHDSIDeriveVariables)

####### Setup environment ###########
cdmDatabaseSchema <- 'cdm5'
cohortDatabaseSchema <- 'study'
cohortTableName <- 'masterfile'

connectionDetails <- createConnectionDetails(dbms="postgresql",
                                             server="localhost/ohdsi",
                                             user="postgres", password="",
                                             port=5433,
                                             schema=cdmDatabaseSchema)

# Get the study cohort as a dataframe (studyPop)
cohort <- getCohort(connectionDetails, cdmDatabaseSchema, cohortDatabaseSchema, cohortTableName)
attach(cohort)

########### Death ###########
# Get days at risk. Patients still alive will be given the days from index to end of study.
# getDeathDaysAtRisk returns a dataframe with $days_at_risk and $is_deceased.
deaths <- getDeathDaysAtRisk(FALSE, connectionDetails, cohortDatabaseSchema, cohortTableName)
daysAtRiskAll <- deaths$DAYS_AT_RISK
is_deceased <- deaths$CENSOR

# Custom function printing the proportional hazards survival statistics.
# Annual death rate for both groups, Hazard Ratio 95% Conf. Interval and Kaplan Meijer Curve.
ph.summary <- printSurvivalStatistics( daysAtRiskAll, is_deceased, INDEX_DRUG_STRING )
print(ph.summary)

# Proportional Hazards Regression with stratification for gender and age
ageAtIndex <- getAgeAtIndex( cohort )
ph.model.adjusted <- coxph( Surv(daysAtRiskAll,is_deceased) ~ INDEX_DRUG + strata(GENDER_STRING, ageAtIndex), cohort )
summary(ph.model.adjusted)
