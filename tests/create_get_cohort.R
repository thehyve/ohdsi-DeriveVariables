install.packages("devtools")
library("devtools")
install_github("ohdsi/OhdsiRTools")
install_github("ohdsi/SqlRender")
install_github("ohdsi/DatabaseConnector")
install_github("thehyve/ohdsi-DeriveVariables")

# If all was succesfull, the following should load the package
library("SqlRender")
library("OHDSIDeriveVariables")

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
createCohort(connection, connectionDetails, cdmDatabaseSchema, cohortDatabaseSchema, cohortTableName)

cohort <- getCohort(connection, connectionDetails, cdmDatabaseSchema, cohortDatabaseSchema, cohortTableName)
View(cohort)
