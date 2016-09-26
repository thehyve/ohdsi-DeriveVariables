-- Cohort for the rivaroxaban treatment group exported from ATLAS.
-- Drug exposure of Rivaroxaban on or after October 3, 2012
-- Age Greater or equal to 18
-- Condition occurrence of atrial fibrillation before index date

CREATE TEMP TABLE Codesets  (
  codeset_id int NOT NULL,
  concept_id bigint NOT NULL
)
;

INSERT INTO Codesets (codeset_id, concept_id)
SELECT 0 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @cdm_database_schema.CONCEPT where concept_id in (40241331)and invalid_reason is null
UNION  select c.concept_id
  from @cdm_database_schema.CONCEPT c
  join @cdm_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (40241331)
  and c.invalid_reason is null

) I
) C;
INSERT INTO Codesets (codeset_id, concept_id)
SELECT 1 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @cdm_database_schema.CONCEPT where concept_id in (313217)and invalid_reason is null
UNION  select c.concept_id
  from @cdm_database_schema.CONCEPT c
  join @cdm_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (313217)
  and c.invalid_reason is null

) I
) C;

CREATE TEMP TABLE primary_events

AS
SELECT
 row_number() over (order by P.person_id, P.start_date) as event_id, P.person_id, P.start_date, P.end_date, OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date

FROM

(
  select P.person_id, P.start_date, P.end_date, ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY start_date ASC) ordinal
  FROM 
  (
  select C.person_id, C.drug_exposure_start_date as start_date, COALESCE(C.drug_exposure_end_date, ( C.drug_exposure_start_date +  1)) as end_date, C.drug_concept_id as TARGET_CONCEPT_ID
from 
(
  select de.*, ROW_NUMBER() over (PARTITION BY de.person_id ORDER BY de.drug_exposure_start_date) as ordinal
  FROM @cdm_database_schema.DRUG_EXPOSURE de
where de.drug_concept_id in (SELECT concept_id from  Codesets where codeset_id = 0)
) C
JOIN @cdm_database_schema.PERSON P on C.person_id = P.person_id
WHERE C.drug_exposure_start_date >= TO_DATE(TO_CHAR(2012,'0000')||'-'||TO_CHAR( 10,'00')||'-'||TO_CHAR( 03,'00'), 'YYYY-MM-DD')
AND EXTRACT(YEAR FROM C.drug_exposure_start_date) - P.year_of_birth >= 18

  ) P
) P
JOIN @cdm_database_schema.observation_period OP on P.person_id = OP.person_id and P.start_date between OP.observation_period_start_date and op.observation_period_end_date
WHERE (OP.OBSERVATION_PERIOD_START_DATE + 0) <= P.START_DATE AND (P.START_DATE + 0) <= OP.OBSERVATION_PERIOD_END_DATE
;


CREATE TEMP TABLE qualified_events

AS
SELECT
 event_id, person_id, start_date, end_date, op_start_date, op_end_date

FROM
 
(
  select pe.event_id, pe.person_id, pe.start_date, pe.end_date, pe.op_start_date, pe.op_end_date, row_number() over (partition by pe.person_id order by pe.start_date ASC) as ordinal
  FROM primary_events pe
  
JOIN (
select 0 as index_id, event_id
FROM
(
  select event_id FROM
  (
    SELECT 0 as index_id, p.event_id
FROM primary_events P
LEFT JOIN
(
  select C.person_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, (C.condition_start_date + 1)) as end_date, C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID
from 
(
        select co.*, ROW_NUMBER() over (PARTITION BY co.person_id ORDER BY co.condition_start_date) as ordinal
        FROM @cdm_database_schema.CONDITION_OCCURRENCE co
where co.condition_concept_id in (SELECT concept_id from  Codesets where codeset_id = 1)
) C



) A on A.person_id = P.person_id and A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE AND A.START_DATE >= P.OP_START_DATE and A.START_DATE <= (P.START_DATE + 0)
GROUP BY p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) >= 1


  ) CQ
  GROUP BY event_id
  HAVING COUNT(index_id) = 1
) G
) AC on AC.event_id = pe.event_id

) QE

;


CREATE TEMP TABLE inclusionRuleCohorts 
 (
  inclusion_rule_id bigint,
  event_id bigint
)
;


CREATE TEMP TABLE included_events

AS
WITH  cteIncludedEvents(event_id, person_id, start_date, end_date, op_start_date, op_end_date, ordinal)  AS 
(
  SELECT event_id, person_id, start_date, end_date, op_start_date, op_end_date, row_number() over (partition by person_id order by start_date ASC) as ordinal
  from
  (
    select Q.event_id, Q.person_id, Q.start_date, Q.end_date, Q.op_start_date, Q.op_end_date, SUM(coalesce(POWER(cast(2 as bigint), I.inclusion_rule_id), 0)) as inclusion_rule_mask
    from qualified_events Q
    LEFT JOIN inclusionRuleCohorts I on I.event_id = Q.event_id
    GROUP BY Q.event_id, Q.person_id, Q.start_date, Q.end_date, Q.op_start_date, Q.op_end_date
  ) MG -- matching groups

)
 SELECT
 event_id, person_id, start_date, end_date, op_start_date, op_end_date

FROM
 cteIncludedEvents Results

;

-- Apply end date stratagies
-- by default, all events extend to the op_end_date.
CREATE TEMP TABLE cohort_ends

AS
SELECT
 event_id, person_id, op_end_date as end_date

FROM
 included_events;



DELETE FROM @target_database_schema.@target_cohort_table where cohort_definition_id = @target_cohort_id;
INSERT INTO @target_database_schema.@target_cohort_table (cohort_definition_id, subject_id, cohort_start_date, cohort_end_date)
select @target_cohort_id as cohort_definition_id, F.person_id, F.start_date, F.end_date
FROM (
  select Q.person_id, Q.start_date, E.end_date, row_number() over (partition by Q.event_id order by E.end_date) as ordinal 
  from qualified_events Q
  join cohort_ends E on Q.event_id = E.event_id and Q.person_id = E.person_id and E.end_date >= Q.start_date
) F
WHERE F.ordinal = 1
;




TRUNCATE TABLE cohort_ends;
DROP TABLE cohort_ends;

TRUNCATE TABLE inclusionRuleCohorts;
DROP TABLE inclusionRuleCohorts;

TRUNCATE TABLE qualified_events;
DROP TABLE qualified_events;

TRUNCATE TABLE included_events;
DROP TABLE included_events;

TRUNCATE TABLE primary_events;
DROP TABLE primary_events;

TRUNCATE TABLE Codesets;
DROP TABLE Codesets;