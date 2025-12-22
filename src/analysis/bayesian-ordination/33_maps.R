# maps_impute_plots_minimal.R
# Requires: sf, dplyr, ggplot2, viridis, readr
# Produces side-by-side observed vs full-coverage maps (PNG)

rm(list = ls())
gc()

required_packages <- c("sf", "dplyr", "ggplot2", "viridis", "readr")
install.packages(setdiff(required_packages, installed.packages()[, "Package"]))

library(sf)
library(dplyr)
library(ggplot2)
library(viridis)
library(readr)
library(grid)

#--- Paths ---#
analysis_dir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "analysis")
impute_dir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "impute")
dbdir <- file.path(getwd(), "src", "database", "db-data")
outdir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "maps")
indir <- file.path(getwd(), "wd", "in")
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

#--- Load data ---#
fit <- readRDS(file.path(analysis_dir, "fit.rds"))

md_orig <- read_csv(file.path(analysis_dir, "md.csv"), show_col_types = FALSE) # observed with gaps
md_full <- read_csv(file.path(impute_dir, "md.csv"), show_col_types = FALSE) # full coverage (imputed where needed)

imp_flag_path <- file.path(impute_dir, "imputed.csv") # optional: 0/1 flags
imp_flag <- if (file.exists(imp_flag_path)) read_csv(imp_flag_path, show_col_types = FALSE) else NULL

nuts <- st_read(file.path(dbdir, "NUTS_RG_20M_2021_4326.geojson"), quiet = TRUE)
if (!"NUTS_ID" %in% names(nuts)) stop("Expected NUTS_ID field in geojson.")
nuts <- nuts %>% rename(geo = NUTS_ID)

var_names <- read_csv(file.path(indir, "varnames.csv"), show_col_types = FALSE)

#--- Standardize GEO IDs ---#
md_orig$geo <- toupper(trimws(as.character(md_orig$geo)))
md_full$geo <- toupper(trimws(as.character(md_full$geo)))
nuts$geo <- toupper(trimws(as.character(nuts$geo)))
if (!is.null(imp_flag)) imp_flag$geo <- toupper(trimws(as.character(imp_flag$geo)))

#--- Helper: get NUTS-2 polygons ---#
crop_to_europe <- function(nuts_sf) {
  # Crop extent: continental Europe + Iceland + Scandinavia (excludes FR overseas)
  # tweak if needed
  bbox <- sf::st_bbox(
    c(xmin = -26, xmax = 45, ymin = 25, ymax = 72),
    crs = sf::st_crs(4326)
  )

  # ensure CRS is lon/lat WGS84 before cropping
  if (sf::st_crs(nuts_sf)$epsg != 4326) nuts_sf <- sf::st_transform(nuts_sf, 4326)

  sf::st_crop(nuts_sf, bbox)
}

get_nuts2 <- function(nuts_sf) {
  if ("LEVL_CODE" %in% names(nuts_sf)) {
    nuts_sf <- nuts_sf %>% dplyr::filter(as.numeric(LEVL_CODE) == 2)
  } else {
    nuts_sf <- nuts_sf %>% dplyr::filter(nchar(geo) == 4)
  }
  crop_to_europe(nuts_sf)
}

#--- Plot function ---#
plot_indicator_maps <- function(
    indicator_col,
    md_gappy,
    md_full,
    nuts_sf,
    out_png,
    var_names,
    imp_flag = NULL,
    palette = "plasma",
    width_px = 4200,
    height_px = 2100,
    dpi = 300) {
  if (!indicator_col %in% names(md_gappy)) stop("indicator_col not found in md_gappy: ", indicator_col)
  if (!indicator_col %in% names(md_full)) stop("indicator_col not found in md_full: ", indicator_col)

  # title label from var_names (fallback to indicator_col)
  title_label <- var_names %>%
    filter(variable_name == indicator_col) %>%
    pull(custom_name) %>%
    .[!is.na(.) & . != ""] %>%
    dplyr::first()

  if (is.null(title_label) || length(title_label) == 0) title_label <- indicator_col

  nuts2 <- get_nuts2(nuts_sf)

  lkp_gappy <- tibble(geo = md_gappy$geo, original = suppressWarnings(as.numeric(md_gappy[[indicator_col]])))
  lkp_full <- tibble(geo = md_full$geo, full = suppressWarnings(as.numeric(md_full[[indicator_col]])))

  map_df <- nuts2 %>%
    select(geo, geometry) %>%
    left_join(lkp_gappy, by = "geo") %>%
    left_join(lkp_full, by = "geo")

  if (!is.null(imp_flag) && indicator_col %in% names(imp_flag)) {
    flag_lkp <- tibble(geo = imp_flag$geo, flag = suppressWarnings(as.numeric(imp_flag[[indicator_col]])))
    map_df <- map_df %>%
      left_join(flag_lkp, by = "geo") %>%
      mutate(was_imputed = (flag == 1))
  } else {
    map_df <- map_df %>% mutate(was_imputed = is.na(original) & !is.na(full))
  }

  vals <- map_df$full
  vals <- vals[is.finite(vals)]
  if (length(vals) == 0) stop("No finite values found for indicator: ", indicator_col)
  vmin <- min(vals, na.rm = TRUE)
  vmax <- max(vals, na.rm = TRUE)

  map_theme <- theme_minimal() +
    theme(
      axis.title = element_blank(),
      axis.text = element_blank(),
      panel.grid = element_blank(),
      legend.position = "right",
      plot.title = element_text(size = 13, face = "bold")
    )

  p_obs <- ggplot(map_df) +
    geom_sf(aes(fill = original), color = "grey60", size = 0.08) +
    scale_fill_viridis_c(option = palette, na.value = "grey95", limits = c(vmin, vmax)) +
    coord_sf(xlim = c(-26, 45), ylim = c(25, 72), expand = FALSE) +
    ggtitle(paste0(title_label, "\nObserved (gaps shown)")) +
    labs(fill = title_label) +
    map_theme

  p_full <- ggplot(map_df) +
    geom_sf(aes(fill = full), color = "grey60", size = 0.08) +
    geom_sf(
      data = filter(map_df, was_imputed %in% TRUE),
      fill = NA, color = "black", linetype = "dashed", size = 0.25
    ) +
    scale_fill_viridis_c(option = palette, limits = c(vmin, vmax)) +
    coord_sf(xlim = c(-26, 45), ylim = c(25, 72), expand = FALSE) +
    ggtitle(paste0(title_label, "\nFull coverage (imputed missing)")) +
    labs(fill = title_label) +
    map_theme

  png(out_png, width = width_px, height = height_px, res = dpi)
  grid.newpage()
  pushViewport(viewport(layout = grid.layout(1, 2)))
  print(p_obs, vp = viewport(layout.pos.row = 1, layout.pos.col = 1))
  print(p_full, vp = viewport(layout.pos.row = 1, layout.pos.col = 2))
  dev.off()

  invisible(list(observed = p_obs, full = p_full, data = map_df, title_label = title_label))
}


#--- Run (edit indicator as needed) ---#
model_vars <- lavaan::lavNames(fit, type = "ov.nox")

for (indicator_col in model_vars) {
  out_png_path <- file.path(outdir, paste0(indicator_col, "_maps.png"))

  plot_indicator_maps(
    indicator_col = indicator_col,
    var_names = var_names,
    md_gappy = md_orig,
    md_full = md_full,
    nuts_sf = nuts,
    out_png = out_png_path,
    imp_flag = imp_flag
  )
}
