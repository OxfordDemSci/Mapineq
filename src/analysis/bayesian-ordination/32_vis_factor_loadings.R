# cleanup
rm(list = ls())
gc()

# install libraries (if needed)
required_packages <- c("blavaan", "tidyverse", "ggridges")
install.packages(setdiff(required_packages, installed.packages()[, "Package"]))

# load libraries
library(blavaan) # for bsem(), standardizedPosterior()
library(tidyverse) # for as_tibble(), pivot_longer(), separate(), ggplot2
library(ggridges) # for geom_density_ridges()
library(stringr)

# directories
indir <- file.path(getwd(), "wd", "in")
datdir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "analysis")
outdir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "vis_factor_loadings")
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

# load data
fit <- readRDS(file.path(datdir, "fit.rds"))
md <- read.csv(file.path(datdir, "md.csv"))
var_names <- read.csv(file.path(indir, "varnames.csv"))

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
# draws_long$indicator <- factor(draws_long$indicator, levels = order_df$indicator)

# interpretable indicator names
lookup_table <- var_names %>%
  filter(select_y == 1) %>%
  select(variable_name, custom_name)

draws_long <- draws_long %>%
  left_join(lookup_table, by = c("indicator" = "variable_name")) %>%
  mutate(indicator_label = coalesce(custom_name, indicator)) %>%
  left_join(order_df, by = "indicator") %>%
  mutate(indicator_label = fct_reorder(indicator_label, mean))


# make ridge plots for each factor
for (f in unique(draws_long$factor)) {
  factor_data <- draws_long %>% filter(factor == f)
  n_indicators <- n_distinct(factor_data$indicator_label)
  dynamic_height <- max(4, n_indicators * 0.8)

  p <- ggplot(factor_data, aes(x = value, y = indicator_label, fill = factor)) +
    geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.5) +
    geom_density_ridges(scale = 1.2, alpha = 0.7, rel_min_height = 0.01) +
    scale_y_discrete(labels = function(x) str_wrap(x, width = 30)) +
    scale_fill_viridis_d(guide = "none") +
    labs(
      title = paste("Standardized Factor Loadings:", f),
      subtitle = "Posterior distributions (ordered by mean loading)",
      x = "Standardized Loading",
      y = NULL
    ) +
    theme_minimal() +
    theme(
      axis.text.y = element_text(size = 9),
      plot.title = element_text(face = "bold"),
      panel.grid.minor = element_blank()
    )

  file_name <- paste0("loadings_", str_to_lower(f), ".jpg")
  ggsave(
    filename = file.path(outdir, file_name),
    plot = p,
    width = 7,
    height = dynamic_height,
    dpi = 300
  )
}
