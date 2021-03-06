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

########### Descriptive Statistics ###########

### Table 1. Identification of patients ###
# Create a contigency table of index drug vs naive.
# Use string representations instead of id representations (INDEX_DRUG and IS_NAIVE)
contigency_table <- table(INDEX_DRUG_STRING, IS_NAIVE_STRING)
print(contigency_table)
# Percentage naive/non-naive per group
prop.table( contigency_table, margin=1)

### Table 7. Patients who switched from index drug to another OAC ##
# Create contigency table
switchTable <- table(INDEX_DRUG_STRING, SWITCHTO_STRING)
View(switchTable)
# TODO: As percentage of patients with that index drug
# Total percentage that switched
studySize <- nrow(cohort)
sprintf("Total percent switched: %.2f%%:", sum(switchTable)/studySize*100)

############ Analysis ############

### Table 8. Demography and group testing ###
# Calculate age at index date. Add to dataframe
cohort$ageAtIndex <- getAgeAtIndex( cohort )

# Create two groups, riva and vka. On index, not on string name
# Note: we can't use attach here, because we are comparing two different data frames.
rivaGroup <- cohort[ INDEX_DRUG == 1, ]
vkaGroup  <- cohort[ INDEX_DRUG == 0, ]

## Age ##
# Print descriptive metrics (datalength, mean, sd, median, IQR)
printContinuousDescriptives( rivaGroup$ageAtIndex, "Rivaroxaban" )
printContinuousDescriptives( vkaGroup$ageAtIndex, "vka" )
# Test Age difference. Take pooled variance (assume the two groups have same distribution)
t.test( rivaGroup$ageAtIndex, vkaGroup$ageAtIndex, var.equal = TRUE )

## Gender ##
# Count number of women/men in each cohort
gender_contigency_table <- table( GENDER_STRING, INDEX_DRUG_STRING )
# Remove the unknown row from the contigency tabke
gender_contigency_table <- gender_contigency_table[-3,]
gender_contigency_table
prop.table(gender_contigency_table, margin=2)
# Perform a chi square test on the contigency table
# Disable the Yates continuity correction (gave matching results to example tables)
chisq.test( gender_contigency_table, correct = FALSE )

## Income ##
printContinuousDescriptives( rivaGroup$INCOME, "Rivaroxaban" )
printContinuousDescriptives( vkaGroup$INCOME, "vka" )
# Test income difference. Take pooled variance (assume the two groups have same distribution)
t.test( rivaGroup$INCOME, vkaGroup$INCOME, var.equal = TRUE )

## Immigrants ##
background_contigency_table <- table( BACKGROUND_STRING, INDEX_DRUG_STRING )
background_contigency_table
prop.table( background_contigency_table, margin=2 )
chisq.test( background_contigency_table, correct = FALSE )
