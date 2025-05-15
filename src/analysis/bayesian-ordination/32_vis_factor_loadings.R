# cleanup
rm(list = ls())
gc()

# install libraries (if needed)
required_packages <- c("blavaan", "tidyverse", "ggridges")
install.packages(setdiff(required_packages, installed.packages()[, "Package"]))

# load libraries
library(blavaan)    # for bsem(), standardizedPosterior()
library(tidyverse)  # for as_tibble(), pivot_longer(), separate(), ggplot2
library(ggridges)   # for geom_density_ridges()

# directories
datdir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "analysis")
outdir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "vis_factor_loadings")
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

# load data
fit <- readRDS(file.path(datdir, "fit.rds"))
md <- read.csv(file.path(datdir, "md.csv"))

# get posterior samples
std_post <- standardizedPosterior(fit)

# identify factor loadings
loading_cols <- grep("=~", colnames(std_post), value = TRUE)

# extract factor loading posterior samples in long format
draws_long <- as_tibble(std_post[, loading_cols]) %>%
  pivot_longer(everything(), names_to = "param", values_to = "value") %>%
  separate(param, into = c("factor", "indicator"), sep = "=~")

# sort by means
order_df <- draws_long %>%
  group_by(indicator) %>%
  summarize(mean = mean(value)) %>%
  arrange(mean)
draws_long$indicator <- factor(draws_long$indicator, levels = order_df$indicator)

# ridge plot
p <- ggplot(draws_long, aes(x = value, y = indicator)) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  geom_density_ridges(scale = 1) +
  facet_wrap(~ factor, scales = "free_y") +
  labs(
    title =   "Posterior Distributions of Standardized Factor Loadings",
    x =       "Standardized loading",
    y =       "Indicator"
  ) +
  theme_minimal()

# save to disk
ggsave(
  filename = file.path(outdir, "ridge_plot.jpg"),
  plot = p,
  width = 8,
  height = 6,
  dpi = 300
)
