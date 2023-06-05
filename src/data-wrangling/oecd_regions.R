# Convert OECD TL3 regions shapefile into a csv that excludes geometries (which are private data).
# This provides a linkage between ISO-3 country codes and TL region IDs (level 1, 2, and 3)

library(sf)

# EU country list
eu_countries <- c('')

# OECD countries
oecd_countries <- sf::st_read(dsn = file.path('private', 
                                              'oecd', 
                                              'regions', 
                                              'Country_shape', 
                                              'OECD_Country_2020.shp'))
oecd_countries <- sf::st_drop_geometry(oecd_countries)
oecd_countries <- oecd_countries[order(oecd_countries$iso3),]
oecd_countries <- oecd_countries[,c('tl1_id', 'iso3', 'iso2', 'tl1_name_f', 'tl1_name_e')]

eu_iso3 <- c('AUT', 'BGR', 'HRV', 'CYP', 'CZE', 'DNK', 'EST', 'FIN', 'FRA', 
             'DEU', 'GRC', 'HUN', 'IRL', 'ITA', 'LVA', 'LTU', 'LUX', 'MLT', 
             'NLD', 'POL', 'PRT', 'ROU', 'SVK', 'SVN', 'ESP', 'SWE')
oecd_countries$EU <- oecd_countries$iso3 %in% eu_iso3

eea_iso3 <- c(eu_iso3, 'ISL', 'LIE', 'NOR')
oecd_countries$EEA <- oecd_countries$iso3 %in% eea_iso3

mapineq_iso3 <- c(eea_iso3, 'GBR')
oecd_countries$mapineq <- oecd_countries$iso3 %in% mapineq_iso3

write.csv(oecd_countries,
          row.names=F,
          file=file.path('in', 
                         'oecd', 
                         'regions', 
                         'OECD_Country_2020.csv'))

# OECD TL2
oecd_tl2 <- sf::st_read(dsn = file.path('private', 
                                        'oecd', 
                                        'regions', 
                                        'OECD_TL2_shapefile', 
                                        'OECD_TL2_2020.shp'))
oecd_tl2 <- sf::st_drop_geometry(oecd_tl2)
oecd_tl2 <- oecd_tl2[order(oecd_tl2$tl2_id),]

oecd_tl2$EU <- oecd_tl2$iso3 %in% eu_iso3
oecd_tl2$EEA <- oecd_tl2$iso3 %in% eea_iso3
oecd_tl2$mapineq <- oecd_tl2$iso3 %in% mapineq_iso3

write.csv(oecd_tl2,
          row.names=F,
          file=file.path('in', 
                         'oecd', 
                         'regions', 
                         'OECD_TL2_2020.csv'))

# OECD TL3
oecd_tl3 <- sf::st_read(dsn = file.path('private', 
                                            'oecd', 
                                            'regions', 
                                            'OECD_TL3_shapefile', 
                                            'OECD_TL3_2020.shp'))
oecd_tl3 <- sf::st_drop_geometry(oecd_tl3)
oecd_tl3 <- oecd_tl3[order(oecd_tl3$tl3_id),]

oecd_tl3$EU <- oecd_tl3$iso3 %in% eu_iso3
oecd_tl3$EEA <- oecd_tl3$iso3 %in% eea_iso3
oecd_tl3$mapineq <- oecd_tl3$iso3 %in% mapineq_iso3

write.csv(oecd_tl3,
          row.names=F,
          file=file.path('in', 
                         'oecd', 
                         'regions', 
                         'OECD_TL3_2020.csv'))
