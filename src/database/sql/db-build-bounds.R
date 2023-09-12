# cleanup
rm(list = ls()); gc(); cat("\014"); try(dev.off(), silent = T); options(scipen = 999)

# libraries
library(sf)
library(DBI)
library(RPostgres)
library(mgsub)
library(rpostgis)
library(R.utils)

# working directory
setwd(file.path(dirname(rstudioapi::getSourceEditorContext()$path), '..', '..', '..'))

# define directories
sqldir = file.path('src', 'database', 'sql')
nutsdir = file.path('out', 'nuts', 'data')
gadmdir = file.path('out', 'gadm', 'data')

# functions
source(file.path(sqldir, 'functions.R'))

# environment variables
source('src/database/prod.env')

# database connection
db = DBI::dbConnect(
  drv = RPostgres::Postgres(),
  dbname = POSTGRES_DB,
  host = POSTGRES_HOST,
  port = POSTGRES_PORT,
  password = POSTGRES_PASSWORD,
  user = POSTGRES_USER
)

#------------------------------------------------------
# NUTS data
#------------------------------------------------------

nuts_files = list.files(nutsdir, '.gpkg')
for (file in nuts_files){
  
  # load data
  nuts_df = sf::st_read(file.path(nutsdir, file))
  
  # write table
  sf::dbWriteTable(
    conn = db,
    name = gsub(".gpkg", "", file),
    value = nuts_df,
    overwrite = TRUE
  )
  
}

#------------------------------------------------------
# GADM data
#------------------------------------------------------

# load data
gadm = sf::st_read(file.path(gadmdir, 'gadm_410.gpkg'))

# write table
sf::dbWriteTable(
  conn = db,
  name = 'gadm',
  value = gadm,
  overwrite = TRUE
)

# Disconnect from database
DBI::dbDisconnect(db)
