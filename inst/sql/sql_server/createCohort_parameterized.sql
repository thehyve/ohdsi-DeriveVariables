/*
Creates Study cohort and saves to a table.
*/
DROP SCHEMA IF EXISTS @target_schema cascade;
CREATE SCHEMA @target_schema;

WITH condition_start AS (
    /* Step 1. Per patient, take the date of first occurrence of a diagnosis of AF */
    SELECT person_id, MIN(condition_start_date) as condition_index
    FROM @cdm_schema.condition_occurrence
    WHERE condition_start_date > DATE '1900-01-01' -- Filter empty dates
    GROUP BY person_id
),
    /* Step 2. First Riva occurrence within inclusion period */
    riva_start AS (
    SELECT person_id, MIN(drug_exposure_start_date) as riva_first_date
    FROM @cdm_schema.drug_exposure
    WHERE drug_concept_id in (@riva_ids)-- Rivaroxaban (B01AF01)
        AND drug_exposure_start_date >= DATE '@study_start_date' -- After Nov 30, 2011
        AND drug_exposure_start_date <= DATE '@study_end_date' -- Before Jan 01 2015
    GROUP BY person_id
),
    /* Step 2. First VKA occurrence within inclusion period */
    vka_start AS (
    SELECT person_id, MIN(drug_exposure_start_date) as vka_first_date
    FROM @cdm_schema.drug_exposure
    WHERE (
        -- Warfarin
        drug_concept_id in (@warf_ids)
        -- Phenprocoumon
        OR drug_concept_id in (@phen_ids)
        )
        AND drug_exposure_start_date >= DATE '@study_start_date' -- After Nov 30, 2011
        AND drug_exposure_start_date <= DATE '@study_end_date' -- Before Jan 01 2015
    GROUP BY person_id
),
    ages AS (
    SELECT person_id, MAX(value_as_number) as value_as_number
    FROM @cdm_schema.measurement
    WHERE measurement_concept_id = 4265453 -- 'alder'
    GROUP BY person_id
),
/* Step 3. Study cohort selection */
    cohort AS (
    SELECT person.person_id, person.year_of_birth, condition_index, riva_first_date, vka_first_date, ages.value_as_number as age,
            -- Determine which was first, riva or vka. 1 = riva, 0 = vka
            CASE WHEN riva_first_date < vka_first_date OR vka_first_date IS NULL
                 THEN 1
                 ELSE 0
            END as index_drug,

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
        SELECT cohort.*, drug_concept_id, drug_exposure_start_date
        FROM @cdm_schema.drug_exposure
        JOIN cohort -- Join here decreases the size of the table
            ON drug_exposure.person_id = cohort.person_id
        WHERE drug_concept_id in (@riva_ids,@warf_ids,@phen_ids,@dabi_ids,@apix_ids) -- 40241331,1310149,19035344,40228152,43013024) -- riva, warfarin, phenprocoumon, dabigatran, apixaban
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
                  AND NOT ( (drug_concept_id IN (@riva_ids) AND index_drug = 1)
                         OR (drug_concept_id IN (@warf_ids) AND index_drug = 0)
                          )
            GROUP BY person_id
        ) A JOIN oac_history B
                ON A.person_id = B.person_id AND A.switchDate = B.drug_exposure_start_date
)
-- If multiple lines for one person, select just one. Happens e.g. when multiple switches on the same date.
SELECT  DISTINCT ON (cohort.person_id)
        cohort.person_id,
        cohort.index_drug,
        cohort.index_date,
        -- Naive
        CASE WHEN first_oac_date < index_date
             THEN 0 -- Non-naive: Purchase after index date
             ELSE 1 -- Naive: Purchase before index date,
        END as is_naive,
        -- Switch to other anticoagulant
        switchto,
        switchDate
INTO @target_schema.@target_table
FROM cohort
LEFT JOIN first_oac
  ON first_oac.person_id = cohort.person_id
LEFT JOIN switchers
  ON switchers.person_id = cohort.person_id
WHERE
  /* Study cohort selection rules. */
  (riva_first_date IS NOT NULL or vka_first_date IS NOT NULL)
  AND same_day = 0
  AND (EXTRACT(YEAR FROM index_date) - year_of_birth) > 18 -- Older than 18 at index date
  AND (condition_index IS NULL OR condition_index < index_date) -- No AF diagnosis or tempindex before index date
;
