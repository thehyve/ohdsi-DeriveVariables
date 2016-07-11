/* Retrieve medical history on certain concept id for patients within cohort.
   Did the patient have the condition any time before the index date?
   Inner select marks all patients that had the condition,
   outer marks patients with at least one occurrence of that condition*/
SELECT person_id, MAX(condition) as concept_history
FROM (
    SELECT cohort.person_id,
        CASE WHEN condition_concept_id in (@concept_ids)
                  AND condition_start_date < index_date
             THEN 1
             ELSE 0
        END as condition

    FROM @target_schema.@target_table as cohort
    LEFT JOIN @cdm_schema.condition_occurrence
        ON condition_occurrence.person_id = cohort.person_id
) A
GROUP BY person_id
ORDER BY person_id
;
