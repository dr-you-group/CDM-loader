# Local OMOP MIMIC-IV and SynPUF23 loader

This directory provides the requested local PostgreSQL flow:

1. `download_gcp.sh` downloads the materialized OMOP exports.
2. `create_cdm_schemas.R` uses `CommonDataModel::executeDdl()` to create the
   standard CDM 5.3 base tables.
3. `load_data.sql` applies the reference-specific type changes and loads every
   CSV with explicit ordered columns.

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

The two CSV sets alone occupy about 288.33 GiB. PostgreSQL heap storage and WAL
need substantial additional space; indexes, if added later, need more again.
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
./download_gcp.sh --dest "$PWD/data" --only all --dry-run
```

The script uses `gsutil -m rsync -r`, so an interrupted download can resume. It
does not use rsync's delete option. After downloading, it verifies the exact
file counts and compares every CSV header with its ordered column manifest.

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

`CommonDataModel::executeDdl()` expects the PostgreSQL schemas to exist. Create
both in the empty local database:

```bash
psql -X -v ON_ERROR_STOP=1 \
  -c 'CREATE SCHEMA mimiciv; CREATE SCHEMA synpuf;'
```

Then run the intentionally minimal R script:

```bash
Rscript create_cdm_schemas.R
```

The script follows the OHDSI pattern directly:

- creates one `DatabaseConnector` connection-details object from `PG*` values;
- prints `CommonDataModel::listSupportedVersions()`;
- calls `CommonDataModel::executeDdl(cdmVersion = "5.3")` for `mimiciv` and
  `synpuf`;
- disables primary and foreign keys because the bulk-load order is not
  foreign-key safe.

At this point each schema must be the untouched CDM base: 37 tables, 396
columns, 164 `NOT NULL` columns, no `BIGINT` columns, and no primary/foreign-key
constraints. `load_data.sql` checks this before changing anything.

The CommonDataModel API version is `"5.3"`, not `"5.3.1"`. OHDSI's original
v5.3.1 PostgreSQL file contained the invalid SQL Server type `DATETIME2`; the
v5.3.2 maintenance release fixed that PostgreSQL DDL while retaining the CDM
5.3 model.

## 4. Apply type changes and load the exports

Run `load_data.sql` with psql because it contains psql meta-commands:

```bash
psql -X \
  -v ON_ERROR_STOP=1 \
  -v data_dir="$PWD/data" \
  -f load_data.sql
```

Both datasets and a final `ANALYZE` are enabled by default. For a MIMIC-only
download:

```bash
psql -X \
  -v ON_ERROR_STOP=1 \
  -v data_dir="$PWD/data" \
  -v load_mimiciv=true \
  -v load_synpuf=false \
  -v analyze_after_load=true \
  -f load_data.sql
```
