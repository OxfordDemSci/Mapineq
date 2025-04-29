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
    df_content <- df_content |>
      mutate(geo_level = level)
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
    df_content <- df_content |>
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
              filters = map(
                filters_json,
                ~ fromJSON(.x, simplifyVector = FALSE)
              )
            ) %>%
            mutate(
              combos = map(filters, ~ {
                conds <- .x$conditions
                named_values <- set_names(
                  map_chr(conds, "value"),
                  map_chr(conds, "field")
                )
                cross_df(named_values)
              })
            ) %>%
            select(-filters_json, -filters) %>%
            unnest(combos)

          return(df_content)
        } else {
          message(paste0("No data returned for: \n", X_JSON))
        }
      },
      warning = function(e) {
        warning(paste0("WARNING: [", resource, "] ", e))
      },
      error = function(e) {
        warning(paste0("ERROR: [", resource, "] ", e))
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
  result <- catalogue |>
    filter(f_resource %in% keepers) |>
    mutate(data_year = year)
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

# retrieve data for all rows of an expanded catalogue
catalogue_data <- function(catalogue, year, level) {
  results <- list()

  filters <- names(catalogue) %>%
    {
      .[(which(. == "data_year") + 1):length(.)]
    }

  pb <- txtProgressBar(min = 1, max = nrow(catalogue), style = 3)
  start_time <- Sys.time()
  for (i in 1:nrow(catalogue)) {
    setTxtProgressBar(pb, i)
    resource <- catalogue$f_resource[i]

    row_filters <- unlist(as.vector(catalogue[i, filters]))
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

    results[[paste0(resource, "_", i)]] <- get_data(
      resource = resource,
      year = year,
      level = level,
      x_specs = x_specs
    )
  }
  close(pb)
  end_time <- Sys.time()
  message("Time elapsed: ", round(end_time - start_time, 2))
  return(results)
}

# create variable names based on resource/filter combinations
variable_names <- function(dat){
  filter_pos <- (which(names(dat) == "geo_level") + 1):ncol(dat)
  filter_names <- names(dat)[filter_pos]

  result <- dat |>
    rowwise() |>
    mutate(
      variable_name = {
        row_vals <- as.list(cur_data()) # grab every column in this row
        parts <- c(as.character(row_vals$resource))
        for (nm in filter_names) {
          val <- row_vals[[nm]]
          if (!is.na(val)) {
            parts <- c(parts, paste0(nm, "=", as.character(val)))
          }
        }
        paste(parts, collapse = "|")
      }
    ) |>
    ungroup()

  return(result)
}

variable_names_fast <- function(dat){
  # 1) identify the filter columns
  pos_geo     <- which(names(dat) == "geo_level")
  filter_cols <- names(dat)[(pos_geo + 1):ncol(dat)]

  dat %>%
    # 2) for each filter column, build "col=val" or NA
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
    # 3) unite resource + all tmp_* into one string, dropping NAs
    unite(
      col       = "variable_name",
      c("resource", paste0("tmp_", filter_cols)),
      sep       = "|",
      na.rm     = TRUE
    )
}

# catalogue data to wide format
wide_catalogue_data <- function(dat) {

  if (!"variable_name" %in% names(dat)){
    dat <- variable_names(dat)
  }
  
  keep_cols <- c("data_year", "geo", "geo_name", "geo_source", "geo_year")

  result <- dat |>
    select(all_of(keep_cols), variable_name, value) |>
    pivot_wider(
      id_cols = all_of(keep_cols),
      names_from = variable_name,
      values_from = value
    )
  
  return(result)
}
