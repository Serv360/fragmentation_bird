# Install required packages if not already installed

# Load packages
library(tidyverse)
library(dplyr)
library(lmtest)
library(sandwich)

# Function to regress y on x and produce a clean table
regression_table_long <- function(data, y, x, x2, x_controls, col_to_stand, interaction=TRUE, standardise=TRUE) {
  # Build formula
  
  if (standardise) {
    data <- data %>%
      mutate(across(col_to_stand, scale))
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
  
  # Output table
  
  return(model)
}




plot_regression_coefficients_by_category <- function(data, 
                                                     x_diffs, 
                                                     y_base_names,
                                                     bird_categories,
                                                     x_controls,
                                                     interaction = FALSE,
                                                     standardise = TRUE) {
  results <- list()
  
  for (x in x_diffs) {
    for (cat in bird_categories) {
      for (y_base in y_base_names) {
        y <- paste0(y_base, "_", cat)
        
        cols_to_standardise <- unique(c(x_controls, y, x))
        
        # Run model
        model <- regression_table_long(data, y, x, x2 = "", x_controls, cols_to_standardise, interaction, standardise)
        
        # Tidy output
        tidy_model <- broom::tidy(model, conf.int = TRUE)
        
        # Extract term for current predictor
        predictor_row <- tidy_model %>% 
          filter(term == x) %>%
          mutate(
            x_diff = x,
            y_metric = y_base,
            category = cat
          )
        
        results[[length(results) + 1]] <- predictor_row
      }
    }
  }
  
  # Combine
  coef_df <- bind_rows(results)
  
  # Plot
  ggplot(coef_df, aes(x = x_diff, y = estimate, group = y_metric, color = y_metric)) +
    geom_line(position = position_dodge(width = 0.5), linewidth = 1) +
    geom_point(position = position_dodge(width = 0.5), size = 2.5) +
    geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.2, position = position_dodge(width = 0.5)) +
    facet_wrap(~category) +
    labs(
      title = "Regression Coefficients by Biodiversity Metric and Bird Category",
      x = "Predictor (x_diff)",
      y = "Coefficient Estimate",
      color = "Biodiversity Metric"
    ) +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
}


plot_forest_by_category <- function(data, 
                                    x_diffs, 
                                    y_base_names,
                                    bird_categories,
                                    x_controls,
                                    interaction = FALSE,
                                    standardise = TRUE) {
  results <- list()
  
  for (x in x_diffs) {
    for (cat in bird_categories) {
      for (y_base in y_base_names) {
        y <- paste0(y_base, "_", cat)
        
        cols_to_standardise <- unique(c(x_controls, y, x))
        
        # Run model
        model <- regression_table_long(data, y, x, x2 = "", x_controls, cols_to_standardise, interaction, standardise)
        
        # Tidy model
        tidy_model <- broom::tidy(model, conf.int = TRUE)
        
        # Extract main predictor
        predictor_row <- tidy_model %>% 
          filter(term == x) %>%
          mutate(
            predictor = x,
            metric = y_base,
            category = cat
          )
        
        results[[length(results) + 1]] <- predictor_row
      }
    }
  }
  
  # Combine
  coef_df <- bind_rows(results)
  
  # Create combined label for Y-axis grouping
  coef_df <- coef_df %>%
    mutate(group_label = paste(category, metric, predictor, sep = " | ")) %>%
    arrange(category, metric, predictor)
  
  # Set factor levels to preserve order
  coef_df$group_label <- factor(coef_df$group_label, levels = rev(unique(coef_df$group_label)))
  
  # Plot
  ggplot(coef_df, aes(x = estimate, y = group_label)) +
    geom_point(size = 2.5, color = "steelblue") +
    geom_errorbarh(aes(xmin = conf.low, xmax = conf.high), height = 0.2, color = "steelblue") +
    geom_vline(xintercept = 0, linetype = "dashed", color = "gray40") +
    labs(
      title = "Regression Coefficients with 95% CI by Category, Metric, and Predictor",
      x = "Coefficient Estimate",
      y = ""
    ) +
    theme_minimal(base_size = 12) +
    theme(
      panel.grid.major.y = element_blank(),
      axis.text.y = element_text(size = 10)
    )
}

plot_forest_by_category_pretty <- function(data, 
                                           x_diffs, 
                                           y_base_names,
                                           bird_categories,
                                           x_controls,
                                           interaction = FALSE,
                                           standardise = TRUE) {
  results <- list()
  
  for (x in x_diffs) {
    for (cat in bird_categories) {
      for (y_base in y_base_names) {
        y <- paste0(y_base, "_", cat)
        
        cols_to_standardise <- unique(c(x_controls, y, x))
        
        model <- regression_table_long(data, y, x, x2 = "", x_controls, cols_to_standardise, interaction, standardise)
        
        tidy_model <- broom::tidy(model, conf.int = TRUE)
        
        predictor_row <- tidy_model %>% 
          filter(term == x) %>%
          mutate(
            predictor = x,
            metric = y_base,
            category = cat
          )
        
        results[[length(results) + 1]] <- predictor_row
      }
    }
  }
  
  coef_df <- bind_rows(results)
  
  # Create a new label column for grouping
  coef_df <- coef_df %>%
    mutate(
      metric = factor(metric, levels = y_base_names),
      predictor = factor(predictor, levels = x_diffs),
      category = factor(category, levels = bird_categories)
    )
  
  # Plot
  ggplot(coef_df, aes(x = estimate, y = fct_rev(predictor), color = metric)) +
    geom_point(size = 2.5, position = position_dodge(width = 0.7)) +
    geom_errorbarh(aes(xmin = conf.low, xmax = conf.high), height = 0.2, position = position_dodge(width = 0.7)) +
    facet_grid(category ~ metric, scales = "free_y", space = "free_y") +
    geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
    scale_color_brewer(palette = "Set2") +
    labs(
      title = "Regression Coefficients (with 95% CI)",
      subtitle = "Grouped by Bird Category and Biodiversity Metric",
      x = "Coefficient Estimate",
      y = "Predictor",
      color = "Biodiversity Metric"
    ) +
    theme_minimal(base_size = 13) +
    theme(
      strip.text = element_text(face = "bold", size = 11),
      axis.text.y = element_text(size = 11),
      axis.title.y = element_text(margin = margin(r = 10)),
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

# Read the data
diff_path <- "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/merged_data/difference_data_all_three.csv"
final_path <- "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/merged_data/final_data_all_three.csv"
final_data <- read_csv(final_path)
diff_data <- read_csv(diff_path)

# ================================================ #

# y <- "Total_Abundance_woodland"
# x <- "MSIZ"
# x2 <- "dummy_year"
# x_controls <- c() # c("temperature_moyenne24h", "precipitation_somme24h", "radiation_somme24h", "alt", "latitude")

# final_data <- final_data %>%
#   mutate(across(c(x_controls, y, x), scale))
# final_data <- final_data %>% filter(year!=2012)
# final_data <- final_data %>% filter(perc4 < 0.2) %>%
#   mutate(dummy_year = ifelse(year == 2008, 0,
#                              ifelse(year == 2018, 1, NA))) %>%
#   filter(abs(MSIZ) < 4000000)
# 
# regression_table_long(final_data, y, x, x2, x_controls)

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

diff_data <- diff_data %>% filter(year_diff=="2018-2008")
diff_data <- diff_data %>%
  left_join(final_data, by=c("site", "alt", "group", "longitude", "latitude", "year_i"="year")) %>%
    filter(perc4 < 0.2) %>% filter(abs(diff_MSIZ)<500000) #%>% filter(MSIZ<1000000)
print(diff_data %>% count())

x_diffs <- c("diff_MSIZ", "diff_CBC_MSIZ", "diff_patches", "diff_perc1", "diff_perc2", "diff_perc3")
y_diffs_woodland <- c("diff_Total_Abundance_woodland", "diff_Species_Richness_woodland", "diff_Simpson_Diversity_woodland", "diff_Shannon_Diversity_woodland")
y_diffs <- c("diff_Total_Abundance", "diff_Species_Richness", "diff_Simpson_Diversity", "diff_Shannon_Diversity")
bird_categories <- c("woodland", "urban", "farmland", "generalist", "all")
x_controls <- c("temperature_moyenne24h", "precipitation_somme24h", "radiation_somme24h", "alt", "latitude")

plot_forest_by_category_pretty(
  data = diff_data,
  x_diffs = x_diffs,
  y_base_names = y_diffs,
  bird_categories = bird_categories,
  x_controls = x_controls,
  interaction = FALSE,
  standardise = TRUE
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
