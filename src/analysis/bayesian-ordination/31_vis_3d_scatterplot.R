# cleanup
rm(list = ls())
gc()

# install libraries (if needed)
required_packages <- c("plotly", "htmlwidgets") # "befa"
install.packages(setdiff(required_packages, installed.packages()[, "Package"]))

# load libraries
library(plotly)
library(htmlwidgets)
future::plan("multicore")
options(mc.cores = 4)

# # load functions
# source(file.path(getwd(), "src", "analysis", "bayesian-ordination", "3_vis_fun.R"))

# directories
datdir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "analysis")
outdir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "vis_3d_scatterplot")
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

# load data
fit <- readRDS(file.path(datdir, "fit.rds"))
md <- read.csv(file.path(datdir, "md.csv"))

#---- prepare data ----#

# factor scores
fscores <- lavPredict(fit, type = "lv") # matrix with one column per latent

# data
df <- cbind(md, as.data.frame(fscores)) %>%
  mutate(
    Country = substr(geo, 1, 2),
    CaseID = paste0(geo_name, " [", geo, "]")
  )

# variables
orig_vars <- md %>%
  select(-all_of(c("data_year", "geo", "geo_name", "geo_source", "geo_year"))) %>%
  colnames()
latents <- colnames(fscores)
all_choices <- c(latents, orig_vars)


#---- interactive 3D scatterplot ----#

# axis selection drop-down
make_axis_menu <- function(axis, button_y) {
  buttons <- lapply(all_choices, function(var) {
    list(
      method = "update",
      args = list(
        # first list: traces to update
        list(
          x = if (axis == "x") list(df[[var]]) else NULL,
          y = if (axis == "y") list(df[[var]]) else NULL,
          z = if (axis == "z") list(df[[var]]) else NULL
        ),
        # second list: layout updates
        list(
          scene = list(
            xaxis = list(title = if (axis == "x") var else NULL),
            yaxis = list(title = if (axis == "y") var else NULL),
            zaxis = list(title = if (axis == "z") var else NULL)
          )
        )
      ),
      label = var
    )
  })

  list(
    x = if (axis == "x") 0.15 else if (axis == "y") 0.50 else 0.85,
    y = button_y,
    buttons = buttons,
    direction = "down",
    showactive = TRUE,
    pad = list(r = 10, t = 10),
    xanchor = "left",
    yanchor = "top",
    type = "dropdown"
  )
}

# make plot
p <- plot_ly(
  data = df,
  x = ~ get(latents[1]), # initial axes
  y = ~ get(latents[2]),
  z = ~ get(latents[3]),
  color = ~Country, # colour by country
  colors = "Set1", # optional palette
  key = ~CaseID,
  text = ~ paste0(
    "Case: ", CaseID,
    "<br>", latents[1], " = ", round(get(latents[1]), 2),
    "<br>", latents[2], " = ", round(get(latents[2]), 2),
    "<br>", latents[3], " = ", round(get(latents[3]), 2)
  ),
  hoverinfo = "text",
  mode = "markers",
  type = "scatter3d",
  marker = list(size = 5, opacity = 0.8)
) %>%
  layout(
    title = "Mapineq Multivariate Space",
    scene = list(
      xaxis = list(title = latents[1]),
      yaxis = list(title = latents[2]),
      zaxis = list(title = latents[3])
    ),
    updatemenus = list(
      # three dropdown menus, one for each axis
      make_axis_menu("x", 0.95),
      make_axis_menu("y", 0.65),
      make_axis_menu("z", 0.35)
    )
  )

# save to html
saveWidget(p,
  file = file.path(outdir, "3d_scatterplot.html"),
  selfcontained = TRUE
)
