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
# Data catalogue
#------------------------------------------------------

# load data
catalogue = read.csv(file.path(initdir, 'catalogue.csv'))

# write table
sf::dbWriteTable(
  conn = db,
  name = 'catalogue',
  value = catalogue,
  overwrite = TRUE
)

# Disconnect from database
DBI::dbDisconnect(db)
