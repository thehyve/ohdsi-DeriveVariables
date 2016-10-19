SELECT  cohort.person_id,
        -- Days from index (plus correction) to condition date. Or to end of study period.
        CASE WHEN condition_date IS NOT NULL
             THEN condition_date - index_date - @days_correction
             ELSE to_date(@study_end_date::varchar,'yyyymmdd') - index_date - @days_correction
        END AS days_at_risk,
        -- Has gotten condition yes or no
        CASE WHEN condition_date IS NOT NULL
             THEN 1
             ELSE 0
         END AS censor
FROM (
    SELECT  cohort.person_id,
            -- First occurrence of condition (after index)
            MIN(condition_start_date) as condition_date
    FROM @target_schema.@target_table cohort
    LEFT JOIN @cdm_schema.condition_occurrence AS condition
        ON cohort.person_id = condition.person_id
    WHERE condition_start_date > index_date AND death_date < to_date(@study_end_date::varchar,'yyyymmdd')
        AND @where_clause
        -- Not a Secondary condition (Primary and first place condition are allowed)
        AND condition_type_concept_id != 44786629
    GROUP BY cohort.person_id -- Groups all the secondary causes of death
) temp
RIGHT JOIN @target_schema.@target_table cohort
    ON cohort.person_id = temp.person_id
ORDER BY cohort.person_id
;
