# cleanup
rm(list = ls()); gc(); cat("\014"); try(dev.off(), silent = T); options(scipen = 999)

# libraries
library(sf)
library(countrycode)

# working directory
setwd(file.path(dirname(rstudioapi::getSourceEditorContext()$path), "..", ".."))

# define directories
outdir <- file.path('src', 'database', 'sql', 'init_data')


#---- data catalogue ----#

# load catalogues (oecd and eurostat)
oecd_cat <- read.csv(file.path('out', 'oecd', 'oecd_catalogue.csv'))
estat_cat <- read.csv(file.path('out', 'eurostat', 'eurostat_catalogue.csv'))

# list data downloaded
oecd_dat <- list.files(file.path('out', 'oecd', 'data'))
oecd_dat <- sapply(oecd_dat, tools::file_path_sans_ext)

estat_dat <- list.files(file.path('out', 'eurostat', 'data'))
estat_dat <- sapply(estat_dat, tools::file_path_sans_ext)

# subset catalogues
oecd_cat <- oecd_cat[oecd_cat$id %in% oecd_dat,]
estat_cat <- estat_cat[estat_cat$id %in% estat_dat,]

# add url
estat_url <- 'https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/'

estat_cat$url <- sapply(estat_cat$id,
                        function(x) {paste0(estat_url, x)})

oecd_url <- 'https://stats.oecd.org/restsdmx/sdmx.ashx/GetData/'
oecd_cat$url <- sapply(oecd_cat$id,
                       function(x) {paste0(oecd_url, x, '/all?')})

# create database catalogue
db_cols <- c('agencyID', 'id', 'Name.en', 'version', 'url')
db_cat <- rbind(oecd_cat[,db_cols],
                estat_cat[,db_cols])
names(db_cat) <- c('provider', 'resource', 'descr', 'version', 'url')

# add information for climate raster variables
clim_raster_info = data.frame(
  agencyID = rep("WorldClim", 7),
  id = paste0("wc2.1_30s_", c("tmin", "tmax", "tavg", "prec", "srad", "wind", "vapr")),
  Name.en = c(
    "Minimum temperature (degrees Celsius) 1970-2000; 30 seconds (~1 km2)",
    "Maximum temperature (degrees Celsius) 1970-2000; 30 seconds (~1 km2)",
    "Average temperature (degrees Celsius) 1970-2000; 30 seconds (~1 km2)",
    "Precipitation 1970-2000 (mm); 30 seconds (~1 km2)",
    "Solar radiation 1970-2000 (kJ/m2 per day); 30 seconds (~1 km2)",
    "Wind speed 1970-2000 (m/s); 30 seconds (~1 km2)",
    "Water vapor pressure (kPa) 1970-2000; 30 seconds (~1 km2)"
  ),
  version = rep("v2.1", 7),
  url = c(
    "https://biogeo.ucdavis.edu/data/worldclim/v2.1/base/wc2.1_30s_tmin.zip",
    "https://biogeo.ucdavis.edu/data/worldclim/v2.1/base/wc2.1_30s_tmax.zip",
    "https://biogeo.ucdavis.edu/data/worldclim/v2.1/base/wc2.1_30s_tavg.zip",
    "https://biogeo.ucdavis.edu/data/worldclim/v2.1/base/wc2.1_30s_prec.zip",
    "https://biogeo.ucdavis.edu/data/worldclim/v2.1/base/wc2.1_30s_srad.zip",
    "https://biogeo.ucdavis.edu/data/worldclim/v2.1/base/wc2.1_30s_wind.zip",
    "https://biogeo.ucdavis.edu/data/worldclim/v2.1/base/wc2.1_30s_vapr.zip"
  )
)
db_cat = rbind(db_cat, clim_raster_info)

# add information for geospatial polygon variables
envir_polygon_info = data.frame(
  agencyID = c("North American Cartographic Information Society", rep("World Wild Life (WWF)", 3)),
  id = c("natural_earth_vector", "8ark3lcpfw_GLWD_level1", "65sv5l285i_GLWD_level2", "9slil0ww7t_GLWD_level3"),
  Name.en = c("Natural Earth", paste0("Lakes and wetlands (Level ", 1:3, ")")),
  version = rep(NA, 4),
  url = c(
    "https://naciscdn.org/naturalearth/packages/natural_earth_vector.gpkg.zip",
    "https://files.worldwildlife.org/wwfcmsprod/files/Publication/file/8ark3lcpfw_GLWD_level1.zip?_ga=2.6743986.1226121816.1690982761-579293559.1690982761",
    "https://files.worldwildlife.org/wwfcmsprod/files/Publication/file/65sv5l285i_GLWD_level2.zip?_ga=2.6743986.1226121816.1690982761-579293559.1690982761",
    "https://files.worldwildlife.org/wwfcmsprod/files/Publication/file/9slil0ww7t_GLWD_level3.zip?_ga=2.6743986.1226121816.1690982761-579293559.1690982761"
  )
)
db_cat = rbind(db_cat, envir_polygon_info)

# add information for geospatial line data variables
envir_line_info = data.frame(
  agencyID = c("UK Ordnance Survey"),
  id = c("gb_roads"),
  Name.en = c("Roads in Great Britain"),
  version = c("v1"),
  url = c("https://api.os.uk/downloads/v1/products/OpenRoads/downloads?area=GB&format=GeoPackage&redirect")
)
db_cat = rbind(db_cat, envir_line_info)

# add information for geospatial point data variables
n_datasets = 91
envir_point_info = data.frame(
  agencyID = rep("The World Ozone and Ultraviolet Radiation Data Centre", n_datasets),
  id = paste0("uv_ozone_", 1:n_datasets),
  Name.en = paste0("UV and Ozone levels (starting from feature ", 1:n_datasets * 1e4, ")"),
  version = rep("1.1", n_datasets),
  url = paste0('https://geo.woudc.org/ows?service=WFS&version=1.1.0&request=GetFeature&outputformat=GeoJSON&typename=filelist&filter=%3Cogc:Filter%3E%3Cogc:And%3E%3Cogc:BBOX%3E%3CPropertyName%3EmsGeometry%3C/PropertyName%3E%3CBox%20srsName=%22EPSG:4326%22%3E%3Ccoordinates%3E-189.14062500000003,-83.67694304841552%20189.84375,85.51339830988749%3C/coordinates%3E%3C/Box%3E%3C/ogc:BBOX%3E%3Cogc:PropertyIsBetween%3E%3Cogc:PropertyName%3Einstance_datetime%3C/ogc:PropertyName%3E%3Cogc:LowerBoundary%3E1924-01-01%2000:00:00%3C/ogc:LowerBoundary%3E%3Cogc:UpperBoundary%3E2023-12-30%2023:59:59%3C/ogc:UpperBoundary%3E%3C/ogc:PropertyIsBetween%3E%3C/ogc:And%3E%3C/ogc:Filter%3E&sortby=instance_datetime%20DESC&startindex=', 1:n_datasets * 1e4,'&maxfeatures=10000')
)
db_cat = rbind(db_cat, envir_point_info)

# save to disk
write.csv(db_cat, 
          file = file.path(outdir, 'catalogue.csv'), 
          row.names = FALSE)


#---- nuts regions ----#

# list nuts files
lf <- list.files(file.path('out', 'nuts'))

# load data into list
df_list <- list()
for(i in 1:length(lf)){
  df_list[[i]] <- st_read(file.path('out', 'nuts', lf[i]))
}

# combine NUTS levels into one sf data.frame
df_combined <- do.call('rbind', df_list)

# map new column names
new_names = list(NUTS_ID = 'id',
                 CNTR_CODE = 'country',
                 LEVL_CODE = 'level', 
                 NUTS_NAME = 'name',
                 URBN_TYPE = 'urban',
                 MOUNT_TYPE = 'mount',
                 COAST_TYPE = 'coast', 
                 id_nuts_0 = 'nuts0_id',
                 id_nuts_1 = 'nuts1_id',
                 id_nuts_2 = 'nuts2_id',
                 id_nuts_3 = 'nuts3_id',
                 tl0_id = 'tl0_id',
                 tl1_id = 'tl1_id',
                 tl2_id = 'tl2_id',
                 tl3_id = 'tl3_id',
                 geom = 'geom')

# reduce cols
df_combined <- df_combined[names(new_names)]

# rename cols
match_idx <- match(names(df_combined), names(new_names))
names(df_combined)[match_idx] <- unlist(new_names)

# rearrange columns
df_combined <- df_combined[,unlist(new_names)]

# country names
df_combined$country[df_combined$country=='EL'] <- 'GR'
df_combined$country[df_combined$country=='UK'] <- 'GB'
df_combined$name[df_combined$level==0] <- countrycode(sourcevar = df_combined$country[df_combined$level==0], 
                                                      origin = 'iso2c', 
                                                      destination = 'country.name')

# copy combined data to database directory
sf::st_write(obj = df_combined,
             dsn = file.path(outdir, 'nuts.gpkg'),
             append = FALSE)
