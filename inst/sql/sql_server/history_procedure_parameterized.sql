/* Retrieve medical history on certain concept id for patients within cohort.
   Did the patient have the condition any time before the index date?
   Inner select marks all patients that had the condition,
   outer marks patients with at least one occurrence of that condition*/
SELECT person_id, MAX(procedure_bool) as concept_history
FROM (
    SELECT cohort.person_id,
        CASE WHEN procedure_concept_id in (@concept_ids) AND
                  procedure_date >= cohort.index_date - INTERVAL '@days_before_index days' AND
                  procedure_date <= cohort.index_date + INTERVAL '@days_after_index days'
             THEN 1
             ELSE 0
        END as procedure_bool

    FROM @target_schema.@target_table as cohort
    LEFT JOIN @cdm_schema.procedure_occurrence
        ON procedure_occurrence.person_id = cohort.person_id
) A
GROUP BY person_id
ORDER BY person_id
;
