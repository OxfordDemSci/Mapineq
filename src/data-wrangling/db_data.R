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
