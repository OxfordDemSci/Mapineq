# libraries
library(rsdmx)

#---- endpoint: REGION_DEMOGR ----#
get_region_demogr <- function(oecd_key){
  
  # get request
  query_string <- paste0('http://stats.oecd.org/restsdmx/sdmx.ashx/GetData/REGION_DEMOGR/',
                         '1+2+3.',
                         '.',
                         'T.T.ALL.',
                         paste0(2010:format(Sys.Date(), "%Y")-1, collapse='+'),
                         '/all?')
  
  dat <- as.data.frame(rsdmx::readSDMX(query_string))
  
  # subset TL1 (country) data for mapineq countries
  dat_tl1 <- dat[dat$TL==1 & dat$REG_ID %in% oecd_key$iso3,]
  
  dat_oecd <- oecd_key[,c('iso3', 'tl1_id')]
  
  dat_tl1 <- merge(x = dat_tl1, 
                   y = dat_oecd, 
                   by.x = 'REG_ID', 
                   by.y = 'iso3')

  # subset TL2 (region) data for mapineq countries
  dat_tl2 <- dat[dat$TL==2 & dat$REG_ID %in% oecd_key$tl2_id,]
  
  dat_oecd <- oecd_key[!duplicated(oecd_key$tl2_id), c('iso3', 'tl1_id', 'tl2_id')]
  
  dat_tl2 <- merge(x = dat_tl2, 
                   y = dat_oecd, 
                   by.x = 'REG_ID', 
                   by.y = 'tl2_id', 
                   all.y=T)
  
  dat_tl2$tl2_id <- dat_tl2$REG_ID
  
  # subset TL3 (region) data for mapineq countries
  dat_tl3 <- dat[dat$TL==3 & dat$REG_ID %in% oecd_key$tl3_id,]
  
  dat_oecd <- oecd_key[!duplicated(oecd_key$tl3_id),c('iso3', 'tl1_id', 'tl2_id', 'tl3_id')]
  
  dat_tl3 <- merge(x = dat_tl3, 
                   y = dat_oecd, 
                   by.x = 'REG_ID', 
                   by.y = 'tl3_id', 
                   all.y=T)
  
  dat_tl3$tl3_id <- dat_tl3$REG_ID
  
  return(list(tl1 = dat_tl1, 
              tl2 = dat_tl2, 
              tl3 = dat_tl3))
}

#---- endpoint: REGION_EDUCAT ----#
get_region_educat <- function(oecd_key){
  
  # get request
  countries <- c('AUT', 'BEL', 'CZE', 'DNK', 'EST', 'FIN', 'FRA', 'DEU', 'GRC', 
                 'HUN', 'ISL', 'IRL', 'ITA', 'LVA', 'LTU', 'LUX', 'NLD', 'NOR', 
                 'POL', 'PRT', 'SVK', 'SVN', 'ESP', 'SWE', 'CHE', 'GBR')
  
  query_string <- paste0('https://stats.oecd.org/SDMX-JSON/data/REGION_EDUCAT/',
                         paste0(countries, collapse='+'), '.',
                         paste0(countries, collapse='+'), '.',
                         'NEAC_SHARE_EA_Y25T64+NEAC_SHARE_EA_Y25T34.',
                         'L0T2+L3T4+L5T8+L5+L6+L7+L8.',
                         'T+F+M.VALUE/all?',
                         'startTime=2015&',
                         paste0('endTime=', as.numeric(format(Sys.Date(), "%Y"))-1, '&'),
                         'dimensionAtObservation=allDimensions')

    response <- rsdmx::readSDMX(query_string)
    dat <- as.data.frame(response)
    
    countries <- c('AUT', 'BEL', 'DNK', 'EST', 'FIN')
    tl3 <- oecd_key$tl3_id[oecd_key$iso3 %in% countries]
    
    query_string <- paste0('https://stats.oecd.org/SDMX-JSON/data/REGION_EDUCAT/',
                           paste0(countries, collapse='+'), '.',
                           paste0(tl3, collapse='+'), '.',
                           'NEAC_SHARE_EA_Y25T64+NEAC_SHARE_EA_Y25T34+NEAC_RATE_EMPLOYMENT_Y25T64+NEAC_RATE_EMPLOYMENT_Y25T34+ENRL_RATE_AGE_Y3T5+ENRL_RATE_AGE_Y6T14+ENRL_RATE_AGE_Y15T19+ENRL_RATE_AGE_Y20T29+ENRL_RATE_AGE_Y30T39+ENRL_RATE_AGE_Y40T64+TRANS_SHARE_EDULABOUR_NE_U_I_Y18T24+EARLY_LEAVERS_RATE_Y18T24+PIAAC_AL_FNFAET12_Y25T64+PIAAC_AL_FNFAET4_Y25T64.',
                           'L0T2+L3T4+L5+L6+L7+L8.',
                           'T+F+M.VALUE/all?',
                           'startTime=2015&',
                           paste0('endTime=', as.numeric(format(Sys.Date(), "%Y"))-1, '&'),
                           'dimensionAtObservation=allDimensions')
    
    response <- rsdmx::readSDMX(query_string)
    dat <- as.data.frame(response)
    
    
  
}