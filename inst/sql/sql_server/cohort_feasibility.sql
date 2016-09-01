/*********************************************************************************
# Copyright 2014-2015 Observational Health Data Sciences and Informatics
#
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
********************************************************************************/

IF OBJECT_ID('@results_database_schema.cohort_inclusion', 'U') IS NOT NULL 
  DROP TABLE @results_database_schema.cohort_inclusion; 

CREATE TABLE @results_database_schema.cohort_inclusion(
  cohort_definition_id int NOT NULL,
  rule_sequence int NOT NULL,
  name varchar(255) NULL,
  description varchar(1000) NULL
)
;

IF OBJECT_ID('@results_database_schema.cohort_inclusion_result', 'U') IS NOT NULL 
  DROP TABLE @results_database_schema.cohort_inclusion_result; 

CREATE TABLE @results_database_schema.cohort_inclusion_result(
  cohort_definition_id int NOT NULL,
  inclusion_rule_mask bigint NOT NULL,
  person_count bigint NOT NULL
)
;

IF OBJECT_ID('@results_database_schema.cohort_inclusion_stats', 'U') IS NOT NULL 
  DROP TABLE @results_database_schema.cohort_inclusion_stats; 

CREATE TABLE @results_database_schema.cohort_inclusion_stats(
  cohort_definition_id int NOT NULL,
  rule_sequence int NOT NULL,
  person_count bigint NOT NULL,
  gain_count bigint NOT NULL,
  person_total bigint NOT NULL
)
;

IF OBJECT_ID('@results_database_schema.cohort_summary_stats', 'U') IS NOT NULL 
  DROP TABLE @results_database_schema.cohort_summary_stats; 
  
CREATE TABLE @results_database_schema.cohort_summary_stats(
  cohort_definition_id int NOT NULL,
  base_count bigint NOT NULL,
  final_count bigint NOT NULL
)
;

IF OBJECT_ID('@results_database_schema.cohort_test', 'U') IS NOT NULL 
  DROP TABLE @results_database_schema.cohort_test; 

CREATE TABLE @results_database_schema.cohort_test 
AS TABLE @results_database_schema.cohort;