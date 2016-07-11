/* Retrieve drug history on certain atc codes for patients within cohort.
   Did the patient have exposure to the drug(s) any time before the index date?
   Inner select marks all patients that had exposure,
   outer marks patients with at least one occurrence of that condition*/
SELECT cohort.person_id,
       CASE WHEN MAX(drug_30_after) = 1 AND MAX(drug_365_before) = 0
            THEN 1
            ELSE 0
       END as drug_new
FROM (
    SELECT cohort.person_id,
            -- Drug purchased in 30 days following index_date
            CASE WHEN
                  drug_exposure_start_date >= cohort.index_date AND
                  drug_exposure_start_date < cohort.index_date + INTERVAL '30 day'
                  THEN 1
                  ELSE 0
             END as drug_30_after,

             -- Drug purchased in the year before index
            CASE WHEN drug_exposure_start_date < cohort.index_date AND
                  drug_exposure_start_date > cohort.index_date - INTERVAL '1 year'
                  THEN 1
                  ELSE 0
             END as drug_365_before

    FROM @target_schema.@target_table cohort
    LEFT JOIN @cdm_schema.drug_exposure
        ON drug_exposure.person_id = cohort.person_id

    JOIN @cdm_schema.concept_relationship AS relation
        ON drug_concept_id= relation.concept_id_1
            AND relation.relationship_id = 'RxNorm - ATC'

    JOIN @cdm_schema.concept AS atc
        ON relation.concept_id_2 = atc.concept_id

    WHERE @where_clause
) A
RIGHT JOIN @target_schema.@target_table cohort
    ON cohort.person_id = A.person_id
GROUP BY cohort.person_id
ORDER BY cohort.person_id
;
