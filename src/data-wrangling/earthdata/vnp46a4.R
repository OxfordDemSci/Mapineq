# cleanup
rm(list = ls()); gc(); cat("\014"); try(dev.off(), silent = T); options(scipen = 999)

# libraries
if ("ncdf4" %in% rownames(installed.packages()) == FALSE) {install.packages("ncdf4")}
if ("reshape2" %in% rownames(installed.packages()) == FALSE) {install.packages("reshape2")}
if ("dplyr" %in% rownames(installed.packages()) == FALSE) {install.packages("dplyr")}
if ("rstudioapi" %in% rownames(installed.packages()) == FALSE) {install.packages("rstudioapi")}
if ("DBI" %in% rownames(installed.packages()) == FALSE) {install.packages("DBI")}
if ("RPostgres" %in% rownames(installed.packages()) == FALSE) {install.packages("RPostgres")}
if ("dbplyr" %in% rownames(installed.packages()) == FALSE) {install.packages("dbplyr")}

library(ncdf4)
library(reshape2)
library(dplyr)
library(rstudioapi)
library(DBI)
library(RPostgres)


setwd(file.path(dirname(rstudioapi::getSourceEditorContext()$path), "..", "..", ".."))
srcdir <- file.path('src', 'data-wrangling', 'earthdata')
outdir <- file.path('out', 'earthdata', 'nighttime_lights', 'data')
source(file.path(srcdir, 'functions.R'))


POSTGRES_HOST <- Sys.getenv("POSTGRES_HOST", 'localhost')
POSTGRES_DB <- Sys.getenv("POSTGRES_DB", 'mapineq_local')
POSTGRES_USER <- Sys.getenv("POSTGRES_USER", 'postgres')
POSTGRES_RPASS <- Sys.getenv("POSTGRES_RPASS", 'password')
POSTGRES_PORT <- Sys.getenv("POSTGRES_PORT", '5432')

angles <- list('AllAngle', 'NearNadir', 'OffNadir')
snow_conditions <- list(TRUE, FALSE)

h5_files <- list.files(path = outdir, pattern = "\\.h5$", full.names = TRUE)


cols <- c('composite', 'num', 'quality', 'std', 'snow', 'angle', 'year', 'platform', 'mask', 'geom')


query <- sprintf(
  "INSERT INTO earthdata_vnp46a4(%s)
    SELECT composite, num, quality, std, snow, angle, year, platform, mask, ST_SetSRID(ST_PointFromText(geom), 4326)::geography
    FROM temp_earthdata_vnp46a4",
  paste(cols, collapse = ", ")
)

con <- dbConnect(RPostgres::Postgres(), dbname = POSTGRES_DB, host = POSTGRES_HOST, user = POSTGRES_USER, password = POSTGRES_RPASS, port = POSTGRES_PORT)

for (file in h5_files) {
  nc_data <- nc_open(file)
  for (angle in angles) {
    for (snow in snow_conditions) {
      df <- append(data_list, get_composite_observations(nc_data, snow, angle))
      final_df <- bind_rows(final_df, df)
      final_df$geom <- sprintf('POINT(%s %s)', final_df$lon, final_df$lat)
      copy_to(con, final_df, "temp_earthdata_vnp46a4", temporary = FALSE, overwrite = TRUE)
      dbExecute(con, "ALTER TABLE temp_earthdata_vnp46a4 ALTER COLUMN geom TYPE text;")
      dbExecute(con, query)
      dbExecute(con, "DROP TABLE IF EXISTS temp_earthdata_vnp46a4")
    }
  }
}
dbDisconnect(con)
