#!/usr/bin/env Rscript

# Install once if needed:
# install.packages("devtools")
# devtools::install_github("OHDSI/DatabaseConnector", ref = "v7.2.0")
# devtools::install_github("OHDSI/CommonDataModel", ref = "v1.0.1")

driverPath <- Sys.getenv("DATABASECONNECTOR_JAR_FOLDER", unset = "jdbc")

cd <- DatabaseConnector::createConnectionDetails(
  dbms = "postgresql",
  server = paste(
    Sys.getenv("PGHOST", unset = "localhost"),
    Sys.getenv("PGDATABASE", unset = "ohdsi"),
    sep = "/"
  ),
  user = Sys.getenv("PGUSER", unset = "postgres"),
  port = as.integer(Sys.getenv("PGPORT", unset = "5432")),
  password = Sys.getenv("PGPASSWORD", unset = ""),
  pathToDriver = driverPath
)

CommonDataModel::listSupportedVersions()

schemas <- commandArgs(trailingOnly = TRUE)
if (length(schemas) == 0L) schemas <- c("mimiciv", "synpuf", "ehrshot")
if (any(!schemas %in% c("mimiciv", "synpuf", "ehrshot"))) {
  stop("Schemas must be mimiciv, synpuf, or ehrshot")
}

for (schema in unique(schemas)) {
  CommonDataModel::executeDdl(
    connectionDetails = cd,
    cdmVersion = "5.3",
    cdmDatabaseSchema = schema,
    executePrimaryKey = FALSE,
    executeForeignKey = FALSE
  )
}
