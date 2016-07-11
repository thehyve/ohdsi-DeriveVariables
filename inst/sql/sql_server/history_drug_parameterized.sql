/* Retrieve drug history on certain atc codes for patients within cohort.
   Did the patient have exposure to the drug(s) any time before the index date?
   Inner select marks all patients that had exposure,
   outer marks patients with at least one occurrence of that condition*/
SELECT person_id, MAX(drug) as concept_history
FROM (
    SELECT cohort.person_id,
        CASE WHEN @concept_ids AND
                  drug_exposure_start_date < cohort.index_date
             THEN 1
             ELSE 0
        END as drug

    FROM @target_schema.@target_table cohort
    LEFT JOIN @cdm_schema.drug_exposure
    ON drug_exposure.person_id = cohort.person_id

    LEFT JOIN @cdm_schema.concept_relationship AS relation
    ON drug_concept_id= relation.concept_id_1
    AND relation.relationship_id = 'RxNorm - ATC'

    LEFT JOIN @cdm_schema.concept AS atc
    ON relation.concept_id_2 = atc.concept_id
) A
GROUP BY person_id
ORDER BY person_id
;
