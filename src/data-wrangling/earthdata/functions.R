if ("ncdf4" %in% rownames(installed.packages()) == FALSE) {install.packages("ncdf4")}
if ("dplyr" %in% rownames(installed.packages()) == FALSE) {install.packages("dplyr")}

library(ncdf4)
library(dplyr)

melt_data <- function(data, lat, lon, column) {
  melted <- melt(data)
  melted$Lat <- lat[melted$Var1]
  melted$Lon <- lon[melted$Var2]
  colnames(melted) <- c("row", "col", column, "lat", "lon")
  return(melted)
}

get_composite_observations <- function (nc, snow, angle) {
  field_root = 'HDFEOS/GRIDS/VIIRS_Grid_DNB_2d/Data Fields/'
  start_time <- ncatt_get(nc_data, 0, "StartTime")
  obs_year <- ifelse(start_time$hasatt, as.integer(format(as.Date(start_time$value, format="%Y-%m-%d %H:%M:%S"), '%Y')), NA)
  
  lat <- ncvar_get(nc, paste0(field_root, 'lat'))
  lon <- ncvar_get(nc, paste0(field_root, 'lon'))
  
  angles <- list('AllAngle', 'NearNadir', 'OffNadir')
  snow_conditions <- list(TRUE, FALSE)
  
  composite <- ncvar_get(nc, paste0(field_root, paste(angle, 'Composite', 'Snow', ifelse(snow, 'Covered', 'Free'), sep = '_')))
  num <- ncvar_get(nc, paste0(field_root, paste(angle, 'Composite', 'Snow', ifelse(snow, 'Covered', 'Free'), 'Num', sep = '_')))
  quality <- ncvar_get(nc, paste0(field_root, paste(angle, 'Composite', 'Snow', ifelse(snow, 'Covered', 'Free'), 'Quality', sep = '_')))
  std <- ncvar_get(nc, paste0(field_root, paste(angle, 'Composite', 'Snow', ifelse(snow, 'Covered', 'Free'), 'Std', sep = '_')))
  platform <- ncvar_get(nc, paste0(field_root, 'DNB_Platform'))
  mask <- ncvar_get(nc, paste0(field_root, 'Land_Water_Mask'))
  
  melted_composite <- melt_data(composite, lat, lon, 'composite')
  melted_num <- melt_data(composite, lat, lon, 'num')
  melted_quality <- melt_data(quality, lat, lon, 'quality')
  melted_std <- melt_data(std, lat, lon, 'std')
  melted_platform <- melt_data(platform, lat, lon, 'platform')
  melted_mask <- melt_data(mask, lat, lon, 'mask')
  
  joined_data <- melted_composite %>%
    inner_join(melted_num, by=c("lat", "lon")) %>%
    inner_join(melted_quality, by=c("lat", "lon")) %>%
    inner_join(melted_std, by=c("lat", "lon")) %>%
    inner_join(melted_platform, by=c("lat", "lon")) %>%
    inner_join(melted_mask, by=c("lat", "lon"))
  
  
  joined_data$snow <- snow
  joined_data$angle <- angle
  joined_data$year <- obs_year
  
  final_data <- joined_data %>%
    select(lat, lon, composite, num, quality, std, snow, angle, year, platform, mask)
  return(final_data)
}