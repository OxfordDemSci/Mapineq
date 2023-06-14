# cleanup
rm(list = ls()); gc(); cat("\014"); try(dev.off(), silent = T); options(scipen = 999)

# libraries
library(sf)
library(DBI)
library(RPostgres)

# working directory
setwd(file.path(dirname(rstudioapi::getSourceEditorContext()$path), ".."))

# environment variables
source('production.env')

# define directories
datdir <- file.path('sql', 'init_data')

# database connection
db <- DBI::dbConnect(drv = RPostgres::Postgres(),
                     dbname = POSTGRES_DB,
                     host = '15.236.82.244', # '15.236.82.244' or '127.0.0.1'
                     port = 5432,
                     password = POSTGRES_PASSWORD,
                     user = POSTGRES_USER)


#---- NUTS ----#

# load data
dat <- sf::st_read(file.path(datdir, 'nuts.gpkg'))

# write table
sf::dbWriteTable(conn = db,
                 name = 'nuts',
                 value = dat,
                 overwrite = TRUE)
