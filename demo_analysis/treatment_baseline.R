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

########### Treatment baseline ###########
# Up to 152 days before index date
days_before <- 152
# Up to 30 days after index date
days_after <- 30

ace_ids <- c("C09AA%","C09B%")
ace_baseline <- getDrugBaselineByATC( ace_ids, days_before, days_after, connectionDetails, cohortDatabaseSchema, cohortTableName )

ace_contigency <-  table(ace_history, INDEX_DRUG_STRING)
print("ACE-inhibitor")
prop.table(ace_contigency, margin = 2)
chisq.test(ace_contigency, correct = FALSE)

