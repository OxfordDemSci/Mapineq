# cleanup
rm(list = ls())
gc()

# install / load
required_packages <- c("plotly", "htmlwidgets", "dplyr", "lavaan", "RColorBrewer")
install.packages(setdiff(required_packages, installed.packages()[, "Package"]))
library(plotly)
library(htmlwidgets)
library(dplyr)
library(lavaan)
library(RColorBrewer)

# directories
srcdir <- file.path(getwd(), "src", "analysis", "bayesian-ordination")
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

orig_vars <- lavaan::lavNames(fit, type="ov.nox")
latents <- colnames(fscores)
all_choices <- c(latents, orig_vars) # dropped orig_vars for testing

# remove originals for speed
df <- df %>% select(CaseID, Country, all_of(all_choices))

# assign a distinct hex-colour to each of the 37 countries
n_ct <- length(unique(df$Country))
pal <- colorRampPalette(brewer.pal(9, "Set1"))(n_ct)
df$colHex <- pal[as.numeric(factor(df$Country))]

# initial axes
current_axes <- latents[1:3]

# build the multi-trace plot (one trace per country)
p <- plot_ly()
for (cty in unique(df$Country)) {
  dsub <- df[df$Country == cty, ]
  p <- add_trace(
    p,
    data = dsub,
    x = ~ get(current_axes[1]),
    y = ~ get(current_axes[2]),
    z = ~ get(current_axes[3]),
    type = "scatter3d",
    mode = "markers",
    marker = list(
      color   = dsub$colHex,
      size    = 5,
      opacity = 0.8
    ),
    key = ~CaseID,
    text = ~ paste0(
      "Case: ", CaseID,
      "<br>", current_axes[1], " = ", round(get(current_axes[1]), 2),
      "<br>", current_axes[2], " = ", round(get(current_axes[2]), 2),
      "<br>", current_axes[3], " = ", round(get(current_axes[3]), 2)
    ),
    hoverinfo = "text",
    name = cty,
    legendgroup = cty,
    showlegend = TRUE
  )
}

p <- p %>% layout(
  # template = "plotly_dark",
  title = list(
    text = "Mapineq Ordination Space",
    font = list(color = "white")
  ),
  paper_bgcolor = "black",
  plot_bgcolor  = "black",
  legend = list(
    font = list(color="white")
  ),
  scene = list(
    xaxis = list(
      title = list(
        text = current_axes[1], 
        font = list(color="white")
      ),
      tickfont = list(color = "white"),
      backgroundcolor = "black",
      gridcolor       = "white",
      zerolinecolor   = "white"
    ),
    yaxis = list(
      title = list(
        text = current_axes[2], 
        font = list(color="white")
      ),
      tickfont = list(color = "white"),
      backgroundcolor = "black",
      gridcolor       = "white",
      zerolinecolor   = "white"
    ),
    zaxis = list(
      title = list(
        text = current_axes[3], 
        font = list(color="white")
      ),
      tickfont = list(color = "white"),
      backgroundcolor = "black",
      gridcolor       = "white",
      zerolinecolor   = "white"
    )
  )
)

# inject js
p <- p %>% onRender(
  htmlwidgets::JS(
    paste0(
      readLines(file.path(srcdir, "31_vis_3d_scatterplot.js"), warn = FALSE),
      collapse = "\n"
    )
  ),
  data = list(df = df, all_choices = all_choices, current_axes = current_axes)
)

# write out
saveWidget(
  p,
  file          = file.path(outdir, "3d_scatterplot.html"),
  selfcontained = TRUE
)
