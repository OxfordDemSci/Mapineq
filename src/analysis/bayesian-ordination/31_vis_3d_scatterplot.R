# cleanup
rm(list = ls())
gc()

# install libraries (if needed)
required_packages <- c("blavaan", "shiny", "plotly", "htmlwidgets") # "befa"
install.packages(setdiff(required_packages, installed.packages()[, "Package"]))

# load libraries
library(lavaan)
library(shiny)
library(plotly)
library(htlmwidgets)
future::plan("multicore")
options(mc.cores=4)

# # load functions
# source(file.path(getwd(), "src", "analysis", "bayesian-ordination", "3_vis_fun.R"))

# directories
datdir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "analysis")
outdir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "vis_3d_scatterplot")
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

# load data
fit <- readRDS(file.path(datdir, "fit.rds"))


# Extract posterior means of factor scores
fscores <- lavPredict(fit, type = "lv")  # matrix with one column per latent
df <- as.data.frame(fscores)
df$CaseID <- rownames(df)

# Select latent variables 
latents <- sample(colnames(fscores), 3)

#---- ChatGPT prototype suggestion ----#


p <- plot_ly(
  data      = df,
  x         = ~get(latents[1]),
  y         = ~get(latents[2]),
  z         = ~get(latents[3]),
  key       = ~CaseID,
  text      = ~paste0(
                "Case: ", CaseID,
                "<br>", latents[1], " = ", round(get(latents[1]),2),
                "<br>", latents[2], " = ", round(get(latents[2]),2),
                "<br>", latents[3], " = ", round(get(latents[3]),2)
              ),
  hoverinfo = "text",
  mode      = "markers",
  type      = "scatter3d",
  marker    = list(size = 5)
) %>%
  layout(
    scene = list(
      xaxis = list(title = latents[1]),
      yaxis = list(title = latents[2]),
      zaxis = list(title = latents[3])
    )
  )

# 4) Preview in RStudio Viewer or default browser
p

# 5) (Optional) Export to standalone HTML
saveWidget(p, file.path(outdir, "latent_3d_test.html"), selfcontained = TRUE)

#---- ChatGPT shiny suggestion ----#

# Install if you haven’t already
# install.packages(c("shiny","plotly","blavaan"))

library(shiny)
library(plotly)
library(blavaan)
library(lavaan)

# ——————————————————————————————
# 1) Fit your model (example)
# fit <- blavaan::bcfa(...)

# 2) Extract posterior means of factor scores
# Replace 'fit' with your actual blavaan object
fscores <- lavPredict(fit, type = "lv")  # matrix with one column per latent
df <- as.data.frame(fscores)
df$CaseID <- rownames(df)

# Suppose your three latents are named "F1", "F2", "F3"
# If they have different names, adapt below:
latents <- sample(colnames(fscores), 3)

# 3) Build Shiny app
ui <- fluidPage(
  titlePanel("3D latent-space plot"),
  sidebarLayout(
    sidebarPanel(
      p("Click on a point to see its metadata below:")
    ),
    mainPanel(
      plotlyOutput("latentPlot", height = "600px"),
      verbatimTextOutput("clickInfo")
    )
  )
)

server <- function(input, output, session) {
  
  output$latentPlot <- renderPlotly({
    plot_ly(
      data = df,
      x = ~get(latents[1]),
      y = ~get(latents[2]),
      z = ~get(latents[3]),
      key = ~CaseID,            # use 'key' for click events
      text = ~paste("Case:", CaseID,
                    "<br>", latents[1], "=", round(get(latents[1]),2),
                    "<br>", latents[2], "=", round(get(latents[2]),2),
                    "<br>", latents[3], "=", round(get(latents[3]),2)),
      hoverinfo = "text",
      mode = "markers",
      type = "scatter3d",
      marker = list(size = 5)
    ) %>% 
      layout(scene = list(
        xaxis = list(title = latents[1]),
        yaxis = list(title = latents[2]),
        zaxis = list(title = latents[3])
      ))
  })
  
  # 4) Show clicked point’s info
  output$clickInfo <- renderPrint({
    d <- event_data("plotly_click")
    if (is.null(d)) {
      "Click on a point to see details here."
    } else {
      # d$key contains the CaseID
      sel <- df[df$CaseID == d$key, ]
      sel  # prints the entire row; you can format as you like
    }
  })
}

# 5) Run the app
shinyApp(ui, server)
