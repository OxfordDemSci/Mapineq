# cleanup
rm(list = ls())
gc()
options(scipen = 999)

# libraries
library(httr)
library(jsonlite)
library(tidyr)

# API url
url <- "https://api.mapineq.org"


#---- get sources by NUTS level ----#

# API endpoint
endpoint <- "functions/postgisftw.get_source_by_nuts_level/items.json"

# Endpoint parameters
params <- list(
  `_level` = 2,
  limit = 500
)

# GET request to query API
response <- httr::GET(url = url, path = endpoint, query = params)

# Check the response status
if (!status_code(response) == 200) {
  print(paste("Error:", status_code(response)))
} else {
  # API response as text
  raw_content <- content(response, "text")

  # API response as data.frame
  df_content <- jsonlite::fromJSON(raw_content)
}





#---- get years and NUTS levels from source ----#


# API endpoint
endpoint <- "functions/postgisftw.get_year_nuts_level_from_source/items.json"

# Endpoint parameters
params <- list(
  `_resource` = "TGS00103",
  limit = 500
)

# GET request to query API
response <- httr::GET(url = url, path = endpoint, query = params)

# Check the response status
if (!status_code(response) == 200) {
  print(paste("Error:", status_code(response)))
} else {
  # API response as data.frame
  df_content <- jsonlite::fromJSON(content(response, "text"))
}


#---- get column values from source ----#

# API endpoint
endpoint <- "functions/postgisftw.get_column_values_source_json/items.json"

# Endpoint paramters
params <- list(
  `_resource` = "TGS00103",
  source_selections = toJSON(list(
    source = "TGS00103",
    source_selections = list(
      year = 2020,
      level = 2, 
      selected = list()
    )
  ), auto_unbox = TRUE),
  limit = 40
)

# GET request to query API
response <- httr::GET(url = url, path = endpoint, query = params)

# Check the response status
if (!status_code(response) == 200) {
  print(paste("Error:", status_code(response)))
} else {
  # API response as JSON
  json_content <- jsonlite::fromJSON(content(response, "text"))

  # flatten into data frame
  df_content <- json_content %>%
    unnest_longer(field_values) %>%
    unnest_wider(field_values)
}


#---- get X data ----#

# API endpoint
endpoint <- "functions/postgisftw.get_x_data/items.json"

# Endpoint parameters
params <- list(
  `_level` = 2,
  `_year` = 2018,
  X_JSON = toJSON(list(
    source = "TGS00103",
    conditions = list(
      list(field = "unit", value = "PC_POP"),
      list(field = "freq", value = "A")
    )
  ), auto_unbox = TRUE),
  limit = 1500
)

# GET request to query API
response <- httr::GET(url = url, path = endpoint, query = params)

# Check the response status
if (!status_code(response) == 200) {
  print(paste("Error:", status_code(response)))
} else {
  # API response as data.frame
  df_content <- jsonlite::fromJSON(content(response, "text"))
}



#---- get X and Y data ----#

# API endpoint
endpoint <- "functions/postgisftw.get_xy_data/items.json"

# Endpoint parameters
params <- list(
  `_level` = 2,
  `_year` = 2018,
  X_JSON = toJSON(
    list(
      source = "TGS00103",
      conditions = list(
        list(field = "unit", value = "PC_POP"),
        list(field = "freq", value = "A")
      )
    ),
    auto_unbox = TRUE
  ),
  Y_JSON = toJSON(
    list(
      source = "DEMO_R_MLIFEXP",
      conditions = list(
        list(field = "unit", value = "YR"),
        list(field = "age", value = "Y_LT1"),
        list(field = "sex", value = "T"),
        list(field = "freq", value = "A")
      )
    ),
    auto_unbox = TRUE
  ),
  limit = 1500
)

# GET request to query API
response <- httr::GET(url = url, path = endpoint, query = params)

# Check the response status
if (!status_code(response) == 200) {
  print(paste("Error:", status_code(response)))
} else {
  # API response as data.frame
  df_content <- jsonlite::fromJSON(content(response, "text"))
}
