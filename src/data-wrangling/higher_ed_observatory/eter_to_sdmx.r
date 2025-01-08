# load libraries
library(dplyr)
library(tidyr)
library(stringr)
library(purrr)

# directories
indir <- file.path("wd", "in", "data-wrangling", "higher_ed_observatory")
outdir <- file.path("src", "database", "db-data")

# load data
eter_data <- read.csv(file.path(indir, "eter-export-all.csv"), sep = ";")

# data dictionary
eter_dict <- as.vector(eter_data[1, ])

# drop first row from data that contains column descriptions
eter_data <- eter_data[-1, ]

# data dictionary as data.frame
eter_dict_df <- data.frame(
  col = names(eter_dict),
  desc = unlist(eter_dict, use.names = FALSE)
)
View(eter_dict_df)

# cleanup categories
category_map <- list(
  "Free-standing higher education institution" = c(
    "Free-standing higher education institution",
    "Free-standing higher education institutions"
  ),
  "Other" = c("m")
)

category_lookup <- tibble::enframe(category_map, name = "standard", value = "variants") |>
  unnest(variants)


# count of institutions by NUTS-2 and NUTS-3
inst_nuts <- eter_data |>
  # create "All" category
  bind_rows(
    eter_data |>
      mutate(BAS.INSTCATENGL = "All")
  ) |>
  # Pivot GEO.NUTS1 and GEO.NUTS2 into a single column `geo`
  pivot_longer(cols = c(GEO.NUTS2, GEO.NUTS3), names_to = "geo_type", values_to = "geo") %>%
  # select and rename rows needed
  select(BAS.ETERID, BAS.REFYEAR, BAS.INSTCATENGL, geo) |>
  rename(
    id = BAS.ETERID,
    category = BAS.INSTCATENGL,
    obsTime = BAS.REFYEAR
  ) |>
  # apply category lookup to rename/merge some categories
  left_join(category_lookup, by = c("category" = "variants")) |>
  mutate(category = if_else(!is.na(standard), standard, category)) |>
  select(-standard) |>
  # standardise caplitalisation to avoid duplicate categories
  mutate(
    category = case_when(
      stringr::str_detect(category, "HEI") ~ category, # Keep categories containing "HEI" unchanged
      TRUE ~ paste0(toupper(substr(category, 1, 1)), tolower(substr(category, 2, nchar(category))))
    )
  ) |>
  # get counts by year, region, and category
  group_by(obsTime, geo, category) |>
  summarise(obsValue = n_distinct(id), .groups = "drop") |>
  # fill NA with zeros
  # tidyr::complete(geo, obsTime, category, fill=list(obsValue = 0)) |>

  # Add sorting key to prioritize "All" in category
  mutate(sort_key = if_else(category == "All", 1, 2)) %>%
  # Sort by sort_key and other columns as needed
  arrange(sort_key, category, geo, obsTime) %>%
  # Drop sort_key column after sorting (optional)
  select(-sort_key) |>
  # add id column and arrange columns
  mutate(id = row_number()) |>
  select(id, geo, obsTime, obsValue, category)


# check data
View(inst_nuts)
sort(unique(inst_nuts$category))

# save to disk
write.csv(inst_nuts, file = file.path(outdir, "eter.csv"), row.names = FALSE)
