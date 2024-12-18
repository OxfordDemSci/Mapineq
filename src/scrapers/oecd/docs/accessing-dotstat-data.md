# Fetching OECD data from the OECD.Stat API
The OECD API also works with the SDMX query. On the DotStat portal, once you have selected your dataset and filter the variables your are interested in, click on `Export`, and then `SDMX (XML)`. Copy the main part of the `SDMX DATA URL` (i.e. drop `https://stats.oecd.org/restsdmx/sdmx.ashx/GetData` from the string). For more details, see [here](accessing-dotstat-data.md#get-the-smdx-query).


## Get the SMDX query
On the DotStat portal, once you have selected your dataset and filter the variables your are interested in, click on `Export`, and then `SDMX (XML)`. Copy the main part of the `SDMX DATA URL` (i.e. drop `https://stats.oecd.org/restsdmx/sdmx.ashx/GetData` from the string).

![alt text](_images/dotstat2.png)

Data URLs for the regional and metropolitan databases can get very long because of the regions/FUAs identifiers. To avoid any issue with your software, you can drop all the identifiers (e.g. `REGION_LABOUR/3..UNEM_RA_15_64+EMP_RA_15_16.T+F+M.ALL.2015+2016+2017+2018+2019/all?`) if you want to get data for all regions/FUAs.
For all datasets in DotStat, URLs are constructed as `DATASET_NAME/FILTER1.FILTER2.[...].FILTERn/all?`. Filters depend on the dataset. Leaving a filter empty between two dots selects all values.

## Fetch data from your software
### Using R
```R
library(rsdmx)
data <- readSDMX("<YourSdmxQuery>")
```
Example:
```R
library(rsdmx)
query <- paste0(
  "https://stats.oecd.org/restsdmx/sdmx.ashx/GetData/RWB/",
  ".",
  "BB_ACC.VALUE/",
  "all?startTime=2000&endTime=2014"
  )
draw <- readSDMX(query) %>%
  as.data.frame()
```

> If the SDMX query string is too long, R will not read it. To avoid this issue, you need to reduce the length of the string (e.g. by removing all the regional identifiers).
### Using Python
To fetch the data as a Pandas DataFrame, you just need to copy paste the SDMX query in the query string.
```Python
import pandas as pd
data = pd.read_csv(f"https://stats.oecd.org/SDMX-JSON/data/{<YourSdmxQuery>}&contentType=csv")
```
Example:
```Python
import pandas as pd
sdmx_query = "REGION_LABOUR/3..UNEM_RA_15_64+EMP_RA_15_16.T+F+M.ALL.2015+2016+2017+2018+2019/all?"
data = pd.read_csv(f"https://stats.oecd.org/SDMX-JSON/data/{sdmx_query}&contentType=csv")

```
