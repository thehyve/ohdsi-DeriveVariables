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
# New schema that is made when executing createCohort
cohortDatabaseSchema <- 'study'
cohortTableName <- 'masterfile'

############# Create Cohort ################
connectionDetails <- createConnectionDetails(dbms="postgresql",
                                             server="localhost/ohdsi",
                                             user="postgres", password="",
                                             port=5433,
                                             schema=cdmDatabaseSchema)
connection <- connect(connectionDetails)

# createCohort() will create a cohort from the following rules:
# - All patients with rivaroxaban (riva), warfarin or phenprocoumon (vka) between december 1, 2011 and december 31, 2014.
# - Excluding the patients who had their first AF after index
# - Excluding all the patients with index drug both riva and vka
# - Excluding all patients younger than 18 years at index date.
# - Excluding non-naive patients (can be ignored by setting onlyNaive to FALSE)
onlyNaive = TRUE
createCohort(connection, connectionDetails, cdmDatabaseSchema,
             cohortDatabaseSchema, cohortTableName,
             onlyNaive)

# View the resulting cohort
cohort <- getCohort(connectionDetails, cdmDatabaseSchema, cohortDatabaseSchema, cohortTableName)
# The following column names are present:
names(cohort)
# Show the cohort table
View(cohort)
# Number of rows:
nrow(cohort)
