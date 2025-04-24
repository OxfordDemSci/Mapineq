# install libraries (if needed)
required_packages <- c("httr", "jsonlite", "dplyr", "tidyr", "purrr")
install.packages(setdiff(required_packages, installed.packages()[, "Package"]))

# load libraries
library(httr)
library(jsonlite)
library(dplyr)
library(tidyr)
library(purrr)

get_catalogue <- function(level) {
  response <- httr::GET(
    url = "https://api.mapineq.org",
    path = "functions/postgisftw.get_source_by_nuts_level/items.json",
    query = list(
      `_level` = level,
      limit = 10e3
    ),
    config = config(ssl_verifypeer = FALSE) # TODO: REMOVE WHEN SSL RENEWED
  )

  if (!status_code(response) == 200) {
    print(paste("Error:", status_code(response)))
  } else {
    df_content <- jsonlite::fromJSON(content(response, "text", encoding = "UTF-8"))
    return(df_content)
  }
}

catalogue_for_year <- function(catalogue, year) {
  keep_resource <- c()
  for (resource in catalogue$f_resource) {
    response <- httr::GET(
      url = "https://api.mapineq.org",
      path = "functions/postgisftw.get_year_nuts_level_from_source/items.json",
      query = list(
        `_resource` = resource
      ),
      config = config(ssl_verifypeer = FALSE) # TODO: REMOVE WHEN SSL RENEWED
    )

    if (!status_code(response) == 200) {
      print(paste("Error:", status_code(response)))
    } else {
      df_content <- fromJSON(content(response, "text", encoding = "UTF-8"))
      if (year %in% df_content$f_year) {
        keep_resource <- c(keep_resource, resource)
      }
    }
  }
  result <- catalogue |>
    filter(f_resource %in% keep_resource)
  return(result)
}

catalogue_filters <- function(catalogue, year, level) {
  # get filters for each data set
  catalogue$filters_json <- apply(catalogue, 1, function(x) {
    query_filters(
      resource = x["f_resource"],
      year = year,
      level = level
    )
  })

  return(catalogue)
}

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
        ~ cross_df(.x) # returns a tibble with columns named by the fields
      )
    ) %>%
    select(-filters_json, -filters, -filter_values) %>%
    unnest(combos)

  return(result)
}

expand_catalogue_alt <- function(catalogue) {
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

catalogue_data <- function(catalogue, year, level) {
  results <- list()

  filters <- names(catalogue) %>%
    {
      .[(which(. == "f_short_description") + 1):length(.)]
    }

  pb <- txtProgressBar(min = 1, max = nrow(catalogue), style = 3)
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

    X_JSON <- toJSON(list(
      source = resource,
      conditions = conditions
    ), auto_unbox = TRUE)

    results[[resource]] <- get_data(
      resource = resource,
      year = year,
      level = level,
      X_JSON = X_JSON
    )
  }
  close(pb)
  result <- bind_rows(results)
  return(result)
}


get_data <- function(resource, year, level, X_JSON) {
  response <- httr::GET(
    url = "https://api.mapineq.org",
    path = "functions/postgisftw.get_x_data/items.json",
    query = list(
      `_level` = level,
      `_year` = year,
      X_JSON = X_JSON,
      limit = 10e3
    ),
    config = config(ssl_verifypeer = FALSE) # TODO: REMOVE WHEN SSL RENEWED
  )

  if (!status_code(response) == 200) {
    message(paste0("[", resource, "] Error:", status_code(response)))
  } else {
    df_content <- jsonlite::fromJSON(content(response, "text", encoding = "UTF-8"))
    if (is.data.frame(df_content)) {
      df_content <- df_content |>
        dplyr::mutate(indicator = resource) |>
        dplyr::rename(value = x)

      return(df_content)
    } else {
      message(paste0("No data returned for: \n", X_JSON))
    }
  }
}

query_filters <- function(resource, year, level) {
  response <- httr::GET(
    url = "https://api.mapineq.org",
    path = "functions/postgisftw.get_column_values_source_json/items.json",
    query = list(
      `_resource` = resource,
      source_selections = toJSON(list(
        year = year,
        level = level,
        selected = list()
      ), auto_unbox = TRUE)
    ),
    config = config(ssl_verifypeer = FALSE) # TODO: REMOVE WHEN SSL RENEWED
  )
  result <- content(response, "text", encoding = "UTF-8")
  return(result)
}
