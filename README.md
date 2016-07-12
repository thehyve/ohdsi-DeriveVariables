# ohdsi-DeriveVariables
R package for deriving variables from the OMOP Common Data Model.

## Usage:
- Install dependencies
```
install.packages("devtools")
library("devtools")
install_github("ohdsi/OhdsiRTools")
install_github("ohdsi/SqlRender")
install_github("ohdsi/DatabaseConnector")
```
- Install and load this package
```
install_github("thehyve/ohdsi-DeriveVariables")
library("OHDSIDeriveVariables")
```
- Create and get cohort with:
```
connectionDetails <- createConnectionDetails(dbms="postgresql",
                                             server="localhost/ohdsi",
                                             user="postgres", password="",
                                             port=5432,
                                             schema="cdm5")
connection <- connect(connectionDetails)

createCohort(connection, connectionDetails, "cdm5", "study", "cohort")
cohort <- getCohort(connectionDetails, "cdm5", "study", "cohort")
```
