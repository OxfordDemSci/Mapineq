library(tidyverse)
library(rsdmx)

### Get population weights from the data set "Demographic"
query_tl2_popwgt_raw <- paste0(
  "http://stats.oecd.org/restsdmx/sdmx.ashx/GetData/REGION_DEMOGR/2.",
  ".",
  "T.T.ALL.",
  "2019+2020+2021/all?"
)

tl2_popwgt_raw <- readSDMX(query_tl2_popwgt_raw) %>%
  as.data.frame()


### Get some indicators from the data set "Social et environmental"
query_tl2_socialenv_raw <- paste0(
  "http://stats.oecd.org/restsdmx/sdmx.ashx/GetData/REGION_SOCIAL/1+2.",
  ".",
  "DOC_RA+HOSP_BEDS_RA+WASTE_RA+AIR_POL+VOTERS_RA+BB_ACC.ALL.",
  "2019+2020+2021"
)

tl2_socialenv_raw <- readSDMX(query_tl2_socialenv_raw) %>%
  as.data.frame() 


### Get some indicators from the data set "Labour"
query_tl2_labour_raw <- paste0(
  "http://stats.oecd.org/restsdmx/sdmx.ashx/GetData/REGION_LABOUR/1+2.",
  ".",
  "UNEM_RA_15_64+EMP_RA_15_64.T.ALL.",
  "2019+2020+2021"
)

tl2_labour_raw <- readSDMX(query_tl2_labour_raw) %>%
  as.data.frame()
