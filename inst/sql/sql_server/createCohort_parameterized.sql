/*
Writes studypopulation to the relation study.masterfile
TODO: this is a slow procedure. Lot of calculations. Use EXPLAIN to find a way to speed things up.
*/
drop schema if exists @target_schema cascade;
CREATE SCHEMA @target_schema;

WITH condition_start AS (
    /* Step 1. Per patient, take the date of first occurrence of a diagnosis of AF */
    SELECT person_id, MIN(condition_start_date) as condition_index
    FROM @cdm_schema.condition_occurrence
    -- WHERE condition_concept_id in (313217,4117112,45768480,4232697,44782442,4108832,4119602,4119601,4141360,4232691,4199501,4154290) -- or ancestor_concept_id 313217
    -- WHERE condition_source_value like 'I48%' -- AF is all ICD10 everything starting with I48
    WHERE condition_start_date > to_date('19000101','yyyymmdd')
    GROUP BY person_id
),
    /* Step 2. First Riva occurrence within inclusion period */
    riva_start AS (
    SELECT person_id, MIN(drug_exposure_start_date) as riva_first_date
    FROM @cdm_schema.drug_exposure
    WHERE drug_concept_id in (40241331)-- Rivaroxaban (B01AF01)
        AND drug_exposure_start_date >= to_date(@study_start_yyyymmdd::varchar,'yyyymmdd') -- After Nov 30, 2011
        AND drug_exposure_start_date <= to_date(@study_end_yyyymmdd::varchar,'yyyymmdd') -- Before Jan 01 2015
    GROUP BY person_id
),
    /* Step 2. First VKA occurrence within inclusion period */
    vka_start AS (
    SELECT person_id, MIN(drug_exposure_start_date) as vka_first_date
    FROM @cdm_schema.drug_exposure
    WHERE drug_concept_id in (1310149, 19035344) -- Warfarin and Phenprocoumon (B01AA03, B01AA04)
        AND drug_exposure_start_date >= to_date(@study_start_yyyymmdd::varchar,'yyyymmdd') -- After Nov 30, 2011
        AND drug_exposure_start_date <= to_date(@study_end_yyyymmdd::varchar,'yyyymmdd') -- Before Jan 01 2015
    GROUP BY person_id
),
    ages AS (
    SELECT person_id, MAX(value_as_number) as value_as_number
    FROM @cdm_schema.measurement
    WHERE measurement_source_value = 'alder'
    GROUP BY person_id
),
/* Step 3. Study population selection */
    population AS (
    SELECT person.person_id, person.year_of_birth, condition_index, riva_first_date, vka_first_date, ages.value_as_number as age,
            -- Determine which was first, riva or vka. 1 = riva, 0 = vka
            CASE WHEN riva_first_date < vka_first_date OR vka_first_date IS NULL
                 THEN 1
                 ELSE 0
            END as riva_or_vka,

            CASE WHEN riva_first_date < vka_first_date OR vka_first_date IS NULL
                 THEN riva_first_date
                 ELSE vka_first_date
            END as index_date,

            CASE WHEN riva_first_date = vka_first_date
                 THEN 1
                 ELSE 0
            END as same_day
            -- riva_first_date - tempindex, vka_first_date - tempindex
    FROM @cdm_schema.person
    LEFT JOIN riva_start
        ON person.person_id = riva_start.person_id
    LEFT JOIN vka_start
        ON person.person_id = vka_start.person_id
    LEFT JOIN condition_start
        ON person.person_id = condition_start.person_id
    LEFT JOIN ages
        ON ages.person_id = person.person_id
),
/* Step 4. Get OAC drug history */
    oac_history as (
        SELECT population.*, drug_concept_id, drug_exposure_start_date
        FROM @cdm_schema.drug_exposure
        JOIN population -- Join here decreases the size of the table
            ON drug_exposure.person_id = population.person_id
        WHERE drug_concept_id in (40241331,1310149,19035344,40228152,43013024) -- riva, warfarin, phenprocoumon, dabigatran, apixaban
),
/* First oac occurrence (for naive calculation) */
    first_oac as (
        SELECT person_id, MIN(drug_exposure_start_date) AS first_oac_date
        FROM oac_history
        GROUP BY person_id
),
/* Step 5. Switchers to other oac after index date. Only keeps first switch*/
    switchers as (
        SELECT A.*, B.drug_concept_id as switchto
        FROM (
            SELECT person_id, MIN(drug_exposure_start_date) as switchDate
            FROM oac_history
            WHERE drug_exposure_start_date > index_date
                  -- Not the same drug as index drug
                  AND NOT ( (drug_concept_id = 40241331 AND riva_or_vka = 1)
                         OR (drug_concept_id in (1310149,19035344) AND riva_or_vka = 0)
                          )
            GROUP BY person_id
        ) A JOIN oac_history B
                ON A.person_id = B.person_id AND A.switchDate = B.drug_exposure_start_date
)

SELECT  population.person_id, population.riva_or_vka, population.index_date,
        -- Naive
        CASE WHEN first_oac_date < index_date
             THEN 0 -- Non-naive: Purchase after index date
             ELSE 1 -- Naive: Purchase before index date,
        END as is_naive,
        -- Switch?
        switchto,
        switchDate
INTO @target_schema.@target_table
FROM population
LEFT JOIN first_oac
  ON first_oac.person_id = population.person_id
LEFT JOIN switchers
  ON switchers.person_id = population.person_id
WHERE
  /* Actual Study population selection rules. */
  (riva_first_date IS NOT NULL or vka_first_date IS NOT NULL)
  AND same_day = 0
  AND age > 18 AND (2012 - year_of_birth) > 18 -- Older than 18 at start of inclusion period
  AND (condition_index IS NULL OR condition_index < index_date) -- Missing AF or tempindex before index date
ORDER BY person_id
;
