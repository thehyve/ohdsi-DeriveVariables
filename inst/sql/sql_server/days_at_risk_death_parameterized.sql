SELECT  cohort.person_id,
        -- Days from index+30 to death
        CASE WHEN cause_concept_id IS NOT NULL
             THEN death_date - index_date - @days_correction
             ELSE to_date(@study_end_date::varchar,'yyyymmdd') - index_date
        END AS days_at_risk,
        cause_concept_id,
        CASE WHEN cause_concept_id IS NOT NULL
             THEN 1
             ELSE 0
         END AS censor
FROM (
    SELECT  cohort.person_id,
            MAX(death_date) as death_date, -- Every person has one or no death date, thus max gives the death date.
            MAX(cause_concept_id) as cause_concept_id
    FROM @target_schema.@target_table cohort
    LEFT JOIN @cdm_schema.death
        ON cohort.person_id = death.person_id
    -- Add secondary causes of death (morsak)
    LEFT JOIN @cdm_schema.observation death_causes
        ON  observation_concept_id = 4083743 -- Cause of Death
        AND death.person_id = death_causes.person_id
        AND death.death_date = death_causes.observation_date
    WHERE death_date > index_date AND @where_clause
    GROUP BY cohort.person_id -- Groups all the secondary causes of death
) temp
RIGHT JOIN @target_schema.@target_table cohort
    ON cohort.person_id = temp.person_id
ORDER BY cohort.person_id
;
