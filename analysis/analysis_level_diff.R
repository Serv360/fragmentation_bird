# ================================================ #
# ================== Packages ==================== #
# ================================================ #

library(tidyverse)
library(dplyr)
library(lmtest)
library(sandwich)

# ================================================ #
# ================= Main path ==================== #
# ================================================ #

main_path <- "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP"

# ================================================ #
# ================= Functions ==================== #
# ================================================ #

# Function to regress y on x and produce a clean table
regression_table_long <- function(data, y, x, x2, x_controls, col_to_stand, interaction=FALSE, standardise=TRUE, square=FALSE) {
  # Build formula
  
  if (standardise) {
    data <- data %>%
      mutate(across(col_to_stand, scale))
  }
  if (interaction & square) {
    print("Interaction and square shouldn't be TRUE at the same time")
    return(0)  
    }
  
  if (interaction) {
    if (length(x_controls) > 0) {
      formula <- as.formula(paste(y, "~", x, " * ", x2, " + ", paste(x_controls, collapse = " + ")))
      print(formula)
    } else {
      formula <- as.formula(paste(y, "~", x, " * ", x2))
    }
  } else if (square) {
    if (length(x_controls) > 0) {
      formula <- as.formula(paste(y, "~", x, " + I(", x, "^2)", " + ", paste(x_controls, collapse = " + ")))
    } else {
      formula <- as.formula(paste(y, "~", x, " + I(", x, "^2)",))
    }
  } else {
    if (length(x_controls) > 0) {
      formula <- as.formula(paste(y, "~", x, " + ", paste(x_controls, collapse = " + ")))
    } else {
      formula <- as.formula(paste(y, "~", x))
    }
  }
  
    
  
  # Run linear model
  model <- lm(formula, data = data)
  
  # Output table
  
  return(model)
}

plot_forest_by_category_pretty <- function(data, 
                                           x_diffs, 
                                           y_base_names,
                                           bird_categories,
                                           x_controls,
                                           x_names,
                                           thresholds = NA,
                                           interaction = FALSE,
                                           standardise = TRUE,
                                           split_thresh = FALSE) {
  results <- list()
  
  for (x in x_diffs) {
    for (cat in bird_categories) {
      for (y_base in y_base_names) {
        y <- paste0(y_base, "_", cat)
        cols_to_standardise <- unique(c(x_controls, y, x))
        
        if (split_thresh) {
          absolute_metric <- sub("^diff_", "", x)
          absolute_index <- sub("^diff_", "", y)
          threshold <- thresholds %>%
            filter(category == cat,
                   y_var == absolute_index,
                   x_var == absolute_metric) %>%
            pull(breakpoint)
          
          print(threshold)
          
          # BELOW threshold model
          model_below <- regression_table_long(
            data %>% filter(!!sym(absolute_metric) < threshold),
            y, x, x2 = "", x_controls, cols_to_standardise, interaction, standardise
          )
          
          tidy_below <- broom::tidy(model_below, conf.int = TRUE) %>%
            filter(term == x) %>%
            mutate(
              predictor = x,
              metric = y_base,
              category = cat,
              split = "Below"
            )
          
          # ABOVE or EQUAL threshold model
          model_above <- regression_table_long(
            data %>% filter(!!sym(absolute_metric) >= threshold),
            y, x, x2 = "", x_controls, cols_to_standardise, interaction, standardise
          )
          
          tidy_above <- broom::tidy(model_above, conf.int = TRUE) %>%
            filter(term == x) %>%
            mutate(
              predictor = x,
              metric = y_base,
              category = cat,
              split = "Above"
            )
          
          predictor_rows <- bind_rows(tidy_below, tidy_above)
        } else {
          model <- regression_table_long(
            data, y, x, x2 = "", x_controls, cols_to_standardise, interaction, standardise
          )
          
          predictor_rows <- broom::tidy(model, conf.int = TRUE) %>%
            filter(term == x) %>%
            mutate(
              predictor = x,
              metric = y_base,
              category = cat,
              split = "All"
            )
        }
        
        results[[length(results) + 1]] <- predictor_rows
      }
    }
  }
  
  coef_df <- bind_rows(results)
  
  coef_df <- coef_df %>%
    mutate(
      predictor = x_names[predictor],
      metric = factor(metric, levels = y_base_names),
      predictor = factor(predictor, levels = x_names[x_diffs]),
      category = factor(category, levels = bird_categories),
      split = factor(split, levels = c("Below", "Above", "All"))
    )
  
  levels(coef_df$predictor) <- gsub("diff_", "\u0394", levels(coef_df$predictor))
  levels(coef_df$metric) <- gsub("diff_", "\u0394", levels(coef_df$metric))
  levels(coef_df$metric) <- gsub("_", " ", levels(coef_df$metric))
  
  if (split_thresh) {
    x_min <- -1
    x_max <- 1

    # Clip confidence intervals
    coef_df <- coef_df %>%
      mutate(
        conf.low = pmax(conf.low, x_min),
        conf.high = pmin(conf.high, x_max)
      ) %>%
      # Remove rows with estimate outside plot range
      filter(estimate >= x_min, estimate <= x_max)
  }
  
  if (split_thresh) {
    breaks_x <- c(-1, -0.5, 0, 0.5, 1)
  } else {
    breaks_x <- c(-0.3, -0.2, -0.1, 0, 0.1, 0.2, 0.3)
  }
  
  # Plot
  ggplot(coef_df, aes(x = estimate, y = fct_rev(category), color = metric, shape = split)) +
    geom_point(size = 2.5, position = position_dodge(width = 0.7)) +
    geom_errorbarh(aes(xmin = conf.low, xmax = conf.high), height = 0.2, position = position_dodge(width = 0.7)) +
    facet_grid(predictor ~ metric, scales = "free_y", space = "free_y") +
    geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
    scale_color_brewer(palette = "Set2") +
    scale_shape_manual(values = c("Below" = 16, "Above" = 17, "All" = 15)) +
    scale_x_continuous(breaks = breaks_x) +
    labs(
      title = "Regression Coefficients (with 95% CI)",
      subtitle = "Grouped by Metric, Biodiversity Index, and Split",
      x = "",
      y = "Category",
      color = "Biodiversity Index",
      shape = "Data Split"
    ) +
    theme_minimal(base_size = 13) +
    theme(
      strip.text = element_text(face = "bold", size = 11),
      strip.text.y.left = element_text(margin = margin(r = 12)),
      axis.text.y = element_text(size = 11),
      axis.title.y = element_text(margin = margin(r = 7)),
      legend.position = "top",
      panel.spacing.y = unit(1.5, "lines")
    )
}



regression_table_double <- function(data, y, x, x2, x_controls, col_to_stand, interaction=TRUE, standardise=TRUE) {
  # Build formula
  
  if (standardise) {
    data <- data %>%
      mutate(across(all_of(col_to_stand), scale))
  } else {
    print(col_to_stand)
  }
  
  if (interaction) {
    if (length(x_controls) > 0) {
      formula <- as.formula(paste(y, "~", x, " * ", x2, " + ", paste(x_controls, collapse = " + ")))
    } else {
      formula <- as.formula(paste(y, "~", x, " * ", x2))
    }
  } else {
    if (length(x_controls) > 0) {
      formula <- as.formula(paste(y, "~", x, " + ", paste(x_controls, collapse = " + ")))
    } else {
      formula <- as.formula(paste(y, "~", x))
    }
  }
  
  
  
  # Run linear model
  model <- lm(formula, data = data)
  
  # Clustered standard errors by a column (e.g., cluster_id)
  cl_vcov <- vcovCL(model, cluster = ~site)
  
  # Print model summary with clustered SEs
  coeftest(model, vcov. = cl_vcov)
}

# ================================================ #
# ============= Global variables ================= #
# ================================================ #


# Read the data
diff_path <- paste0(main_path, "/data/merged_data/difference_data_all_three.csv")
diff_data <- read_csv(diff_path)
final_path <- paste0(main_path, "/data/merged_data/final_data_all_three.csv")
final_data <- read_csv(final_path)

# ================================================ #
# ==================== Calls ===================== #
# ================================================ #

# Calls should be uncommented one at a time.

# ================================================ #

# y <- "Total_Abundance_woodland"
# x <- "COH"
# x2 <- "truc"
# x_controls <- c("perc3", "temperature_moyenne24h", "precipitation_somme24h", "radiation_somme24h", "alt", "latitude")
# col_to_stand <- c(x_controls, y, x)
# 
# # final_data <- final_data %>%
# #   mutate(across(c(x_controls, y, x), scale))
# # final_data <- final_data %>% filter(year!=2012)
# # final_data <- final_data %>% filter(perc4 < 0.2) %>%
# #   mutate(dummy_year = ifelse(year == 2008, 0,
# #                              ifelse(year == 2018, 1, NA))) %>%
# #   filter(abs(MSIZ) < 4000000)
# 
# final_data <- final_data %>% mutate(COH = COH*100) %>%
#   mutate(CBC_MSIZ_share = CBC_MSIZ_share*100) %>%
#   filter(perc4 < 20) %>% filter(perc3<25)
# 
# result <- regression_table_long(final_data, y, x, x2, x_controls, col_to_stand, interaction = FALSE, standardise = TRUE, square=FALSE)
# 
# #summary(result)
# # Clustered standard errors by a column (e.g., cluster_id)
# cl_vcov <- vcovCL(result, cluster = ~site)
# 
# # Print model summary with clustered SEs
# coeftest(result, vcov. = cl_vcov)


# ================================================ #

# y_diff <- "diff_Total_Abundance_woodland"
# x_diff <- "diff_MSIZ"
# x2_diff <- ""
# x_controls_diff <- c("temperature_moyenne24h", "precipitation_somme24h", "radiation_somme24h", "alt", "latitude")
# col_to_stand <- c(x_controls_diff, y_diff, x_diff)
# 
# diff_data <- diff_data %>% filter(year_diff=="2018-2008")
# diff_data <- diff_data %>%
#   left_join(final_data, by=c("site", "alt", "group", "longitude", "latitude", "year_i"="year")) %>%
#     filter(perc4 < 0.2) %>% filter(MSIZ<100000) %>% filter(abs(diff_MSIZ)<500000)
# print(diff_data %>% count())
# 
# model <- regression_table_long(diff_data, y_diff, x_diff, x2_diff, x_controls_diff, col_to_stand, interaction=FALSE, standardise=TRUE)
# 
# summary(model)

# ================================================ #

# diff_data <- diff_data %>% filter(year_diff=="2018-2008")
# diff_data <- diff_data %>%
#   left_join(final_data, by=c("site", "alt", "group", "longitude", "latitude", "year_i"="year")) %>%
#     filter(perc4 < 20) #%>% filter(abs(diff_MSIZ)<500000) #%>% filter(MSIZ<1000000)
# print(diff_data %>% count())
# 
# x_diffs <- c("diff_COH", "diff_CBC_MSIZ_share", "diff_perc1", "diff_perc2", "diff_perc3")
# x_names <- c("diff_COH", "diff_COH CBC", "diff_urban", "diff_agri", "diff_woodland")
# names(x_names) <- x_diffs
# #y_diffs_woodland <- c("diff_Total_Abundance_woodland", "diff_Species_Richness_woodland", "diff_Simpson_Diversity_woodland", "diff_Shannon_Diversity_woodland")
# y_diffs <- c("diff_Total_Abundance", "diff_Species_Richness", "diff_Shannon_Diversity", "diff_Simpson_Diversity")
# bird_categories <- c("woodland", "urban", "farmland", "generalist", "all")
# x_controls <- c("temperature_moyenne24h", "precipitation_somme24h", "radiation_somme24h", "alt", "latitude")
# 
# plot_forest_by_category_pretty(
#   data = diff_data,
#   x_diffs = x_diffs,
#   y_base_names = y_diffs,
#   bird_categories = bird_categories,
#   x_controls = x_controls,
#   x_names = x_names,
#   interaction = FALSE,
#   standardise = TRUE
# )

# ================================================ #
# Big forest plot with two coefficient for each subset on either side of thresholds.

diff_data <- diff_data %>% filter(year_diff=="2018-2008")
diff_data <- diff_data %>%
  left_join(final_data, by=c("site", "alt", "group", "longitude", "latitude", "year_i"="year")) %>%
  mutate(across(c(COH, diff_COH, diff_CBC_MSIZ_share, CBC_MSIZ_share), ~ .x * 100)) %>%
    filter(perc4 < 20) #%>% filter(perc3 < 18) #%>% filter(abs(diff_MSIZ)<500000) #%>% filter(MSIZ<1000000)
print(diff_data %>% count())

x_diffs <- c("diff_COH", "diff_CBC_MSIZ_share", "diff_perc1", "diff_perc2", "diff_perc3")
x_names <- c("diff_COH", "diff_COH CBC", "diff_urban", "diff_agri", "diff_woodland")
names(x_names) <- x_diffs
#y_diffs_woodland <- c("diff_Total_Abundance_woodland", "diff_Species_Richness_woodland", "diff_Simpson_Diversity_woodland", "diff_Shannon_Diversity_woodland")
y_diffs <- c("diff_Total_Abundance", "diff_Species_Richness", "diff_Shannon_Diversity", "diff_Simpson_Diversity")
bird_categories <- c("woodland", "all")
x_controls <- c("temperature_moyenne24h", "precipitation_somme24h", "radiation_somme24h", "alt", "latitude")

base_path_thresh <- "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/results"

# Load all files into one tibble
threshold_data <- bird_categories %>%
  map_df(~{
    file_path <- file.path(base_path_thresh, paste0("threshold_", .x, ".csv"))
    read_csv(file_path, col_types = cols()) %>%
      mutate(category = .x)
  }) %>%
  dplyr::select(category, y_var, x_var, breakpoint)  # Reorder columns

plot_forest_by_category_pretty(
  data = diff_data,
  x_diffs = x_diffs,
  y_base_names = y_diffs,
  bird_categories = bird_categories,
  x_controls = x_controls,
  x_names = x_names,
  thresholds = threshold_data,
  interaction = FALSE,
  standardise = TRUE,
  split_thresh = TRUE
)

# ================================================ #

# y_diff <- "diff_Total_Abundance_woodland"
# x_diff <- "diff_MSIZ"
# x2_diff <- "truc"
# x_controls_diff <- c("temperature_moyenne24h", "precipitation_somme24h", "radiation_somme24h", "alt", "latitude")
# col_to_stand <- c(x_controls_diff, y_diff, x_diff)
# 
# diff_data <- diff_data %>% filter(year_diff!="2018-2008")
# diff_data <- diff_data %>%
#   left_join(final_data, by=c("site", "alt", "group", "longitude", "latitude", "year_i"="year")) %>%
#     filter(perc4 < 0.2) %>% filter(MSIZ>1000000) %>% filter(abs(diff_MSIZ)<500000)
# 
# 
# regression_table_double(diff_data, y_diff, x_diff, x2_diff, x_controls_diff, col_to_stand, interaction=FALSE, standardise=TRUE)

# ================================================ #

# data_2008 <- final_data %>% filter(year == 2008)
# data_2012 <- final_data %>% filter(year == 2012)
# data_2018 <- final_data %>% filter(year == 2018)
# 
# # Step 2: Select relevant variables and rename
# msiz_2012 <- data_2012 %>%
#   select(site, MSIZ) %>%
#   rename(MSIZ_2012 = MSIZ)
# 
# msiz_2008 <- data_2008 %>%
#   select(site, MSIZ) %>%
#   rename(MSIZ_2008 = MSIZ)
# 
# abwood_2018 <- data_2018 %>%
#   select(site, Species_Richness_woodland) %>%
#   rename(AbWood_2018 = Species_Richness_woodland)
# 
# abwood_2008 <- data_2008 %>%
#   select(site, Species_Richness_woodland) %>%
#   rename(AbWood_2008 = Species_Richness_woodland)
# 
# # Step 3: Join and compute differences
# diffs <- msiz_2012 %>%
#   inner_join(msiz_2008, by = "site") %>%
#   inner_join(abwood_2018, by = "site") %>%
#   inner_join(abwood_2008, by = "site") %>%
#   mutate(
#     diff_MSIZ_2012_2008 = MSIZ_2012 - MSIZ_2008,
#     diff_Species_Richness_woodland_2018_2008 = AbWood_2018 - AbWood_2008
#   ) %>%
#   select(site, diff_MSIZ_2012_2008, diff_Species_Richness_woodland_2018_2008)
# 
# # Step 4: Get control variables from 2008
# controls_filters <- data_2008 %>%
#   select(site, alt, group, longitude, latitude,
#          temperature_moyenne24h, precipitation_somme24h, radiation_somme24h, MSIZ, perc4) %>%
#   distinct()
# 
# # Step 5: Merge diffs with control variables
# final_dataset <- diffs %>%
#   inner_join(controls_filters, by = "site") %>%
#       filter(perc4 < 0.2) %>% filter(abs(diff_MSIZ_2012_2008)<5000000) # %>% filter(MSIZ<1000000)
# 
# y_diff <- "diff_Species_Richness_woodland_2018_2008"
# x_diff <- "diff_MSIZ_2012_2008"
# x2_diff <- "truc"
# x_controls_diff <- c("alt", "longitude", "latitude", "temperature_moyenne24h", "precipitation_somme24h", "radiation_somme24h")
# col_to_stand <- c(x_controls_diff, y_diff, x_diff) 
# 
# regression_table_long(final_dataset, y_diff, x_diff, x2_diff, x_controls_diff, col_to_stand, interaction=FALSE, standardise=TRUE)
# print(final_dataset %>% count())
