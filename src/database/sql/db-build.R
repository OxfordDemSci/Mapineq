# cleanup
rm(list = ls()); gc(); cat("\014"); try(dev.off(), silent = T); options(scipen = 999)

# libraries
library(sf)
library(DBI)
library(RPostgres)

# working directory
setwd(file.path(dirname(rstudioapi::getSourceEditorContext()$path), '..', '..', '..'))

# functions
source('functions.R')

# environment variables
# TODO: file not found
source('prod.env')

# define directories
datdir <- file.path('src', 'database', 'sql', 'init_data')
oecddir <- file.path('out', 'oecd', 'data')
estatdir <- file.path('out', 'eurostat', 'data')

# database connection
# TODO: define PostGres arguments
db <- DBI::dbConnect(
  drv = RPostgres::Postgres(),
  dbname = POSTGRES_DB,
  host = POSTGRES_HOST, 
  port = POSTGRES_PORT,
  password = POSTGRES_PASSWORD,
  user = POSTGRES_USER
)

#---- NUTS ----#

# load data
nuts <- sf::st_read(file.path(datdir, 'nuts.gpkg'))

# write table
sf::dbWriteTable(
  conn = db,
  name = 'nuts',
  value = nuts,
  overwrite = TRUE
)


#---- catalogue ----#

# load data
catalogue <- read.csv(file.path(datdir, 'catalogue.csv'))

# write table
sf::dbWriteTable(
  conn = db,
  name = 'catalogue',
  value = catalogue,
  overwrite = TRUE
)


#------------------------------------------------------
# OECD data
#------------------------------------------------------

# List data and codebook files
oecd_data_files = list.files(oecddir, pattern = '.csv')
oecd_cobo_files = oecd_data_files[grepl('_codebook.csv', oecd_data_files)]
oecd_data_files = oecd_data_files[!grepl('_codebook.csv', oecd_data_files)]

# List metadata files
oecd_meta_files = list.files(oecddir, pattern = '.xml')

dlist = list()
for (dfile in oecd_data_files){
  
  # Load original data file into R
  data_df = load_data_file(oecddir, dfile)
  
  # Modify file to get intuitive variable descriptions/values
  # TODO: match names of columns (e.g. COUNTRY means LOCATION)
  meta_file = paste0(oecddir, "/", gsub(".csv", ".xml", dfile))
  match_df = oecd_meta_xml_to_data_frame(meta_file)
  for (col in names(data_df)){
    match_sub = match_df[gsub(paste0("CL_", gsub(".csv", "", dfile), "_"), "", match_df$id) == col, ]
    if ("parentCode" %in% names(match_sub)){
      data_df[paste0(col, "_PARENT")] = match_sub$parentCode[match(data_df[, col], match_sub$value)]
      data_df[paste0(col, "_PARENT_DESC.EN")] = match_sub$desc_en[match(data_df[, paste0(col, "_PARENT")], match_sub$parentCode)]
    } 
    data_df[paste0(col, "_DESC.EN")] = match_sub$desc_en[match(data_df[, col], match_sub$value)]
  }
  
  # Write data into database table
  # TODO: define separate folders for different data sources?
  sf::dbWriteTable(
    conn = db,
    name = gsub(".csv", "", dfile), 
    value = data_df,
    overwrite = TRUE
  )
  
}


#------------------------------------------------------
# Eurostat data
#------------------------------------------------------

# List data files
euro_data_files = list.files(estatdir, pattern = '.csv')

# List metadata files
euro_meta_files = list.files(estatdir, pattern = '.xml')

for (dfile in euro_data_files){
  
  # Load original data file into R
  data_df = load_data_file(estatdir, dfile)
  
  # Modify file to get intuitive variable descriptions/values
  for (variable in names(data_df)){
    file_nam = paste0(toupper(variable), ".xml")
    if (file_nam %in% euro_meta_files){
      match_df = eurostat_meta_xml_to_data_frame(paste0(estatdir, "/", file_nam))
      index = match(data_df[, variable], rownames(match_df))
      data_df[paste0(variable, "_metadesc")] = match_df$en[index]
    }
  }
  
  # Write data into database table
  # TODO: define separate folders for different data sources?
  sf::dbWriteTable(
    conn = db,
    name = gsub(".csv", "", dfile), 
    value = data_df,
    overwrite = TRUE
  )
  
}

