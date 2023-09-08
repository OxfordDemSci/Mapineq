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

#------------------------------------------------------
# Environmental data
#------------------------------------------------------

# List data files
envir_directories = c(orddir, wwldir, nacisdir, woudcdir, worldclimdir)
envir_csv_files = list_files_across_directories(envir_directories, ptrn = '.csv')
envir_shp_files = list_files_across_directories(envir_directories, ptrn = '.shp')
envir_tif_files = list_files_across_directories(envir_directories, ptrn = '.tif')
envir_files = c(envir_csv_files, envir_shp_files, envir_tif_files)

# Define more intuitive variable names for climate data
name_match = data.frame(
  original_name = c("prec", "srad", "tavg", "tmax", "tmin", "wind", "vapr"),
  new_name = c("precipitation", "solar_radiation", "average_temperature", 
               "maximum_temperature", "minimum_temperature", "wind_speed", "water_vapor_pressure")
)

# For each data set: load, wrangle and write into database
for (dfile in envir_files){
  
  # Find directory of data
  matchdir = envir_directories[which(unlist(lapply(lapply(envir_directories, list.files), function(x){ dfile %in% x })))]
  
  # Load original data file into R
  data_df = load_data_file(matchdir, dfile)

  # Write data into database table
  if (all(grepl("raster", class(data_df), ignore.case = T))){
    # Change names of variables if necessary
    name_idx = which(!names(data_df) %in% c("x", "y"))
    match_idx = match(substr(dfile, 11, 14), name_match$original_name)
    names(data_df)[name_idx] = name_match$new_name[match_idx]

    # Write geospatial data into database (skip if not completed after 10 minutes)
    tryCatch(
      expr = {
        withTimeout({
          rpostgis::pgWriteRast(
            conn = db,
            name = mgsub(dfile, c(".tif", ".csv", ".shp"), rep("", 3)),
            raster = data_df,
            overwrite = TRUE,
            blocks = c(1e4, 1e4)
          )
        }, timeout = 600)
      },
      TimeoutException = function(ex) cat("Timeout. Skipping.\n")
    )

  } else {

    # Convert coordinates to geometry if needed
    if (grepl("ozone_uv", dfile)){
      coord_inds = which(names(data_df) %in% c("X", "Y"))
      data_df = st_as_sf(data_df, coords = coord_inds)
    }

    # Write geospatial data into database
    sf::dbWriteTable(
      conn = db,
      name = mgsub(dfile, c(".tif", ".csv", ".shp"), rep("", 3)),
      value = data_df,
      overwrite = TRUE
    )

  }

}

# Disconnect from database
DBI::dbDisconnect(db)
