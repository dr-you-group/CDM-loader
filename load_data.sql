\set ON_ERROR_STOP on

-- This file is a psql script because \copy reads files on the client machine.
-- Run it with:
--   psql -X -v ON_ERROR_STOP=1 -v data_dir=/absolute/path/to/data -f load_data.sql
--
-- Optional psql booleans (all default to true):
--   -v load_mimiciv=false
--   -v load_synpuf=false
--   -v load_ehrshot=false
--   -v analyze_after_load=false
--
-- The downloader has already verified each CSV header against its ordered
-- *_column.csv manifest or ehrshot_headers.tsv. Explicit column lists below
-- preserve that contract. EHRSHOT uses HEADER true because its CSV headers
-- capitalize DATE/DATETIME while the CDM columns retain lowercase names.

\if :{?data_dir}
\else
  \echo 'ERROR: data_dir is required and must point to the download directory.'
  DO $$ BEGIN RAISE EXCEPTION 'load_data.sql preflight failed'; END $$;
\endif

\if :{?load_mimiciv}
\else
  \set load_mimiciv true
\endif
\if :{?load_synpuf}
\else
  \set load_synpuf true
\endif
\if :{?load_ehrshot}
\else
  \set load_ehrshot true
\endif
\if :{?analyze_after_load}
\else
  \set analyze_after_load true
\endif

\cd :data_dir

SET client_encoding TO 'UTF8';
SET synchronous_commit TO off;
SET statement_timeout TO 0;

-- CommonDataModel::executeDdl(cdmVersion = "5.3") must have created the
-- untouched 37-table CDM base with primary and foreign keys disabled.
-- All reference-specific type changes and supplemental tables are applied here.
\if :load_mimiciv
SELECT (
  (SELECT count(*) FROM information_schema.tables
   WHERE table_schema = 'mimiciv' AND table_type = 'BASE TABLE') = 37
  AND
  (SELECT count(*) FROM information_schema.columns
   WHERE table_schema = 'mimiciv') = 396
  AND
  (SELECT count(*) FROM information_schema.columns
   WHERE table_schema = 'mimiciv' AND is_nullable = 'NO') = 164
  AND
  (SELECT count(*) FROM information_schema.columns
   WHERE table_schema = 'mimiciv' AND data_type = 'bigint') = 0
  AND
  (SELECT count(*)
   FROM pg_catalog.pg_constraint c
   JOIN pg_catalog.pg_namespace n ON n.oid = c.connamespace
   WHERE n.nspname = 'mimiciv' AND c.contype IN ('p', 'f')) = 0
) AS mimiciv_base_ok
\gset
\if :mimiciv_base_ok
\else
  \echo 'ERROR: mimiciv must be the untouched unkeyed 37-table CDM 5.3 base.'
  DO $$ BEGIN RAISE EXCEPTION 'load_data.sql preflight failed'; END $$;
\endif
SELECT NOT (
  EXISTS (SELECT 1 FROM "mimiciv"."attribute_definition") OR
  EXISTS (SELECT 1 FROM "mimiciv"."care_site") OR
  EXISTS (SELECT 1 FROM "mimiciv"."cdm_source") OR
  EXISTS (SELECT 1 FROM "mimiciv"."cohort_definition") OR
  EXISTS (SELECT 1 FROM "mimiciv"."concept_ancestor") OR
  EXISTS (SELECT 1 FROM "mimiciv"."concept_class") OR
  EXISTS (SELECT 1 FROM "mimiciv"."concept") OR
  EXISTS (SELECT 1 FROM "mimiciv"."concept_relationship") OR
  EXISTS (SELECT 1 FROM "mimiciv"."concept_synonym") OR
  EXISTS (SELECT 1 FROM "mimiciv"."condition_era") OR
  EXISTS (SELECT 1 FROM "mimiciv"."condition_occurrence") OR
  EXISTS (SELECT 1 FROM "mimiciv"."cost") OR
  EXISTS (SELECT 1 FROM "mimiciv"."death") OR
  EXISTS (SELECT 1 FROM "mimiciv"."device_exposure") OR
  EXISTS (SELECT 1 FROM "mimiciv"."domain") OR
  EXISTS (SELECT 1 FROM "mimiciv"."dose_era") OR
  EXISTS (SELECT 1 FROM "mimiciv"."drug_era") OR
  EXISTS (SELECT 1 FROM "mimiciv"."drug_exposure") OR
  EXISTS (SELECT 1 FROM "mimiciv"."drug_strength") OR
  EXISTS (SELECT 1 FROM "mimiciv"."fact_relationship") OR
  EXISTS (SELECT 1 FROM "mimiciv"."location") OR
  EXISTS (SELECT 1 FROM "mimiciv"."measurement") OR
  EXISTS (SELECT 1 FROM "mimiciv"."metadata") OR
  EXISTS (SELECT 1 FROM "mimiciv"."note") OR
  EXISTS (SELECT 1 FROM "mimiciv"."note_nlp") OR
  EXISTS (SELECT 1 FROM "mimiciv"."observation") OR
  EXISTS (SELECT 1 FROM "mimiciv"."observation_period") OR
  EXISTS (SELECT 1 FROM "mimiciv"."payer_plan_period") OR
  EXISTS (SELECT 1 FROM "mimiciv"."person") OR
  EXISTS (SELECT 1 FROM "mimiciv"."procedure_occurrence") OR
  EXISTS (SELECT 1 FROM "mimiciv"."provider") OR
  EXISTS (SELECT 1 FROM "mimiciv"."relationship") OR
  EXISTS (SELECT 1 FROM "mimiciv"."source_to_concept_map") OR
  EXISTS (SELECT 1 FROM "mimiciv"."specimen") OR
  EXISTS (SELECT 1 FROM "mimiciv"."visit_detail") OR
  EXISTS (SELECT 1 FROM "mimiciv"."visit_occurrence") OR
  EXISTS (SELECT 1 FROM "mimiciv"."vocabulary")
) AS mimiciv_base_empty
\gset
\if :mimiciv_base_empty
\else
  \echo 'ERROR: mimiciv is not empty. Load into a newly created CDM schema.'
  DO $$ BEGIN RAISE EXCEPTION 'load_data.sql preflight failed'; END $$;
\endif
\endif

\if :load_synpuf
SELECT (
  (SELECT count(*) FROM information_schema.tables
   WHERE table_schema = 'synpuf' AND table_type = 'BASE TABLE') = 37
  AND
  (SELECT count(*) FROM information_schema.columns
   WHERE table_schema = 'synpuf') = 396
  AND
  (SELECT count(*) FROM information_schema.columns
   WHERE table_schema = 'synpuf' AND is_nullable = 'NO') = 164
  AND
  (SELECT count(*) FROM information_schema.columns
   WHERE table_schema = 'synpuf' AND data_type = 'bigint') = 0
  AND
  (SELECT count(*)
   FROM pg_catalog.pg_constraint c
   JOIN pg_catalog.pg_namespace n ON n.oid = c.connamespace
   WHERE n.nspname = 'synpuf' AND c.contype IN ('p', 'f')) = 0
) AS synpuf_base_ok
\gset
\if :synpuf_base_ok
\else
  \echo 'ERROR: synpuf must be the untouched unkeyed 37-table CDM 5.3 base.'
  DO $$ BEGIN RAISE EXCEPTION 'load_data.sql preflight failed'; END $$;
\endif
SELECT NOT (
  EXISTS (SELECT 1 FROM "synpuf"."attribute_definition") OR
  EXISTS (SELECT 1 FROM "synpuf"."care_site") OR
  EXISTS (SELECT 1 FROM "synpuf"."cdm_source") OR
  EXISTS (SELECT 1 FROM "synpuf"."cohort_definition") OR
  EXISTS (SELECT 1 FROM "synpuf"."concept_ancestor") OR
  EXISTS (SELECT 1 FROM "synpuf"."concept_class") OR
  EXISTS (SELECT 1 FROM "synpuf"."concept") OR
  EXISTS (SELECT 1 FROM "synpuf"."concept_relationship") OR
  EXISTS (SELECT 1 FROM "synpuf"."concept_synonym") OR
  EXISTS (SELECT 1 FROM "synpuf"."condition_era") OR
  EXISTS (SELECT 1 FROM "synpuf"."condition_occurrence") OR
  EXISTS (SELECT 1 FROM "synpuf"."cost") OR
  EXISTS (SELECT 1 FROM "synpuf"."death") OR
  EXISTS (SELECT 1 FROM "synpuf"."device_exposure") OR
  EXISTS (SELECT 1 FROM "synpuf"."domain") OR
  EXISTS (SELECT 1 FROM "synpuf"."dose_era") OR
  EXISTS (SELECT 1 FROM "synpuf"."drug_era") OR
  EXISTS (SELECT 1 FROM "synpuf"."drug_exposure") OR
  EXISTS (SELECT 1 FROM "synpuf"."drug_strength") OR
  EXISTS (SELECT 1 FROM "synpuf"."fact_relationship") OR
  EXISTS (SELECT 1 FROM "synpuf"."location") OR
  EXISTS (SELECT 1 FROM "synpuf"."measurement") OR
  EXISTS (SELECT 1 FROM "synpuf"."metadata") OR
  EXISTS (SELECT 1 FROM "synpuf"."note") OR
  EXISTS (SELECT 1 FROM "synpuf"."note_nlp") OR
  EXISTS (SELECT 1 FROM "synpuf"."observation") OR
  EXISTS (SELECT 1 FROM "synpuf"."observation_period") OR
  EXISTS (SELECT 1 FROM "synpuf"."payer_plan_period") OR
  EXISTS (SELECT 1 FROM "synpuf"."person") OR
  EXISTS (SELECT 1 FROM "synpuf"."procedure_occurrence") OR
  EXISTS (SELECT 1 FROM "synpuf"."provider") OR
  EXISTS (SELECT 1 FROM "synpuf"."relationship") OR
  EXISTS (SELECT 1 FROM "synpuf"."source_to_concept_map") OR
  EXISTS (SELECT 1 FROM "synpuf"."specimen") OR
  EXISTS (SELECT 1 FROM "synpuf"."visit_detail") OR
  EXISTS (SELECT 1 FROM "synpuf"."visit_occurrence") OR
  EXISTS (SELECT 1 FROM "synpuf"."vocabulary")
) AS synpuf_base_empty
\gset
\if :synpuf_base_empty
\else
  \echo 'ERROR: synpuf is not empty. Load into a newly created CDM schema.'
  DO $$ BEGIN RAISE EXCEPTION 'load_data.sql preflight failed'; END $$;
\endif
\endif

\if :load_ehrshot
SELECT (
  (SELECT count(*) FROM information_schema.tables
   WHERE table_schema = 'ehrshot' AND table_type = 'BASE TABLE') = 37
  AND
  (SELECT count(*) FROM information_schema.columns
   WHERE table_schema = 'ehrshot') = 396
  AND
  (SELECT count(*) FROM information_schema.columns
   WHERE table_schema = 'ehrshot' AND is_nullable = 'NO') = 164
  AND
  (SELECT count(*) FROM information_schema.columns
   WHERE table_schema = 'ehrshot' AND data_type = 'bigint') = 0
  AND
  (SELECT count(*)
   FROM pg_catalog.pg_constraint c
   JOIN pg_catalog.pg_namespace n ON n.oid = c.connamespace
   WHERE n.nspname = 'ehrshot' AND c.contype IN ('p', 'f')) = 0
) AS ehrshot_base_ok
\gset
\if :ehrshot_base_ok
\else
  \echo 'ERROR: ehrshot must be the untouched unkeyed 37-table CDM 5.3 base.'
  DO $$ BEGIN RAISE EXCEPTION 'load_data.sql preflight failed'; END $$;
\endif
DO $$
DECLARE
  table_name text;
  contains_rows boolean;
BEGIN
  FOR table_name IN
    SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname = 'ehrshot'
  LOOP
    EXECUTE format('SELECT EXISTS (SELECT 1 FROM %I.%I)', 'ehrshot', table_name)
      INTO contains_rows;
    IF contains_rows THEN
      RAISE EXCEPTION 'ehrshot.% is not empty; use a new CDM schema', table_name;
    END IF;
  END LOOP;
END $$;
\endif

-- Apply the audited reference-server deviations atomically before any COPY.
BEGIN;

\if :load_mimiciv
ALTER TABLE "mimiciv"."care_site" ALTER COLUMN "care_site_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."condition_era" ALTER COLUMN "condition_era_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."condition_era" ALTER COLUMN "person_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."condition_occurrence" ALTER COLUMN "condition_occurrence_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."condition_occurrence" ALTER COLUMN "person_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."condition_occurrence" ALTER COLUMN "visit_occurrence_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."death" ALTER COLUMN "person_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."device_exposure" ALTER COLUMN "device_exposure_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."device_exposure" ALTER COLUMN "person_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."device_exposure" ALTER COLUMN "visit_occurrence_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."drug_era" ALTER COLUMN "drug_era_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."drug_era" ALTER COLUMN "person_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."drug_exposure" ALTER COLUMN "drug_exposure_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."drug_exposure" ALTER COLUMN "person_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."drug_exposure" ALTER COLUMN "visit_occurrence_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."fact_relationship" ALTER COLUMN "fact_id_1" TYPE BIGINT;
ALTER TABLE "mimiciv"."fact_relationship" ALTER COLUMN "fact_id_2" TYPE BIGINT;
ALTER TABLE "mimiciv"."measurement" ALTER COLUMN "measurement_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."measurement" ALTER COLUMN "person_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."measurement" ALTER COLUMN "measurement_concept_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."measurement" ALTER COLUMN "measurement_type_concept_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."measurement" ALTER COLUMN "operator_concept_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."measurement" ALTER COLUMN "value_as_concept_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."measurement" ALTER COLUMN "unit_concept_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."measurement" ALTER COLUMN "provider_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."measurement" ALTER COLUMN "visit_occurrence_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."measurement" ALTER COLUMN "visit_detail_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."measurement" ALTER COLUMN "measurement_source_concept_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."observation" ALTER COLUMN "observation_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."observation" ALTER COLUMN "person_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."observation" ALTER COLUMN "visit_occurrence_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."observation_period" ALTER COLUMN "observation_period_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."observation_period" ALTER COLUMN "person_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."person" ALTER COLUMN "person_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."procedure_occurrence" ALTER COLUMN "procedure_occurrence_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."procedure_occurrence" ALTER COLUMN "person_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."procedure_occurrence" ALTER COLUMN "visit_occurrence_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."specimen" ALTER COLUMN "specimen_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."specimen" ALTER COLUMN "person_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."visit_detail" ALTER COLUMN "visit_detail_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."visit_detail" ALTER COLUMN "person_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."visit_detail" ALTER COLUMN "care_site_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."visit_detail" ALTER COLUMN "preceding_visit_detail_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."visit_detail" ALTER COLUMN "visit_occurrence_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."visit_occurrence" ALTER COLUMN "visit_occurrence_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."visit_occurrence" ALTER COLUMN "person_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."visit_occurrence" ALTER COLUMN "preceding_visit_occurrence_id" TYPE BIGINT;
ALTER TABLE "mimiciv"."concept" ALTER COLUMN "concept_name" TYPE TEXT;
ALTER TABLE "mimiciv"."concept" ALTER COLUMN "domain_id" TYPE TEXT;
ALTER TABLE "mimiciv"."concept" ALTER COLUMN "vocabulary_id" TYPE TEXT;
ALTER TABLE "mimiciv"."concept" ALTER COLUMN "concept_class_id" TYPE TEXT;
ALTER TABLE "mimiciv"."concept" ALTER COLUMN "concept_code" TYPE TEXT;
ALTER TABLE "mimiciv"."condition_occurrence" ALTER COLUMN "condition_source_value" TYPE TEXT;
ALTER TABLE "mimiciv"."domain" ALTER COLUMN "domain_id" TYPE TEXT;
ALTER TABLE "mimiciv"."domain" ALTER COLUMN "domain_name" TYPE TEXT;
ALTER TABLE "mimiciv"."drug_exposure" ALTER COLUMN "drug_source_value" TYPE TEXT;
ALTER TABLE "mimiciv"."measurement" ALTER COLUMN "measurement_time" TYPE TEXT;
ALTER TABLE "mimiciv"."measurement" ALTER COLUMN "measurement_source_value" TYPE TEXT;
ALTER TABLE "mimiciv"."measurement" ALTER COLUMN "unit_source_value" TYPE TEXT;
ALTER TABLE "mimiciv"."measurement" ALTER COLUMN "value_source_value" TYPE TEXT;
ALTER TABLE "mimiciv"."observation" ALTER COLUMN "value_as_string" TYPE TEXT;
ALTER TABLE "mimiciv"."specimen" ALTER COLUMN "specimen_source_id" TYPE TEXT;
ALTER TABLE "mimiciv"."vocabulary" ALTER COLUMN "vocabulary_id" TYPE TEXT;

CREATE TABLE "mimiciv"."concept_stg" (
  concept_id INTEGER NOT NULL,
  concept_name TEXT NOT NULL,
  domain_id TEXT NOT NULL,
  vocabulary_id TEXT NOT NULL,
  concept_class_id TEXT NOT NULL,
  standard_concept VARCHAR(1) NULL,
  concept_code TEXT NOT NULL,
  valid_start_date DATE NOT NULL,
  valid_end_date DATE NOT NULL,
  invalid_reason VARCHAR(1) NULL
);

CREATE TABLE "mimiciv"."dqdashboard_results" (
  num_violated_rows BIGINT NULL,
  pct_violated_rows NUMERIC NULL,
  num_denominator_rows BIGINT NULL,
  execution_time VARCHAR(255) NULL,
  query_text VARCHAR(8000) NULL,
  check_name VARCHAR(255) NULL,
  check_level VARCHAR(255) NULL,
  check_description VARCHAR(8000) NULL,
  cdm_table_name VARCHAR(255) NULL,
  cdm_field_name VARCHAR(255) NULL,
  concept_id VARCHAR(255) NULL,
  unit_concept_id VARCHAR(255) NULL,
  sql_file VARCHAR(255) NULL,
  category VARCHAR(255) NULL,
  subcategory VARCHAR(255) NULL,
  context VARCHAR(255) NULL,
  warning VARCHAR(255) NULL,
  error VARCHAR(8000) NULL,
  checkid VARCHAR(1024) NULL,
  is_error INTEGER NULL,
  not_applicable INTEGER NULL,
  failed INTEGER NULL,
  passed INTEGER NULL,
  not_applicable_reason VARCHAR(8000) NULL,
  threshold_value INTEGER NULL,
  notes_value VARCHAR(8000) NULL
);

-- LIKE is intentionally after all measurement type changes.
CREATE TABLE "mimiciv"."measurement_stg" (LIKE "mimiciv"."measurement");
\endif

\if :load_synpuf
CREATE TABLE "synpuf"."concept_stg" (
  concept_id INTEGER NOT NULL,
  concept_name TEXT NOT NULL,
  domain_id VARCHAR(20) NOT NULL,
  vocabulary_id VARCHAR(20) NOT NULL,
  concept_class_id VARCHAR(20) NOT NULL,
  standard_concept VARCHAR(1) NULL,
  concept_code VARCHAR(50) NOT NULL,
  valid_start_date DATE NOT NULL,
  valid_end_date DATE NOT NULL,
  invalid_reason VARCHAR(1) NULL
);

CREATE TABLE "synpuf"."dqdashboard_results" (
  num_violated_rows BIGINT NULL,
  pct_violated_rows NUMERIC NULL,
  num_denominator_rows BIGINT NULL,
  execution_time VARCHAR(255) NULL,
  query_text VARCHAR(8000) NULL,
  check_name VARCHAR(255) NULL,
  check_level VARCHAR(255) NULL,
  check_description VARCHAR(8000) NULL,
  cdm_table_name VARCHAR(255) NULL,
  cdm_field_name VARCHAR(255) NULL,
  concept_id VARCHAR(255) NULL,
  unit_concept_id VARCHAR(255) NULL,
  sql_file VARCHAR(255) NULL,
  category VARCHAR(255) NULL,
  subcategory VARCHAR(255) NULL,
  context VARCHAR(255) NULL,
  warning VARCHAR(255) NULL,
  error VARCHAR(8000) NULL,
  checkid VARCHAR(1024) NULL,
  is_error INTEGER NULL,
  not_applicable INTEGER NULL,
  failed INTEGER NULL,
  passed INTEGER NULL,
  not_applicable_reason VARCHAR(8000) NULL,
  threshold_value INTEGER NULL,
  notes_value VARCHAR(8000) NULL
);
\endif

\if :load_ehrshot
-- EHRSHOT declares CDM v5.3.1. Its source uses extra provenance fields,
-- 64-bit event identifiers, and strings longer than stock CDM varchar limits.
-- Keep standard CDM names lowercase; headers are verified before COPY.
DO $$
DECLARE
  column_record record;
BEGIN
  FOR column_record IN
    SELECT c.relname AS table_name, a.attname AS column_name,
           a.atttypid AS type_oid
    FROM pg_catalog.pg_namespace n
    JOIN pg_catalog.pg_class c ON c.relnamespace = n.oid
    JOIN pg_catalog.pg_attribute a ON a.attrelid = c.oid
    WHERE n.nspname = 'ehrshot' AND c.relkind = 'r'
      AND a.attnum > 0 AND NOT a.attisdropped
      AND a.atttypid IN ('integer'::regtype, 'character varying'::regtype)
    ORDER BY c.relname, a.attnum
  LOOP
    EXECUTE format('ALTER TABLE %I.%I ALTER COLUMN %I TYPE %s',
      'ehrshot', column_record.table_name, column_record.column_name,
      CASE WHEN column_record.type_oid = 'integer'::regtype
           THEN 'BIGINT' ELSE 'TEXT' END);
  END LOOP;
END $$;

-- The export has empty NOTE_TEXT values; retain those rows without replacement.
ALTER TABLE "ehrshot"."note" ALTER COLUMN "note_text" DROP NOT NULL;

ALTER TABLE "ehrshot"."care_site" ADD COLUMN "trace_id" TEXT, ADD COLUMN "unit_id" TEXT, ADD COLUMN "load_table_id" TEXT;
ALTER TABLE "ehrshot"."cdm_source" ADD COLUMN "unit_id" TEXT, ADD COLUMN "load_table_id" TEXT;
ALTER TABLE "ehrshot"."concept" ADD COLUMN "load_table_id" TEXT, ADD COLUMN "load_row_id" TEXT;
ALTER TABLE "ehrshot"."concept_ancestor" ADD COLUMN "load_table_id" TEXT, ADD COLUMN "load_row_id" TEXT;
ALTER TABLE "ehrshot"."concept_class" ADD COLUMN "load_table_id" TEXT, ADD COLUMN "load_row_id" TEXT;
ALTER TABLE "ehrshot"."concept_relationship" ADD COLUMN "load_table_id" TEXT, ADD COLUMN "load_row_id" TEXT;
ALTER TABLE "ehrshot"."concept_synonym" ADD COLUMN "load_table_id" TEXT, ADD COLUMN "load_row_id" TEXT;
ALTER TABLE "ehrshot"."condition_era" ADD COLUMN "trace_id" TEXT, ADD COLUMN "unit_id" TEXT, ADD COLUMN "load_table_id" TEXT;
ALTER TABLE "ehrshot"."condition_occurrence" ADD COLUMN "trace_id" TEXT, ADD COLUMN "unit_id" TEXT, ADD COLUMN "load_table_id" TEXT;
ALTER TABLE "ehrshot"."death" ADD COLUMN "trace_id" TEXT, ADD COLUMN "unit_id" TEXT, ADD COLUMN "load_table_id" TEXT, ADD COLUMN "_death_date_external" TEXT;
ALTER TABLE "ehrshot"."device_exposure" ADD COLUMN "trace_id" TEXT, ADD COLUMN "unit_id" TEXT, ADD COLUMN "load_table_id" TEXT;
ALTER TABLE "ehrshot"."domain" ADD COLUMN "load_table_id" TEXT, ADD COLUMN "load_row_id" TEXT;
ALTER TABLE "ehrshot"."drug_era" ADD COLUMN "trace_id" TEXT, ADD COLUMN "unit_id" TEXT, ADD COLUMN "load_table_id" TEXT;
ALTER TABLE "ehrshot"."drug_exposure" ADD COLUMN "trace_id" TEXT, ADD COLUMN "unit_id" TEXT, ADD COLUMN "load_table_id" TEXT;
ALTER TABLE "ehrshot"."drug_strength" ADD COLUMN "load_table_id" TEXT, ADD COLUMN "load_row_id" TEXT;
ALTER TABLE "ehrshot"."fact_relationship" ADD COLUMN "trace_id" TEXT, ADD COLUMN "unit_id" TEXT, ADD COLUMN "load_table_id" TEXT;
ALTER TABLE "ehrshot"."location" ADD COLUMN "unit_id" TEXT, ADD COLUMN "load_table_id" TEXT;
ALTER TABLE "ehrshot"."measurement" ADD COLUMN "modifier_of_event_id" BIGINT, ADD COLUMN "modifier_of_field_concept_id" BIGINT, ADD COLUMN "trace_id" TEXT, ADD COLUMN "unit_id" TEXT, ADD COLUMN "load_table_id" TEXT;
ALTER TABLE "ehrshot"."metadata" ADD COLUMN "unit_id" TEXT, ADD COLUMN "load_table_id" TEXT;
ALTER TABLE "ehrshot"."note" ADD COLUMN "load_table_id" TEXT;
ALTER TABLE "ehrshot"."observation" ADD COLUMN "trace_id" TEXT, ADD COLUMN "unit_id" TEXT, ADD COLUMN "load_table_id" TEXT;
ALTER TABLE "ehrshot"."observation_period" ADD COLUMN "trace_id" TEXT, ADD COLUMN "unit_id" TEXT, ADD COLUMN "load_table_id" TEXT;
ALTER TABLE "ehrshot"."payer_plan_period" ADD COLUMN "trace_id" TEXT, ADD COLUMN "load_table_id" TEXT;
ALTER TABLE "ehrshot"."person" ADD COLUMN "trace_id" TEXT, ADD COLUMN "unit_id" TEXT, ADD COLUMN "load_table_id" TEXT;
ALTER TABLE "ehrshot"."procedure_occurrence" ADD COLUMN "trace_id" TEXT, ADD COLUMN "unit_id" TEXT, ADD COLUMN "load_table_id" TEXT;
ALTER TABLE "ehrshot"."provider" ADD COLUMN "trace_id" TEXT, ADD COLUMN "unit_id" TEXT, ADD COLUMN "load_table_id" TEXT;
ALTER TABLE "ehrshot"."relationship" ADD COLUMN "load_table_id" TEXT, ADD COLUMN "load_row_id" TEXT;
ALTER TABLE "ehrshot"."visit_detail" ADD COLUMN "trace_id" TEXT, ADD COLUMN "unit_id" TEXT, ADD COLUMN "load_table_id" TEXT;
ALTER TABLE "ehrshot"."visit_occurrence" ADD COLUMN "trace_id" TEXT, ADD COLUMN "unit_id" TEXT, ADD COLUMN "load_table_id" TEXT;
ALTER TABLE "ehrshot"."vocabulary" ADD COLUMN "load_table_id" TEXT, ADD COLUMN "load_row_id" TEXT;

-- files.csv is source provenance, outside the 37 standard CDM tables.
CREATE TABLE "ehrshot"."files" (
  "file_id" TEXT,
  "file_name" TEXT,
  "size" BIGINT,
  "added_at" TEXT,
  "md5_hash" TEXT
);
\endif

-- Verify the final reference-compatible contract before committing the DDL.
\if :load_mimiciv
SELECT (
  (SELECT count(*) FROM information_schema.tables
   WHERE table_schema = 'mimiciv' AND table_type = 'BASE TABLE') = 40
  AND
  (SELECT count(*) FROM information_schema.columns
   WHERE table_schema = 'mimiciv') = 452
  AND
  (SELECT count(*) FROM information_schema.columns
   WHERE table_schema = 'mimiciv' AND is_nullable = 'NO') = 177
  AND
  (SELECT count(*) FROM information_schema.columns
   WHERE table_schema = 'mimiciv' AND data_type = 'bigint') = 60
) AS mimiciv_contract_ok
\gset
\if :mimiciv_contract_ok
\else
  \echo 'ERROR: MIMIC custom DDL did not produce the audited 40/452/177/60 contract.'
  DO $$ BEGIN RAISE EXCEPTION 'load_data.sql DDL validation failed'; END $$;
\endif
\endif

\if :load_synpuf
SELECT (
  (SELECT count(*) FROM information_schema.tables
   WHERE table_schema = 'synpuf' AND table_type = 'BASE TABLE') = 39
  AND
  (SELECT count(*) FROM information_schema.columns
   WHERE table_schema = 'synpuf') = 432
  AND
  (SELECT count(*) FROM information_schema.columns
   WHERE table_schema = 'synpuf' AND is_nullable = 'NO') = 172
  AND
  (SELECT count(*) FROM information_schema.columns
   WHERE table_schema = 'synpuf' AND data_type = 'bigint') = 2
) AS synpuf_contract_ok
\gset
\if :synpuf_contract_ok
\else
  \echo 'ERROR: SynPUF custom DDL did not produce the audited 39/432/172/2 contract.'
  DO $$ BEGIN RAISE EXCEPTION 'load_data.sql DDL validation failed'; END $$;
\endif
\endif

\if :load_ehrshot
SELECT (
  (SELECT count(*) FROM information_schema.tables
   WHERE table_schema = 'ehrshot' AND table_type = 'BASE TABLE') = 38
  AND
  (SELECT count(*) FROM information_schema.columns
   WHERE table_schema = 'ehrshot') = 479
  AND
  (SELECT count(*) FROM information_schema.columns
   WHERE table_schema = 'ehrshot' AND is_nullable = 'NO') = 163
  AND
  (SELECT count(*) FROM information_schema.columns
   WHERE table_schema = 'ehrshot' AND data_type = 'integer') = 0
  AND
  (SELECT count(*) FROM information_schema.columns
   WHERE table_schema = 'ehrshot' AND data_type = 'character varying') = 0
) AS ehrshot_contract_ok
\gset
\if :ehrshot_contract_ok
\else
  \echo 'ERROR: EHRSHOT custom DDL did not produce the 38-table/479-column contract.'
  DO $$ BEGIN RAISE EXCEPTION 'load_data.sql DDL validation failed'; END $$;
\endif
\endif

COMMIT;
\if :load_mimiciv
  \echo 'Loading 40 materialized OMOP MIMIC-IV exports...'

BEGIN;
\copy "mimiciv"."attribute_definition" ("attribute_definition_id","attribute_name","attribute_description","attribute_type_concept_id","attribute_syntax") FROM 'mimiciv/attribute_definition.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."care_site" ("care_site_id","care_site_name","place_of_service_concept_id","location_id","care_site_source_value","place_of_service_source_value") FROM 'mimiciv/care_site.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."cdm_source" ("cdm_source_name","cdm_source_abbreviation","cdm_holder","source_description","source_documentation_reference","cdm_etl_reference","source_release_date","cdm_release_date","cdm_version","vocabulary_version") FROM 'mimiciv/cdm_source.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."cohort_definition" ("cohort_definition_id","cohort_definition_name","cohort_definition_description","definition_type_concept_id","cohort_definition_syntax","subject_concept_id","cohort_initiation_date") FROM 'mimiciv/cohort_definition.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."concept_ancestor" ("ancestor_concept_id","descendant_concept_id","min_levels_of_separation","max_levels_of_separation") FROM 'mimiciv/concept_ancestor.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."concept_class" ("concept_class_id","concept_class_name","concept_class_concept_id") FROM 'mimiciv/concept_class.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."concept" ("concept_id","concept_name","domain_id","vocabulary_id","concept_class_id","standard_concept","concept_code","valid_start_date","valid_end_date","invalid_reason") FROM 'mimiciv/concept.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."concept_relationship" ("concept_id_1","concept_id_2","relationship_id","valid_start_date","valid_end_date","invalid_reason") FROM 'mimiciv/concept_relationship.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."concept_stg" ("concept_id","concept_name","domain_id","vocabulary_id","concept_class_id","standard_concept","concept_code","valid_start_date","valid_end_date","invalid_reason") FROM 'mimiciv/concept_stg.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."concept_synonym" ("concept_id","concept_synonym_name","language_concept_id") FROM 'mimiciv/concept_synonym.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."condition_era" ("condition_era_id","person_id","condition_concept_id","condition_era_start_date","condition_era_end_date","condition_occurrence_count") FROM 'mimiciv/condition_era.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."condition_occurrence" ("condition_occurrence_id","person_id","condition_concept_id","condition_start_date","condition_start_datetime","condition_end_date","condition_end_datetime","condition_type_concept_id","condition_status_concept_id","stop_reason","provider_id","visit_occurrence_id","visit_detail_id","condition_source_value","condition_source_concept_id","condition_status_source_value") FROM 'mimiciv/condition_occurrence.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."cost" ("cost_id","cost_event_id","cost_domain_id","cost_type_concept_id","currency_concept_id","total_charge","total_cost","total_paid","paid_by_payer","paid_by_patient","paid_patient_copay","paid_patient_coinsurance","paid_patient_deductible","paid_by_primary","paid_ingredient_cost","paid_dispensing_fee","payer_plan_period_id","amount_allowed","revenue_code_concept_id","revenue_code_source_value","drg_concept_id","drg_source_value") FROM 'mimiciv/cost.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."death" ("person_id","death_date","death_datetime","death_type_concept_id","cause_concept_id","cause_source_value","cause_source_concept_id") FROM 'mimiciv/death.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."device_exposure" ("device_exposure_id","person_id","device_concept_id","device_exposure_start_date","device_exposure_start_datetime","device_exposure_end_date","device_exposure_end_datetime","device_type_concept_id","unique_device_id","quantity","provider_id","visit_occurrence_id","visit_detail_id","device_source_value","device_source_concept_id") FROM 'mimiciv/device_exposure.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."domain" ("domain_id","domain_name","domain_concept_id") FROM 'mimiciv/domain.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."dose_era" ("dose_era_id","person_id","drug_concept_id","unit_concept_id","dose_value","dose_era_start_date","dose_era_end_date") FROM 'mimiciv/dose_era.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."dqdashboard_results" ("num_violated_rows","pct_violated_rows","num_denominator_rows","execution_time","query_text","check_name","check_level","check_description","cdm_table_name","cdm_field_name","concept_id","unit_concept_id","sql_file","category","subcategory","context","warning","error","checkid","is_error","not_applicable","failed","passed","not_applicable_reason","threshold_value","notes_value") FROM 'mimiciv/dqdashboard_results.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."drug_era" ("drug_era_id","person_id","drug_concept_id","drug_era_start_date","drug_era_end_date","drug_exposure_count","gap_days") FROM 'mimiciv/drug_era.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."drug_exposure" ("drug_exposure_id","person_id","drug_concept_id","drug_exposure_start_date","drug_exposure_start_datetime","drug_exposure_end_date","drug_exposure_end_datetime","verbatim_end_date","drug_type_concept_id","stop_reason","refills","quantity","days_supply","sig","route_concept_id","lot_number","provider_id","visit_occurrence_id","visit_detail_id","drug_source_value","drug_source_concept_id","route_source_value","dose_unit_source_value") FROM 'mimiciv/drug_exposure.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."drug_strength" ("drug_concept_id","ingredient_concept_id","amount_value","amount_unit_concept_id","numerator_value","numerator_unit_concept_id","denominator_value","denominator_unit_concept_id","box_size","valid_start_date","valid_end_date","invalid_reason") FROM 'mimiciv/drug_strength.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."fact_relationship" ("domain_concept_id_1","fact_id_1","domain_concept_id_2","fact_id_2","relationship_concept_id") FROM 'mimiciv/fact_relationship.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."location" ("location_id","address_1","address_2","city","state","zip","county","location_source_value") FROM 'mimiciv/location.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."measurement" ("measurement_id","person_id","measurement_concept_id","measurement_date","measurement_datetime","measurement_time","measurement_type_concept_id","operator_concept_id","value_as_number","value_as_concept_id","unit_concept_id","range_low","range_high","provider_id","visit_occurrence_id","visit_detail_id","measurement_source_value","measurement_source_concept_id","unit_source_value","value_source_value") FROM 'mimiciv/measurement.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."measurement_stg" ("measurement_id","person_id","measurement_concept_id","measurement_date","measurement_datetime","measurement_time","measurement_type_concept_id","operator_concept_id","value_as_number","value_as_concept_id","unit_concept_id","range_low","range_high","provider_id","visit_occurrence_id","visit_detail_id","measurement_source_value","measurement_source_concept_id","unit_source_value","value_source_value") FROM 'mimiciv/measurement_stg.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."metadata" ("metadata_concept_id","metadata_type_concept_id","name","value_as_string","value_as_concept_id","metadata_date","metadata_datetime") FROM 'mimiciv/metadata.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."note" ("note_id","person_id","note_date","note_datetime","note_type_concept_id","note_class_concept_id","note_title","note_text","encoding_concept_id","language_concept_id","provider_id","visit_occurrence_id","visit_detail_id","note_source_value") FROM 'mimiciv/note.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."note_nlp" ("note_nlp_id","note_id","section_concept_id","snippet","offset","lexical_variant","note_nlp_concept_id","note_nlp_source_concept_id","nlp_system","nlp_date","nlp_datetime","term_exists","term_temporal","term_modifiers") FROM 'mimiciv/note_nlp.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."observation" ("observation_id","person_id","observation_concept_id","observation_date","observation_datetime","observation_type_concept_id","value_as_number","value_as_string","value_as_concept_id","qualifier_concept_id","unit_concept_id","provider_id","visit_occurrence_id","visit_detail_id","observation_source_value","observation_source_concept_id","unit_source_value","qualifier_source_value") FROM 'mimiciv/observation.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."observation_period" ("observation_period_id","person_id","observation_period_start_date","observation_period_end_date","period_type_concept_id") FROM 'mimiciv/observation_period.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."payer_plan_period" ("payer_plan_period_id","person_id","payer_plan_period_start_date","payer_plan_period_end_date","payer_concept_id","payer_source_value","payer_source_concept_id","plan_concept_id","plan_source_value","plan_source_concept_id","sponsor_concept_id","sponsor_source_value","sponsor_source_concept_id","family_source_value","stop_reason_concept_id","stop_reason_source_value","stop_reason_source_concept_id") FROM 'mimiciv/payer_plan_period.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."person" ("person_id","gender_concept_id","year_of_birth","month_of_birth","day_of_birth","birth_datetime","race_concept_id","ethnicity_concept_id","location_id","provider_id","care_site_id","person_source_value","gender_source_value","gender_source_concept_id","race_source_value","race_source_concept_id","ethnicity_source_value","ethnicity_source_concept_id") FROM 'mimiciv/person.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."procedure_occurrence" ("procedure_occurrence_id","person_id","procedure_concept_id","procedure_date","procedure_datetime","procedure_type_concept_id","modifier_concept_id","quantity","provider_id","visit_occurrence_id","visit_detail_id","procedure_source_value","procedure_source_concept_id","modifier_source_value") FROM 'mimiciv/procedure_occurrence.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."provider" ("provider_id","provider_name","npi","dea","specialty_concept_id","care_site_id","year_of_birth","gender_concept_id","provider_source_value","specialty_source_value","specialty_source_concept_id","gender_source_value","gender_source_concept_id") FROM 'mimiciv/provider.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."relationship" ("relationship_id","relationship_name","is_hierarchical","defines_ancestry","reverse_relationship_id","relationship_concept_id") FROM 'mimiciv/relationship.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."source_to_concept_map" ("source_code","source_concept_id","source_vocabulary_id","source_code_description","target_concept_id","target_vocabulary_id","valid_start_date","valid_end_date","invalid_reason") FROM 'mimiciv/source_to_concept_map.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."specimen" ("specimen_id","person_id","specimen_concept_id","specimen_type_concept_id","specimen_date","specimen_datetime","quantity","unit_concept_id","anatomic_site_concept_id","disease_status_concept_id","specimen_source_id","specimen_source_value","unit_source_value","anatomic_site_source_value","disease_status_source_value") FROM 'mimiciv/specimen.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."visit_detail" ("visit_detail_id","person_id","visit_detail_concept_id","visit_detail_start_date","visit_detail_start_datetime","visit_detail_end_date","visit_detail_end_datetime","visit_detail_type_concept_id","provider_id","care_site_id","visit_detail_source_value","visit_detail_source_concept_id","admitting_source_value","admitting_source_concept_id","discharge_to_source_value","discharge_to_concept_id","preceding_visit_detail_id","visit_detail_parent_id","visit_occurrence_id") FROM 'mimiciv/visit_detail.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."visit_occurrence" ("visit_occurrence_id","person_id","visit_concept_id","visit_start_date","visit_start_datetime","visit_end_date","visit_end_datetime","visit_type_concept_id","provider_id","care_site_id","visit_source_value","visit_source_concept_id","admitting_source_concept_id","admitting_source_value","discharge_to_concept_id","discharge_to_source_value","preceding_visit_occurrence_id") FROM 'mimiciv/visit_occurrence.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "mimiciv"."vocabulary" ("vocabulary_id","vocabulary_name","vocabulary_reference","vocabulary_version","vocabulary_concept_id") FROM 'mimiciv/vocabulary.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;
\endif

\if :load_synpuf
  \echo 'Loading 39 materialized OMOP SynPUF23 exports into local schema synpuf...'

BEGIN;
\copy "synpuf"."attribute_definition" ("attribute_definition_id","attribute_name","attribute_description","attribute_type_concept_id","attribute_syntax") FROM 'synpuf23/attribute_definition.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."care_site" ("care_site_id","care_site_name","place_of_service_concept_id","location_id","care_site_source_value","place_of_service_source_value") FROM 'synpuf23/care_site.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."cdm_source" ("cdm_source_name","cdm_source_abbreviation","cdm_holder","source_description","source_documentation_reference","cdm_etl_reference","source_release_date","cdm_release_date","cdm_version","vocabulary_version") FROM 'synpuf23/cdm_source.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."cohort_definition" ("cohort_definition_id","cohort_definition_name","cohort_definition_description","definition_type_concept_id","cohort_definition_syntax","subject_concept_id","cohort_initiation_date") FROM 'synpuf23/cohort_definition.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."concept_ancestor" ("ancestor_concept_id","descendant_concept_id","min_levels_of_separation","max_levels_of_separation") FROM 'synpuf23/concept_ancestor.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."concept_class" ("concept_class_id","concept_class_name","concept_class_concept_id") FROM 'synpuf23/concept_class.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."concept" ("concept_id","concept_name","domain_id","vocabulary_id","concept_class_id","standard_concept","concept_code","valid_start_date","valid_end_date","invalid_reason") FROM 'synpuf23/concept.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."concept_relationship" ("concept_id_1","concept_id_2","relationship_id","valid_start_date","valid_end_date","invalid_reason") FROM 'synpuf23/concept_relationship.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."concept_stg" ("concept_id","concept_name","domain_id","vocabulary_id","concept_class_id","standard_concept","concept_code","valid_start_date","valid_end_date","invalid_reason") FROM 'synpuf23/concept_stg.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."concept_synonym" ("concept_id","concept_synonym_name","language_concept_id") FROM 'synpuf23/concept_synonym.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."condition_era" ("condition_era_id","person_id","condition_concept_id","condition_era_start_date","condition_era_end_date","condition_occurrence_count") FROM 'synpuf23/condition_era.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."condition_occurrence" ("condition_occurrence_id","person_id","condition_concept_id","condition_start_date","condition_start_datetime","condition_end_date","condition_end_datetime","condition_type_concept_id","condition_status_concept_id","stop_reason","provider_id","visit_occurrence_id","visit_detail_id","condition_source_value","condition_source_concept_id","condition_status_source_value") FROM 'synpuf23/condition_occurrence.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."cost" ("cost_id","cost_event_id","cost_domain_id","cost_type_concept_id","currency_concept_id","total_charge","total_cost","total_paid","paid_by_payer","paid_by_patient","paid_patient_copay","paid_patient_coinsurance","paid_patient_deductible","paid_by_primary","paid_ingredient_cost","paid_dispensing_fee","payer_plan_period_id","amount_allowed","revenue_code_concept_id","revenue_code_source_value","drg_concept_id","drg_source_value") FROM 'synpuf23/cost.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."death" ("person_id","death_date","death_datetime","death_type_concept_id","cause_concept_id","cause_source_value","cause_source_concept_id") FROM 'synpuf23/death.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."device_exposure" ("device_exposure_id","person_id","device_concept_id","device_exposure_start_date","device_exposure_start_datetime","device_exposure_end_date","device_exposure_end_datetime","device_type_concept_id","unique_device_id","quantity","provider_id","visit_occurrence_id","visit_detail_id","device_source_value","device_source_concept_id") FROM 'synpuf23/device_exposure.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."domain" ("domain_id","domain_name","domain_concept_id") FROM 'synpuf23/domain.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."dose_era" ("dose_era_id","person_id","drug_concept_id","unit_concept_id","dose_value","dose_era_start_date","dose_era_end_date") FROM 'synpuf23/dose_era.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."dqdashboard_results" ("num_violated_rows","pct_violated_rows","num_denominator_rows","execution_time","query_text","check_name","check_level","check_description","cdm_table_name","cdm_field_name","concept_id","unit_concept_id","sql_file","category","subcategory","context","warning","error","checkid","is_error","not_applicable","failed","passed","not_applicable_reason","threshold_value","notes_value") FROM 'synpuf23/dqdashboard_results.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."drug_era" ("drug_era_id","person_id","drug_concept_id","drug_era_start_date","drug_era_end_date","drug_exposure_count","gap_days") FROM 'synpuf23/drug_era.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."drug_exposure" ("drug_exposure_id","person_id","drug_concept_id","drug_exposure_start_date","drug_exposure_start_datetime","drug_exposure_end_date","drug_exposure_end_datetime","verbatim_end_date","drug_type_concept_id","stop_reason","refills","quantity","days_supply","sig","route_concept_id","lot_number","provider_id","visit_occurrence_id","visit_detail_id","drug_source_value","drug_source_concept_id","route_source_value","dose_unit_source_value") FROM 'synpuf23/drug_exposure.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."drug_strength" ("drug_concept_id","ingredient_concept_id","amount_value","amount_unit_concept_id","numerator_value","numerator_unit_concept_id","denominator_value","denominator_unit_concept_id","box_size","valid_start_date","valid_end_date","invalid_reason") FROM 'synpuf23/drug_strength.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."fact_relationship" ("domain_concept_id_1","fact_id_1","domain_concept_id_2","fact_id_2","relationship_concept_id") FROM 'synpuf23/fact_relationship.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."location" ("location_id","address_1","address_2","city","state","zip","county","location_source_value") FROM 'synpuf23/location.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."measurement" ("measurement_id","person_id","measurement_concept_id","measurement_date","measurement_datetime","measurement_time","measurement_type_concept_id","operator_concept_id","value_as_number","value_as_concept_id","unit_concept_id","range_low","range_high","provider_id","visit_occurrence_id","visit_detail_id","measurement_source_value","measurement_source_concept_id","unit_source_value","value_source_value") FROM 'synpuf23/measurement.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."metadata" ("metadata_concept_id","metadata_type_concept_id","name","value_as_string","value_as_concept_id","metadata_date","metadata_datetime") FROM 'synpuf23/metadata.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."note" ("note_id","person_id","note_date","note_datetime","note_type_concept_id","note_class_concept_id","note_title","note_text","encoding_concept_id","language_concept_id","provider_id","visit_occurrence_id","visit_detail_id","note_source_value") FROM 'synpuf23/note.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."note_nlp" ("note_nlp_id","note_id","section_concept_id","snippet","offset","lexical_variant","note_nlp_concept_id","note_nlp_source_concept_id","nlp_system","nlp_date","nlp_datetime","term_exists","term_temporal","term_modifiers") FROM 'synpuf23/note_nlp.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."observation" ("observation_id","person_id","observation_concept_id","observation_date","observation_datetime","observation_type_concept_id","value_as_number","value_as_string","value_as_concept_id","qualifier_concept_id","unit_concept_id","provider_id","visit_occurrence_id","visit_detail_id","observation_source_value","observation_source_concept_id","unit_source_value","qualifier_source_value") FROM 'synpuf23/observation.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."observation_period" ("observation_period_id","person_id","observation_period_start_date","observation_period_end_date","period_type_concept_id") FROM 'synpuf23/observation_period.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."payer_plan_period" ("payer_plan_period_id","person_id","payer_plan_period_start_date","payer_plan_period_end_date","payer_concept_id","payer_source_value","payer_source_concept_id","plan_concept_id","plan_source_value","plan_source_concept_id","sponsor_concept_id","sponsor_source_value","sponsor_source_concept_id","family_source_value","stop_reason_concept_id","stop_reason_source_value","stop_reason_source_concept_id") FROM 'synpuf23/payer_plan_period.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."person" ("person_id","gender_concept_id","year_of_birth","month_of_birth","day_of_birth","birth_datetime","race_concept_id","ethnicity_concept_id","location_id","provider_id","care_site_id","person_source_value","gender_source_value","gender_source_concept_id","race_source_value","race_source_concept_id","ethnicity_source_value","ethnicity_source_concept_id") FROM 'synpuf23/person.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."procedure_occurrence" ("procedure_occurrence_id","person_id","procedure_concept_id","procedure_date","procedure_datetime","procedure_type_concept_id","modifier_concept_id","quantity","provider_id","visit_occurrence_id","visit_detail_id","procedure_source_value","procedure_source_concept_id","modifier_source_value") FROM 'synpuf23/procedure_occurrence.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."provider" ("provider_id","provider_name","npi","dea","specialty_concept_id","care_site_id","year_of_birth","gender_concept_id","provider_source_value","specialty_source_value","specialty_source_concept_id","gender_source_value","gender_source_concept_id") FROM 'synpuf23/provider.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."relationship" ("relationship_id","relationship_name","is_hierarchical","defines_ancestry","reverse_relationship_id","relationship_concept_id") FROM 'synpuf23/relationship.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."source_to_concept_map" ("source_code","source_concept_id","source_vocabulary_id","source_code_description","target_concept_id","target_vocabulary_id","valid_start_date","valid_end_date","invalid_reason") FROM 'synpuf23/source_to_concept_map.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."specimen" ("specimen_id","person_id","specimen_concept_id","specimen_type_concept_id","specimen_date","specimen_datetime","quantity","unit_concept_id","anatomic_site_concept_id","disease_status_concept_id","specimen_source_id","specimen_source_value","unit_source_value","anatomic_site_source_value","disease_status_source_value") FROM 'synpuf23/specimen.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."visit_detail" ("visit_detail_id","person_id","visit_detail_concept_id","visit_detail_start_date","visit_detail_start_datetime","visit_detail_end_date","visit_detail_end_datetime","visit_detail_type_concept_id","provider_id","care_site_id","visit_detail_source_value","visit_detail_source_concept_id","admitting_source_value","admitting_source_concept_id","discharge_to_source_value","discharge_to_concept_id","preceding_visit_detail_id","visit_detail_parent_id","visit_occurrence_id") FROM 'synpuf23/visit_detail.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."visit_occurrence" ("visit_occurrence_id","person_id","visit_concept_id","visit_start_date","visit_start_datetime","visit_end_date","visit_end_datetime","visit_type_concept_id","provider_id","care_site_id","visit_source_value","visit_source_concept_id","admitting_source_concept_id","admitting_source_value","discharge_to_concept_id","discharge_to_source_value","preceding_visit_occurrence_id") FROM 'synpuf23/visit_occurrence.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "synpuf"."vocabulary" ("vocabulary_id","vocabulary_name","vocabulary_reference","vocabulary_version","vocabulary_concept_id") FROM 'synpuf23/vocabulary.csv' WITH (FORMAT csv, HEADER MATCH, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;
\endif

\if :load_ehrshot
  \echo 'Loading 31 EHRSHOT exports into local schema ehrshot...'

BEGIN;
\copy "ehrshot"."care_site" ("care_site_id","care_site_name","place_of_service_concept_id","location_id","care_site_source_value","place_of_service_source_value","trace_id","unit_id","load_table_id") FROM 'ehrshot/care_site.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "ehrshot"."cdm_source" ("cdm_source_name","cdm_source_abbreviation","cdm_holder","source_description","source_documentation_reference","cdm_etl_reference","source_release_date","cdm_release_date","cdm_version","vocabulary_version","unit_id","load_table_id") FROM 'ehrshot/cdm_source.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "ehrshot"."concept" ("concept_id","concept_name","domain_id","vocabulary_id","concept_class_id","standard_concept","concept_code","valid_start_date","valid_end_date","invalid_reason","load_table_id","load_row_id") FROM 'ehrshot/concept.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "ehrshot"."concept_ancestor" ("ancestor_concept_id","descendant_concept_id","min_levels_of_separation","max_levels_of_separation","load_table_id","load_row_id") FROM 'ehrshot/concept_ancestor.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "ehrshot"."concept_class" ("concept_class_id","concept_class_name","concept_class_concept_id","load_table_id","load_row_id") FROM 'ehrshot/concept_class.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "ehrshot"."concept_relationship" ("concept_id_1","concept_id_2","relationship_id","valid_start_date","valid_end_date","invalid_reason","load_table_id","load_row_id") FROM 'ehrshot/concept_relationship.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "ehrshot"."concept_synonym" ("concept_id","concept_synonym_name","language_concept_id","load_table_id","load_row_id") FROM 'ehrshot/concept_synonym.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "ehrshot"."condition_era" ("condition_era_id","person_id","condition_concept_id","condition_era_start_date","condition_era_end_date","condition_occurrence_count","trace_id","unit_id","load_table_id") FROM 'ehrshot/condition_era.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "ehrshot"."condition_occurrence" ("condition_occurrence_id","person_id","condition_concept_id","condition_start_date","condition_start_datetime","condition_end_date","condition_end_datetime","condition_type_concept_id","stop_reason","provider_id","visit_occurrence_id","visit_detail_id","condition_source_value","condition_source_concept_id","condition_status_source_value","condition_status_concept_id","trace_id","unit_id","load_table_id") FROM 'ehrshot/condition_occurrence.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "ehrshot"."death" ("person_id","death_date","death_datetime","death_type_concept_id","cause_concept_id","cause_source_value","cause_source_concept_id","trace_id","unit_id","load_table_id","_death_date_external") FROM 'ehrshot/death.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "ehrshot"."device_exposure" ("device_exposure_id","person_id","device_concept_id","device_exposure_start_date","device_exposure_start_datetime","device_exposure_end_date","device_exposure_end_datetime","device_type_concept_id","unique_device_id","quantity","provider_id","visit_occurrence_id","visit_detail_id","device_source_value","device_source_concept_id","trace_id","unit_id","load_table_id") FROM 'ehrshot/device_exposure.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "ehrshot"."domain" ("domain_id","domain_name","domain_concept_id","load_table_id","load_row_id") FROM 'ehrshot/domain.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "ehrshot"."drug_era" ("drug_era_id","person_id","drug_concept_id","drug_era_start_date","drug_era_end_date","drug_exposure_count","gap_days","trace_id","unit_id","load_table_id") FROM 'ehrshot/drug_era.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "ehrshot"."drug_exposure" ("drug_exposure_id","person_id","drug_concept_id","drug_exposure_start_date","drug_exposure_start_datetime","drug_exposure_end_date","drug_exposure_end_datetime","verbatim_end_date","drug_type_concept_id","stop_reason","refills","quantity","days_supply","route_concept_id","lot_number","provider_id","visit_occurrence_id","visit_detail_id","drug_source_value","drug_source_concept_id","route_source_value","dose_unit_source_value","trace_id","unit_id","load_table_id","sig") FROM 'ehrshot/drug_exposure.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "ehrshot"."drug_strength" ("drug_concept_id","ingredient_concept_id","amount_value","amount_unit_concept_id","numerator_value","numerator_unit_concept_id","denominator_value","denominator_unit_concept_id","box_size","valid_start_date","valid_end_date","invalid_reason","load_table_id","load_row_id") FROM 'ehrshot/drug_strength.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "ehrshot"."fact_relationship" ("domain_concept_id_1","fact_id_1","domain_concept_id_2","fact_id_2","relationship_concept_id","trace_id","unit_id","load_table_id") FROM 'ehrshot/fact_relationship.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "ehrshot"."files" ("file_id","file_name","size","added_at","md5_hash") FROM 'ehrshot/files.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "ehrshot"."location" ("location_id","address_1","address_2","city","state","zip","county","location_source_value","unit_id","load_table_id") FROM 'ehrshot/location.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "ehrshot"."measurement" ("measurement_id","person_id","measurement_concept_id","measurement_date","measurement_datetime","measurement_time","measurement_type_concept_id","operator_concept_id","value_as_number","value_as_concept_id","unit_concept_id","range_low","range_high","provider_id","visit_occurrence_id","visit_detail_id","measurement_source_value","measurement_source_concept_id","unit_source_value","modifier_of_event_id","modifier_of_field_concept_id","trace_id","unit_id","load_table_id","value_source_value") FROM 'ehrshot/measurement.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "ehrshot"."metadata" ("metadata_concept_id","metadata_type_concept_id","name","value_as_string","value_as_concept_id","metadata_date","metadata_datetime","unit_id","load_table_id") FROM 'ehrshot/metadata.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "ehrshot"."note" ("note_id","person_id","note_date","note_datetime","note_type_concept_id","note_class_concept_id","note_title","encoding_concept_id","language_concept_id","provider_id","visit_occurrence_id","visit_detail_id","note_source_value","load_table_id","note_text") FROM 'ehrshot/note.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "ehrshot"."observation" ("observation_id","person_id","observation_concept_id","observation_date","observation_datetime","observation_type_concept_id","value_as_number","value_as_concept_id","qualifier_concept_id","unit_concept_id","provider_id","visit_occurrence_id","visit_detail_id","observation_source_concept_id","unit_source_value","qualifier_source_value","trace_id","unit_id","load_table_id","value_as_string","observation_source_value") FROM 'ehrshot/observation.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "ehrshot"."observation_period" ("observation_period_id","person_id","observation_period_start_date","observation_period_end_date","period_type_concept_id","trace_id","unit_id","load_table_id") FROM 'ehrshot/observation_period.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "ehrshot"."payer_plan_period" ("payer_plan_period_id","person_id","payer_plan_period_start_date","payer_plan_period_end_date","payer_concept_id","payer_source_value","payer_source_concept_id","plan_concept_id","plan_source_value","plan_source_concept_id","sponsor_concept_id","sponsor_source_value","sponsor_source_concept_id","family_source_value","stop_reason_concept_id","stop_reason_source_value","stop_reason_source_concept_id","trace_id","load_table_id") FROM 'ehrshot/payer_plan_period.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "ehrshot"."person" ("person_id","gender_concept_id","year_of_birth","month_of_birth","day_of_birth","birth_datetime","race_concept_id","ethnicity_concept_id","location_id","provider_id","care_site_id","person_source_value","gender_source_value","gender_source_concept_id","race_source_value","race_source_concept_id","ethnicity_source_value","ethnicity_source_concept_id","trace_id","unit_id","load_table_id") FROM 'ehrshot/person.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "ehrshot"."procedure_occurrence" ("procedure_occurrence_id","person_id","procedure_concept_id","procedure_date","procedure_datetime","procedure_type_concept_id","modifier_concept_id","quantity","provider_id","visit_occurrence_id","visit_detail_id","procedure_source_value","procedure_source_concept_id","modifier_source_value","trace_id","unit_id","load_table_id") FROM 'ehrshot/procedure_occurrence.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "ehrshot"."provider" ("provider_id","provider_name","npi","dea","specialty_concept_id","care_site_id","year_of_birth","gender_concept_id","provider_source_value","specialty_source_value","specialty_source_concept_id","gender_source_value","gender_source_concept_id","trace_id","unit_id","load_table_id") FROM 'ehrshot/provider.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "ehrshot"."relationship" ("relationship_id","relationship_name","is_hierarchical","defines_ancestry","reverse_relationship_id","relationship_concept_id","load_table_id","load_row_id") FROM 'ehrshot/relationship.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "ehrshot"."visit_detail" ("visit_detail_id","person_id","visit_detail_concept_id","visit_detail_start_date","visit_detail_start_datetime","visit_detail_end_date","visit_detail_end_datetime","visit_detail_type_concept_id","provider_id","care_site_id","admitting_source_concept_id","discharge_to_concept_id","preceding_visit_detail_id","visit_detail_source_value","visit_detail_source_concept_id","admitting_source_value","visit_occurrence_id","trace_id","unit_id","load_table_id") FROM 'ehrshot/visit_detail.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "ehrshot"."visit_occurrence" ("visit_occurrence_id","person_id","visit_concept_id","visit_start_date","visit_start_datetime","visit_end_date","visit_end_datetime","visit_type_concept_id","provider_id","care_site_id","visit_source_value","visit_source_concept_id","admitting_source_concept_id","admitting_source_value","discharge_to_concept_id","discharge_to_source_value","preceding_visit_occurrence_id","trace_id","unit_id","load_table_id") FROM 'ehrshot/visit_occurrence.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

BEGIN;
\copy "ehrshot"."vocabulary" ("vocabulary_id","vocabulary_name","vocabulary_reference","vocabulary_version","vocabulary_concept_id","load_table_id","load_row_id") FROM 'ehrshot/vocabulary.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8')
COMMIT;

SELECT EXISTS (SELECT 1 FROM "ehrshot"."cdm_source" WHERE "cdm_version" = 'v5.3.1') AS ehrshot_version_ok
\gset
\if :ehrshot_version_ok
\else
  \echo 'ERROR: EHRSHOT cdm_source did not declare v5.3.1.'
  DO $$ BEGIN RAISE EXCEPTION 'EHRSHOT CDM version validation failed'; END $$;
\endif
\endif

\if :analyze_after_load
  \echo 'Updating PostgreSQL planner statistics...'
  \if :load_mimiciv
SELECT format('ANALYZE %I.%I;', schemaname, tablename)
FROM pg_catalog.pg_tables
WHERE schemaname = 'mimiciv'
ORDER BY tablename
\gexec
  \endif
  \if :load_synpuf
SELECT format('ANALYZE %I.%I;', schemaname, tablename)
FROM pg_catalog.pg_tables
WHERE schemaname = 'synpuf'
ORDER BY tablename
\gexec
  \endif
  \if :load_ehrshot
SELECT format('ANALYZE %I.%I;', schemaname, tablename)
FROM pg_catalog.pg_tables
WHERE schemaname = 'ehrshot'
ORDER BY tablename
\gexec
  \endif
\endif

RESET synchronous_commit;
\echo 'Load completed successfully.'
