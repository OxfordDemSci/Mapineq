# cleanup
rm(list = ls()); gc(); cat("\014"); try(dev.off(), silent = T); options(scipen = 999)

# libraries
library(sf)
library(DBI)
library(RPostgres)

# working directory
setwd(file.path(dirname(rstudioapi::getSourceEditorContext()$path), ".."))

# environment variables
source('.env')

# define directories
datdir <- file.path('sql', 'init_data')

# database connection
db <- DBI::dbConnect(drv = RPostgres::Postgres(),
                     dbname = POSTGRES_DB,
                     host = POSTGRES_HOST, 
                     port = POSTGRES_PORT,
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

#---- catalogue ----#

# load data
dat <- read.csv(file.path(datdir, 'catalogue.csv'))

# write table
sf::dbWriteTable(conn = db,
                 name = 'catalogue',
                 value = dat,
                 overwrite = TRUE)
