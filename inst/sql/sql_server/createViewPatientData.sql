CREATE OR REPLACE VIEW @view_name AS

SELECT  person_id,
        condition_concept_id as concept_id,
        condition_source_value as source_value,
        condition_start_date as start_date,
        'condition_occurrence' as table
FROM @cdm_schema.condition_occurrence

UNION ALL

SELECT  person_id,
        procedure_concept_id,
        procedure_source_value,
        procedure_date,
        'procedure_occurrence'
FROM @cdm_schema.procedure_occurrence

UNION ALL

SELECT  person_id,
        drug_concept_id,
        drug_source_value,
        drug_exposure_start_date,
        'drug_exposure'
FROM @cdm_schema.drug_exposure
;
