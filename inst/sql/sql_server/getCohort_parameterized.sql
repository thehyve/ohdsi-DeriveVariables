/* Get cohort with income and background data */
SELECT *
FROM @target_schema.@target_table AS cohort
JOIN @cdm_schema.person
  ON cohort.person_id = person.person_id

-- Add income
LEFT JOIN (
    SELECT person_id, MAX(value_as_number) as income
    FROM @cdm_schema.measurement
    WHERE measurement.measurement_concept_id = 4073460
    GROUP BY person_id
) income
    ON cohort.person_id = income.person_id

-- Add background
LEFT JOIN (
    SELECT person_id, MAX(value_as_concept_id) as background
    FROM @cdm_schema.observation
    WHERE observation.observation_concept_id = 4136468
    GROUP BY person_id
) background
    ON cohort.person_id = background.person_id
    
ORDER BY cohort.person_id
;
