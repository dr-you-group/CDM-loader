# Local OMOP MIMIC-IV, SynPUF23, and EHRSHOT loader

This directory provides the requested local PostgreSQL flow:

1. `download_gcp.sh` downloads the materialized OMOP exports.
2. `create_cdm_schemas.R` uses `CommonDataModel::executeDdl()` to create the
   standard CDM 5.3 base tables.
3. `load_data.sql` applies export-specific type changes and loads every CSV
   with explicit ordered columns.

No database password is stored in these files. The R and psql processes use the
standard `PG*` environment variables.

## Prerequisites

- Google Cloud CLI with `gsutil`
- Local PostgreSQL and `psql` 16 or newer.
- R and Java, required by OHDSI DatabaseConnector.
- R packages `DatabaseConnector` and `CommonDataModel`.

Install the OHDSI packages once:

```r
install.packages("devtools")
devtools::install_github("OHDSI/DatabaseConnector", ref = "v7.2.0")
devtools::install_github("OHDSI/CommonDataModel", ref = "v1.0.1")
```

MIMIC-IV and SynPUF23 CSVs occupy about 288.33 GiB. EHRSHOT adds 31 CSVs
(16.62 GiB) and `Files_files.zip` (4.62 GiB), so the default download is about
309.6 GiB. PostgreSQL heap storage and WAL need substantial additional space.
Check both the download filesystem and PostgreSQL data volume before starting.

## 1. Download from GCS

From this directory:

```bash
chmod +x download_gcp.sh
./download_gcp.sh --dest "$PWD/data" --only all
```

Partial downloads and a dry run are supported:

```bash
./download_gcp.sh --dest "$PWD/data" --only mimiciv
./download_gcp.sh --dest "$PWD/data" --only synpuf
./download_gcp.sh --dest "$PWD/data" --only ehrshot
./download_gcp.sh --dest "$PWD/data" --only all --dry-run
```

The script uses `gsutil -m rsync -r`, so an interrupted download can resume. It
does not use rsync's delete option. After downloading, it verifies the exact
file counts and CSV column order. The bucket has separate manifests for
MIMIC-IV and SynPUF23; EHRSHOT's 31 checked headers are recorded in
`ehrshot_headers.tsv`. Its ZIP is retained locally for the source `files.csv`
records but is not inserted into PostgreSQL.

## 2. Configure local PostgreSQL and JDBC

Create or choose an empty local database, then set the local connection. Do not
put the password in an R or SQL file:

```bash
export PGHOST=127.0.0.1
export PGPORT=5432
export PGDATABASE=ohdsi
export PGUSER=postgres
read -rsp 'Local PostgreSQL password: ' PGPASSWORD; export PGPASSWORD; echo

export DATABASECONNECTOR_JAR_FOLDER="$PWD/jdbc"
mkdir -p "$DATABASECONNECTOR_JAR_FOLDER"
```

Download the PostgreSQL JDBC driver once:

```bash
Rscript -e 'DatabaseConnector::downloadJdbcDrivers(
  "postgresql",
  pathToDriver = Sys.getenv("DATABASECONNECTOR_JAR_FOLDER")
)'
```

These variables must describe the local PostgreSQL instance, not the reference
server.

## 3. Create empty schemas and standard CDM tables

`CommonDataModel::executeDdl()` expects the PostgreSQL schemas to exist. For a
fresh load of all three datasets, create them in an empty local database:

```bash
psql -X -v ON_ERROR_STOP=1 \
  -c 'CREATE SCHEMA mimiciv; CREATE SCHEMA synpuf; CREATE SCHEMA ehrshot;'
```

Then run the intentionally minimal R script:

```bash
Rscript create_cdm_schemas.R
```

The script follows the OHDSI pattern directly:

- creates one `DatabaseConnector` connection-details object from `PG*` values;
- prints `CommonDataModel::listSupportedVersions()`;
- calls `CommonDataModel::executeDdl(cdmVersion = "5.3")` for `mimiciv`,
  `synpuf`, and `ehrshot`;
- disables primary and foreign keys because the bulk-load order is not
  foreign-key safe.

At this point each schema must be the untouched CDM base: 37 tables, 396
columns, 164 `NOT NULL` columns, no `BIGINT` columns, and no primary/foreign-key
constraints. `load_data.sql` checks this before changing anything.

EHRSHOT's `cdm_source.csv` declares `v5.3.1`. The CommonDataModel API version
for that model is `"5.3"`: OHDSI treats 5.3.1 and later 5.3.x releases as
maintenance revisions of CDM 5.3. The v5.3.2 release fixed the PostgreSQL DDL
without changing the model.

To add EHRSHOT to a database that already has loaded MIMIC-IV and SynPUF23,
create only its new schema and run the same minimal R entry point with one
schema argument:

```bash
psql -X -v ON_ERROR_STOP=1 -c 'CREATE SCHEMA ehrshot;'
Rscript create_cdm_schemas.R ehrshot
```

## 4. Apply type changes and load the exports

Run `load_data.sql` with psql because it contains psql meta-commands:

```bash
psql -X \
  -v ON_ERROR_STOP=1 \
  -v data_dir="$PWD/data" \
  -f load_data.sql
```

All three datasets and a final `ANALYZE` are enabled by default. For a
MIMIC-only download:

```bash
psql -X \
  -v ON_ERROR_STOP=1 \
  -v data_dir="$PWD/data" \
  -v load_mimiciv=true \
  -v load_synpuf=false \
  -v load_ehrshot=false \
  -v analyze_after_load=true \
  -f load_data.sql
```

For an EHRSHOT-only download, including when adding it to an existing local
database:

```bash
psql -X \
  -v ON_ERROR_STOP=1 \
  -v data_dir="$PWD/data" \
  -v load_mimiciv=false \
  -v load_synpuf=false \
  -v load_ehrshot=true \
  -f load_data.sql
```

EHRSHOT uses 30 CDM tables plus a source `files` table. Its CSV headers have
uppercase `DATE`/`DATETIME` suffixes and extra provenance fields. The download
script checks their exact order; SQL retains standard lowercase CDM column
names, adds 78 export-specific fields, and uses positional `COPY HEADER true`.
For this source, SQL widens stock integer columns to `BIGINT` and stock
`varchar` columns to `TEXT` before loading. The EHRSHOT export has empty
`note_text` values, so SQL drops that one stock `NOT NULL` constraint and
preserves those rows unchanged. Its final schema has 38 tables, 479 columns,
163 `NOT NULL` columns, and 202 `BIGINT` columns. The loader requires an
untouched, empty CDM schema and rejects a rerun into a populated schema.

The EHRSHOT path was checked against the live bucket headers and its declared
`v5.3.1` value. A local PostgreSQL 16 smoke run used the pinned OHDSI CDM 5.3
DDL and up to ten actual rows per CSV (285 rows across all 31 files); all
copies and `ANALYZE` completed. The full 16.62 GiB EHRSHOT CSV set has not
been downloaded or loaded in this workspace.
