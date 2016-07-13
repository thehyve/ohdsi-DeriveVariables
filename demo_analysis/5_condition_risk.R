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

######## Analysis ##########
## Acute stroke risk analysis
concepts_acute_stroke <- c(443454,4031045,4043731,4043732,4045735,4045737,4045738,4045740,4045741,4046090,4046237,4046358,4046359,4046360,4046361,4046362,4048784,4077086,4108356,4110189,4110190,4110192,4111714,4119140,4129534,4131383,4138327,4141405,4142739,4145897,4146185,4319146,40479572,43530683,43531607,44782773,45767658,45772786,46270031,46270380,46270381,46273649)
risk_censor <- getConditionDaysAtRisk(concepts_acute_stroke, connectionDetails, cohortDatabaseSchema, cohortTableName)

daysAtRiskStroke <- risk_censor$DAYS_AT_RISK
censor <- risk_censor$CENSOR

# Custom function printing the survival statistics.
# Annual death rate for both groups, Hazard Ratio 95% Conf. Interval and Kaplan Meijer Curve.
ph.summary <- printSurvivalStatistics( daysAtRiskStroke, censor, INDEX_DRUG_STRING )

## Atrial fibrillation stroke risk analysis
concepts_acute_af <- c(4108832)
risk_censor <- getConditionDaysAtRisk(concepts_acute_af, connectionDetails, cohortDatabaseSchema, cohortTableName)

daysAtRiskAF <- risk_censor$DAYS_AT_RISK
censor <- risk_censor$CENSOR

ph.summary <- printSurvivalStatistics( daysAtRiskAF, censor, INDEX_DRUG_STRING )
