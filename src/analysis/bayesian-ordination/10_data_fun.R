# install libraries (if needed)
required_packages <- c("httr", "jsonlite", "dplyr", "tidyr", "purrr")
install.packages(setdiff(required_packages, installed.packages()[, "Package"]))

# load libraries
library(httr)
library(jsonlite)
library(dplyr)
library(tidyr)
library(purrr)


#---- GET operations to retrieve data ----#

# get the Mapineq data catalogue for a given NUTS level
get_catalogue <- function(level) {
  response <- httr::GET(
    url = "https://api.mapineq.org",
    path = "functions/postgisftw.get_source_by_nuts_level/items.json",
    query = list(
      `_level` = level,
      limit = 10e3
    ) # , config = config(ssl_verifypeer = FALSE)  # ignores expired ssl certificate
  )

  if (!status_code(response) == 200) {
    print(paste("Error:", status_code(response)))
  } else {
    df_content <- jsonlite::fromJSON(content(response, "text", encoding = "UTF-8"))
    df_content <- df_content %>%
      mutate(geo_level = level) %>%
      select(f_resource, geo_level, f_short_description, f_description)
    return(df_content)
  }
}

# get years available for a given resource
get_years <- function(resource) {
  response <- httr::GET(
    url = "https://api.mapineq.org",
    path = "functions/postgisftw.get_year_nuts_level_from_source/items.json",
    query = list(
      `_resource` = resource,
      limit = 10e3
    ) # , config = config(ssl_verifypeer = FALSE) # TODO: REMOVE WHEN SSL RENEWED
  )

  if (!status_code(response) == 200) {
    print(paste("Error:", status_code(response)))
  } else {
    df_content <- fromJSON(content(response, "text", encoding = "UTF-8"))
    df_content <- df_content %>%
      mutate(data_year = year)
    return(df_content)
  }
}

# get all filters available for a given resource
get_filters <- function(resource, year, level) {
  response <- httr::GET(
    url = "https://api.mapineq.org",
    path = "functions/postgisftw.get_column_values_source_json/items.json",
    query = list(
      `_resource` = resource,
      source_selections = toJSON(list(
        year = year,
        level = level,
        selected = list(),
        limit = 10e3
      ), auto_unbox = TRUE)
    ) # , config = config(ssl_verifypeer = FALSE)  # ignores expired ssl certificate
  )
  result <- content(response, "text", encoding = "UTF-8")
  return(result)
}

# get data for all administrative units for a given resource, year, nuts level, and resource filter values
get_data <- function(resource, year, level, x_specs) {
  X_JSON <- jsonlite::toJSON(x_specs, auto_unbox = TRUE)

  response <- httr::GET(
    url = "https://api.mapineq.org",
    path = "functions/postgisftw.get_x_data/items.json",
    query = list(
      `_level` = level,
      `_year` = year,
      X_JSON = X_JSON,
      limit = 10e3
    ) # , config = config(ssl_verifypeer = FALSE)  # ignores expired ssl certificate
  )

  if (!status_code(response) == 200) {
    message(paste0("[", resource, "] http status:", status_code(response)))
  } else {
    tryCatch(
      {
        df_content <- jsonlite::fromJSON(content(response, "text", encoding = "UTF-8"))
        if (is.data.frame(df_content)) {
          df_content <- df_content %>%
            as_tibble() %>%
            mutate(
              resource = resource,
              geo_level = level,
              data_year = year
            ) %>%
            rename(value = x) %>%
            mutate(filters_json = as.character(X_JSON)) %>%
            mutate(
              filters = map(filters_json, ~ fromJSON(.x, simplifyVector = FALSE)),
              combos = map(
                filters, ~ {
                  conds <- .x$conditions
                  named_values <- set_names(
                    map_chr(conds, "value"),
                    map_chr(conds, "field")
                  )
                  do.call(expand_grid, as.list(named_values))
                }
              )
            ) %>%
            select(-filters_json, -filters) %>%
            unnest(combos)

          return(df_content)
        } else {
          message(paste0("No data returned for: \n", X_JSON))
        }
      },
      error = function(e) {
        warning(paste0("ERROR: [", resource, "] ", e))
        return(NULL)
      }
    )
  }
}


#---- catalogue manipulation ----#

# subset catalogue to only resources with data for a given year
catalogue_for_year <- function(catalogue, year) {
  keepers <- c()
  for (resource in catalogue$f_resource) {
    df_content <- get_years(resource)
    if (year %in% df_content$f_year) {
      keepers <- c(keepers, resource)
    }
  }
  result <- catalogue %>%
    filter(f_resource %in% keepers) %>%
    mutate(data_year = year) %>%
    select(f_resource, geo_level, data_year, f_short_description, f_description, everything())
  return(result)
}

# add a json column to catalogue that lists filters available for each resource
catalogue_filters <- function(catalogue, year, level) {
  catalogue$filters_json <- apply(catalogue, 1, function(x) {
    get_filters(
      resource = x["f_resource"],
      year = year,
      level = level
    )
  })

  return(catalogue)
}

# create a dictionary of filters and values available for all resources
filter_labels <- function(catalogue) {
  result <- catalogue %>%
    as_tibble() %>%
    mutate(
      filters = map(
        as.character(filters_json),
        ~ fromJSON(.x, simplifyVector = FALSE)
      )
    ) %>%
    unnest_longer(filters) %>%
    unnest_wider(filters, names_sep = "_") %>%
    unnest_longer(filters_field_values) %>%
    unnest_wider(filters_field_values, names_sep = "_") %>%
    rename(
      field = filters_field,
      value = filters_field_values_value,
      field_label = filters_field_label,
      value_label = filters_field_values_label
    ) %>%
    select(-filters_json)

  return(result)
}

# expand the catalogue with a row for all combinations of filter values for every resource
expand_catalogue <- function(catalogue) {
  result <- catalogue %>%
    as_tibble() %>%
    mutate(
      filters = map(
        as.character(filters_json),
        ~ fromJSON(.x, simplifyVector = FALSE)
      )
    ) %>%
    mutate(
      filter_values = map(filters, ~ {
        fl <- .x
        set_names(
          map(fl, ~ map_chr(.x$field_values, "value")),
          map_chr(fl, "field")
        )
      })
    ) %>%
    mutate(
      combos = map(
        filter_values,
        ~ do.call(tidyr::expand_grid, .x) # returns a tibble with columns named by the fields
      )
    ) %>%
    select(-filters_json, -filters, -filter_values) %>%
    unnest(combos)

  return(result)
}

# create variable names based on resource/filter combinations
variable_names <- function(dat, filter_cols) {
  
  dat <- dat %>% 
    select(-any_of(c("variable_name", "variable_name_long")))

  vn <- dat %>% 
    select(f_resource, all_of(filter_cols)) %>%
    distinct() %>%
  
    # long variable names
    mutate(
      across(
        all_of(filter_cols),
        ~ ifelse(is.na(.),
          NA_character_,
          paste0(cur_column(), "=", as.character(.))
        ),
        .names = "tmp_{col}"
      )
    ) %>%
    mutate(
      variable_resource = f_resource
    ) %>%
    unite(
      col = "variable_name_long",
      c("variable_resource", paste0("tmp_", filter_cols)),
      sep = "|",
      na.rm = TRUE
    ) %>%
    
    # short variable names
    group_by(f_resource) %>%
    mutate(
      variable_name = paste0(f_resource, "_", row_number())
    ) %>%
    ungroup()

  result <- dat %>% 
    left_join(vn) %>% 
    select(variable_name, variable_name_long, f_resource, everything())
  
  return(result)
}

# retrieve data for all rows of an expanded catalogue
catalogue_data <- function(catalogue, filter_cols, year, level) {
  results <- list()

  pb <- txtProgressBar(min = 1, max = nrow(catalogue), style = 3)
  start_time <- Sys.time()
  for (i in 1:nrow(catalogue)) {
    setTxtProgressBar(pb, i)
    resource <- catalogue$f_resource[i]
    variable_name <- catalogue$variable_name[i]
    variable_name_long <- catalogue$variable_name_long[i]

    row_filters <- unlist(as.vector(catalogue[i, filter_cols]))
    row_filters <- row_filters[!is.na(row_filters)]

    conditions <- list()
    for (j in 1:length(row_filters)) {
      conditions[[j]] <- list(
        field = names(row_filters[j]),
        value = row_filters[j]
      )
    }

    x_specs <- list(
      source = resource,
      conditions = conditions
    )

    i_data <- get_data(
      resource = resource,
      year = year,
      level = level,
      x_specs = x_specs
    )

    i_data$variable_name <- variable_name
    i_data$variable_name_long <- variable_name_long
    i_data$f_short_description <- catalogue$f_short_description[i]
    i_data$f_description <- catalogue$f_description[i]

    results[[variable_name]] <- i_data %>%
      select(variable_name, variable_name_long, everything())
  }
  close(pb)
  end_time <- Sys.time()
  message("Time elapsed: ", round(end_time - start_time, 2))
  return(results)
}

# catalogue data to wide format
data_to_wide <- function(dat, drop_rows = TRUE) {
  if (!"variable_name" %in% names(dat)) {
    dat <- variable_names(dat)
  }

  keep_cols <- c("data_year", "geo", "geo_name", "geo_source", "geo_year")

  result <- dat %>%
    select(all_of(keep_cols), variable_name, value) %>%
    pivot_wider(
      id_cols = all_of(keep_cols),
      names_from = variable_name,
      values_from = value
    )

  if (drop_rows) {
    vars <- unique(dat$variable_name)
    rows_no_data <- apply(result[, vars], 1, function(x) all(is.na(x)))
    result <- result[!rows_no_data, ]
  }

  return(result)
}

# variable selection spreadsheet
variable_select <- function(dat, catalogue, filter_cols) {
  result <- dat %>%
    select(variable_name, variable_name_long, f_resource, all_of(filter_cols)) %>%
    distinct(variable_name, variable_name_long, f_resource, .keep_all = TRUE) %>%
    left_join(
      catalogue %>%
        select(f_resource, f_short_description, f_description) %>%
        distinct()
    ) %>%
    mutate(
      select_y = 1,
      select_x = 0
    ) %>% 
    select(select_y, select_x, everything())
  return(result)
}
