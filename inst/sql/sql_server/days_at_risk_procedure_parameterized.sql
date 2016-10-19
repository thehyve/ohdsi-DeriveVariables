SELECT  cohort.person_id,
        -- Days from index (plus correction) to condition date. Or to end of study period.
        CASE WHEN procedure_date IS NOT NULL
             THEN procedure_date - index_date - @days_correction
             ELSE to_date(@study_end_date::varchar,'yyyymmdd') - index_date - @days_correction
        END AS days_at_risk,
        -- Has gotten procedure yes or no
        CASE WHEN procedure_date IS NOT NULL
             THEN 1
             ELSE 0
         END AS censor
FROM (
    SELECT  cohort.person_id,
            -- First occurrence of condition (after index)
            MIN(procedure_date) as procedure_date
    FROM @target_schema.@target_table cohort
    LEFT JOIN @cdm_schema.procedure_occurrence AS procedure
        ON cohort.person_id = procedure.person_id
    WHERE procedure_date > index_date AND death_date < to_date(@study_end_date::varchar,'yyyymmdd')
        AND @where_clause
    GROUP BY cohort.person_id -- Groups all the secondary causes of death
) temp
RIGHT JOIN @target_schema.@target_table cohort
    ON cohort.person_id = temp.person_id
ORDER BY cohort.person_id
;
