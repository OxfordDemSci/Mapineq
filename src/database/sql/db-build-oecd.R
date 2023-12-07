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
oecddir = file.path('out', 'oecd', 'data')

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
# OECD data
#------------------------------------------------------

# List data and codebook files
oecd_data_files = list.files(oecddir, pattern = '.csv')
oecd_cobo_files = oecd_data_files[grepl('_codebook.csv', oecd_data_files)]
oecd_data_files = oecd_data_files[!grepl('_codebook.csv', oecd_data_files)]

# List metadata files
oecd_meta_files = list.files(oecddir, pattern = '.xml')
for (dfile in oecd_data_files){
  
  # Load original data file into R
  data_df = load_data_file(oecddir, dfile)
  
  # Modify file to get intuitive variable descriptions/values
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
  tryCatch({
    sf::dbWriteTable(
      conn = db,
      name = gsub(".csv", "", dfile),
      value = data_df,
      overwrite = TRUE
    )
  }, error = function(e){
    message(paste0("Skipping writing to database of ", dfile, "\n"))
    message(e)
  })
  
}

# Disconnect from database
DBI::dbDisconnect(db)
