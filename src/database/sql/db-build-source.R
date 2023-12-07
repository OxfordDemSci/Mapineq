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
initdir = file.path('src', 'database', 'sql', 'init_data')
nutsdir = file.path('out', 'nuts', 'data')
gadmdir = file.path('out', 'gadm', 'data')
oecddir = file.path('out', 'oecd', 'data')
estatdir = file.path('out', 'eurostat', 'data')
orddir = file.path('out', 'ordnance', 'data')
wwldir = file.path('out', 'worldwildlife', 'data')
nacisdir = file.path('out', 'nacis', 'data')
woudcdir = file.path('out', 'woudc', 'data')
worldclimdir = file.path('out', 'worldclim', 'data')

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
# Source information for data sets
#------------------------------------------------------

# load data
source = read.csv('out/source_data_info.csv')

# write table
sf::dbWriteTable(
  conn = db,
  name = 'source',
  value = source,
  overwrite = TRUE
)

# Disconnect from database
DBI::dbDisconnect(db)
