# Export the drug mapping

# Load package
library(OHDSIDeriveVariables)

####### Setup environment ###########
cdmDatabaseSchema <- 'cdm5'
connectionDetails <- createConnectionDetails(dbms="postgresql",
                                             server="localhost/ohdsi",
                                             user="postgres", password="",
                                             port=5433,
                                             schema=cdmDatabaseSchema)

# write in the current working directory.
file <- file.path(getwd(),'drug_mapping.csv' )
exportDrugMapping(connectionDetails, file)
