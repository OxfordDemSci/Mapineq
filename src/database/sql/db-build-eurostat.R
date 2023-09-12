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
estatdir = file.path('out', 'eurostat', 'data')

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
