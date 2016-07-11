

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

studyPop <- getCohort(connectionDetails, cdmDatabaseSchema, cohortDatabaseSchema, cohortTableName)
# View(studyPop)
studySize <- nrow(studyPop)

############ Start Analyses ##################

### Table 8. Demography and group testing ###
# Calculate age at index date.
studyPop$ageAtIndex <- getAgeAtIndex( studyPop )

# Create two groups, riva and vka. On index, not on string name
rivaPop <- studyPop[ studyPop$RIVA_OR_VKA == 1, ]
vkaPop  <- studyPop[ studyPop$RIVA_OR_VKA == 0, ]

## Age ##
# Print descriptive metrics (datalength, mean, sd, median, IQR)
printContinuousDescriptives(rivaPop$ageAtIndex, "Rivaroxaban")
printContinuousDescriptives(vkaPop$ageAtIndex, "vka")
# Test Age difference. Take pooled variance (assume the two groups have same distribution)
t.test(rivaPop$ageAtIndex, vkaPop$ageAtIndex, var.equal = TRUE)

## Gender ##
# Count number of women/men in each cohort
gender_contigency_table <- table( studyPop$GENDER_STRING, studyPop$RIVA_OR_VKA_STRING )
# Remove the unknown row from the contigency tabke
gender_contigency_table <- gender_contigency_table[-3,]
gender_contigency_table
prop.table(gender_contigency_table, margin=2)
# Do a chi square test on the contigency table
# Disable the Yates continuity correction (gave matching results to example tables)
chisq.test( gender_contigency_table, correct = FALSE )

## Income ##
printContinuousDescriptives(rivaPop$INCOME, "Rivaroxaban")
printContinuousDescriptives(vkaPop$INCOME, "vka")
# Test income difference. Take pooled variance (assume the two groups have same distribution)
t.test(rivaPop$INCOME, vkaPop$INCOME, var.equal = TRUE)

## Immigrants ##
background_contigency_table <- table( studyPop$BACKGROUND_STRING, studyPop$RIVA_OR_VKA_STRING )
background_contigency_table
prop.table(background_contigency_table, margin=2)
chisq.test( background_contigency_table, correct = FALSE )

