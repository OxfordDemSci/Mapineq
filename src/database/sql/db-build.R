# cleanup
rm(list = ls()); gc(); cat("\014"); try(dev.off(), silent = T); options(scipen = 999)

# libraries
library(sf)
library(DBI)
library(RPostgres)

# working directory
setwd(file.path(dirname(rstudioapi::getSourceEditorContext()$path), '..', '..', '..'))

# environment variables
source('prod.env')

# define directories
datdir <- file.path('src', 'database', 'sql', 'init_data')
oecddir <- file.path('out', 'oecd', 'data')
estatdir <- file.path('out', 'eurostat', 'data')

# database connection
db <- DBI::dbConnect(drv = RPostgres::Postgres(),
                     dbname = POSTGRES_DB,
                     host = POSTGRES_HOST, 
                     port = POSTGRES_PORT,
                     password = POSTGRES_PASSWORD,
                     user = POSTGRES_USER)


#---- NUTS ----#

# load data
nuts <- sf::st_read(file.path(datdir, 'nuts.gpkg'))

# write table
sf::dbWriteTable(conn = db,
                 name = 'nuts',
                 value = nuts,
                 overwrite = TRUE)


#---- catalogue ----#

# load data
catalogue <- read.csv(file.path(datdir, 'catalogue.csv'))

# write table
sf::dbWriteTable(conn = db,
                 name = 'catalogue',
                 value = catalogue,
                 overwrite = TRUE)


#---- oecd data ----#

# list data
lf <- list.files(oecddir, pattern='.csv')
lf <- lf[!grepl('_codebook.csv', lf)]

for(l in lf){
  # create target db table
  # modify data as needed
  # write data into table
}


#---- estat data ----#

# list data
lf <- list.files(estatdir, pattern='.csv')

for(l in lf){
  # create target db table
  # modify data as needed
  # write data into table
}

