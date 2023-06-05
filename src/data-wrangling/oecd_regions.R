# Convert OECD TL3 regions shapefile into a csv that excludes geometries (which are private data).
# This provides a linkage between ISO-3 country codes and TL region IDs (level 1, 2, and 3)

library(sf)

oecd_regions <- sf::st_read(dsn = file.path('private', 
                                            'oecd', 
                                            'regions', 
                                            'OECD_TL3_shapefile', 
                                            'OECD_TL3_2020.shp'))

oecd_regions <- sf::st_drop_geometry(oecd_regions)

oecd_regions <- oecd_regions[order(oecd_regions$tl3_id),]

write.csv(oecd_regions,
          row.names=F,
          file=file.path('in', 
                         'oecd', 
                         'regions', 
                         'OECD_TL3_2020.csv'))
