# cleanup
rm(list = ls())
gc()

# install / load
required_packages <- c("plotly", "htmlwidgets", "dplyr", "lavaan")
install.packages(setdiff(required_packages, installed.packages()[, "Package"]))
library(plotly)
library(htmlwidgets)
library(dplyr)
library(lavaan)

# directories
datdir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "analysis")
outdir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "vis_3d_scatterplot")
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

# load
fit <- readRDS(file.path(datdir, "fit.rds"))
md <- read.csv(file.path(datdir, "..", "impute", "md.csv"))

# prep data
fscores <- lavPredict(fit, type = "lv")
df <- bind_cols(md, as.data.frame(fscores)) %>%
  mutate(
    Country = substr(geo, 1, 2),
    CaseID  = paste0(geo_name, " [", geo, "]")
  )

orig_vars <- setdiff(names(md), c("data_year", "geo", "geo_name", "geo_source", "geo_year"))
latents <- colnames(fscores)
all_choices <- c(latents, orig_vars)

# remove original variables (for efficiency while testing)
df <- df %>%
  select(CaseID, Country, all_of(latents))
all_choices <- c(latents)

# helper for menus
make_axis_menu <- function(axis, xpos, current_axes) {
  buttons <- lapply(all_choices, function(var) {
    new_axes <- current_axes
    new_axes[which(c("x", "y", "z") == axis)] <- var

    new_text <- paste0(
      "Case: ", df$CaseID,
      "<br>", new_axes[1], " = ", round(df[[new_axes[1]]], 2),
      "<br>", new_axes[2], " = ", round(df[[new_axes[2]]], 2),
      "<br>", new_axes[3], " = ", round(df[[new_axes[3]]], 2)
    )

    list(
      method = "update",
      args = list(
        list(
          x = if (axis == "x") list(df[[var]]) else NULL,
          y = if (axis == "y") list(df[[var]]) else NULL,
          z = if (axis == "z") list(df[[var]]) else NULL,
          color = list(df$Country),
          text = list(new_text)
        ),
        list(
          scene = list(
            xaxis = list(title = new_axes[1]),
            yaxis = list(title = new_axes[2]),
            zaxis = list(title = new_axes[3])
          )
        )
      ),
      label = var
    )
  })

  list(
    active     = which(all_choices == current_axes[which(c("x", "y", "z") == axis)]) - 1,
    type       = "dropdown",
    direction  = "down",
    showactive = TRUE,
    x          = xpos,
    y          = 1.15,
    xanchor    = "left",
    yanchor    = "bottom",
    pad        = list(r = 10, t = 10),
    buttons    = buttons
  )
}

# initial axes
current_axes <- latents[1:3]

# spacing for menus
button_width <- 0.11 # width of each dropdown in normalized coords
base_x <- 0.05 # leftmost start
menu_positions <- base_x + button_width * c(0, 1, 2)

# build the plot
p <- plot_ly(
  df,
  x = ~ get(current_axes[1]),
  y = ~ get(current_axes[2]),
  z = ~ get(current_axes[3]),
  color = ~Country,
  colors = "Set1",
  key = ~CaseID,
  text = ~ paste0(
    "Case: ", CaseID,
    "<br>", current_axes[1], " = ", round(get(current_axes[1]), 2),
    "<br>", current_axes[2], " = ", round(get(current_axes[2]), 2),
    "<br>", current_axes[3], " = ", round(get(current_axes[3]), 2)
  ),
  hoverinfo = "text",
  mode = "markers",
  type = "scatter3d",
  marker = list(size = 5, opacity = 0.8)
) %>%
  layout(
    title = "Mapineq Multivariate Space",
    scene = list(
      xaxis = list(title = current_axes[1]),
      yaxis = list(title = current_axes[2]),
      zaxis = list(title = current_axes[3])
    ),
    updatemenus = list(
      make_axis_menu("x", menu_positions[1], current_axes),
      make_axis_menu("y", menu_positions[2], current_axes),
      make_axis_menu("z", menu_positions[3], current_axes)
    )
  )

# write out
saveWidget(
  p,
  file          = file.path(outdir, "3d_scatterplot.html"),
  selfcontained = TRUE
)
