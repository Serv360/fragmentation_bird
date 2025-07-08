# ================================================ #
# ================== Packages ==================== #
# ================================================ #

library(tidyverse)
library(broom)
library(kableExtra)
library(knitr)

# ================================================ #
# ================= Main path ==================== #
# ================================================ #

main_path <- "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP"

# ================================================ #
# ================= Functions ==================== #
# ================================================ #

graph_deviation <- function (y, predictors, data, pretty_names, standardise=TRUE) {
  if (standardise){
    print("Data standardised.")
    # Standardize data (scale returns mean=0, sd=1)
    data <- data %>%
      mutate(across(all_of(c(y, predictors)), scale))
  } else {
    print("Data not standardised.")
  }
  # Run nested standardized regressions and tidy
  model_results <- map(1:length(predictors), function(i) {
    formula <- as.formula(paste0(y, " ~ ", paste(predictors[1:i], collapse = " + ")))
    model <- lm(formula, data = data)
    tidy(model, conf.int = TRUE) %>%
      mutate(model = paste0("Model_", i))
  })
  
  # Combine and clean results
  plot_data <- bind_rows(model_results) %>%
    filter(term != "(Intercept)")
  
  plot_data <- plot_data %>%
    mutate(term = recode(term, !!!pretty_names))
  
  # Plot standardized coefficients
  ggplot(plot_data, aes(x = estimate, y = term, color = model)) +
    geom_point(position = position_dodge(width = 0.5)) +
    geom_errorbarh(aes(xmin = conf.low, xmax = conf.high), height = 0.2,
                   position = position_dodge(width = 0.5)) +
    labs(
      title = "Standardized Coefficient Estimates (with 95% CI)",
      x = "Standardized Estimate",
      y = NULL
    ) +
    theme_minimal(base_size = 14) +
    theme(legend.position = "top")
}

graph_deviation_multi <- function(y_vars, predictors, data, pretty_names, standardise = TRUE) {
  if (standardise) {
    message("Data standardized.")
    data <- data %>%
      mutate(across(all_of(c(y_vars, predictors)), scale))
  } else {
    message("Data not standardized.")
  }
  
  # Internal helper function for one y
  single_graph <- function(y) {
    model_results <- purrr::map(1:length(predictors), function(i) {
      formula <- as.formula(paste0(y, " ~ ", paste(predictors[1:i], collapse = " + ")))
      model <- lm(formula, data = data)
      broom::tidy(model, conf.int = TRUE) %>%
        mutate(model = paste0("Model_", i))
    })
    
    plot_data <- dplyr::bind_rows(model_results) %>%
      dplyr::filter(term != "(Intercept)") %>%
      dplyr::mutate(term = dplyr::recode(term, !!!pretty_names))
    
    ggplot2::ggplot(plot_data, aes(x = estimate, y = term, color = model)) +
      ggplot2::geom_point(position = ggplot2::position_dodge(width = 0.5)) +
      ggplot2::geom_errorbarh(aes(xmin = conf.low, xmax = conf.high), height = 0.2,
                              position = ggplot2::position_dodge(width = 0.5)) +
      ggplot2::labs(
        title = paste("Standardized Coefficient Estimates for", y),
        x = "Standardized Estimate",
        y = NULL
      ) +
      ggplot2::theme_minimal(base_size = 14) +
      ggplot2::theme(legend.position = "top")
  }
  
  # Return a named list of plots
  plots <- setNames(
    purrr::map(y_vars, single_graph),
    y_vars
  )
  
  return(plots)
}

table_deviation <- function(y, predictors, data, pretty_names, standardise = TRUE, latex = TRUE) {
  
  if (standardise) {
    message("Data standardized.")
    data <- data %>%
      mutate(across(all_of(c(y, predictors)), scale))
  } else {
    message("Data not standardized.")
  }
  
  # Build formula and fit model with all predictors
  formula <- as.formula(paste(y, "~", paste(predictors, collapse = " + ")))
  model <- lm(formula, data = data)
  
  # Tidy coefficients with stars and SE
  tidy_coef <- tidy(model) %>%
    mutate(
      stars = case_when(
        p.value < 0.001 ~ "***",
        p.value < 0.01  ~ "**",
        p.value < 0.05  ~ "*",
        p.value < 0.1   ~ ".",
        TRUE           ~ ""
      ),
      coef_display = paste0(sprintf("%.3f", estimate), stars),
      se_display = paste0("(", sprintf("%.3f", std.error), ")")
    ) %>%
    select(term, coef_display, se_display)
  
  # Model summary stats
  stats <- tibble(
    term = c("R²", "F", "Significance"),
    coef_display = c(sprintf("%.4f", glance(model)$r.squared),
                     sprintf("%.3f", glance(model)$statistic),
                     sprintf("%.4f", glance(model)$p.value)),
    se_display = NA_character_
  )
  
  # Combine coef and stats
  final_table <- bind_rows(tidy_coef, stats)
  
  # Optional: nicer term names (edit as needed)
  
  final_table$term <- recode(final_table$term, !!!pretty_names)
  
  if (latex) {
    return(
      kable(final_table, format = "latex", booktabs = TRUE, escape = FALSE,
            col.names = c("Term", "Coefficient", "Std. Error"),
            caption = "Regression Results with Standardized Coefficients") %>%
        kable_styling(latex_options = c("hold_position", "scale_down"))
    )
  } else {
    return(final_table)
  }
}

# ================================================ #
# ==================== Call ====================== #
# ================================================ #

# Read the data
diff_path <- paste0(main_path, "/data/merged_data/difference_data_all_three.csv")
diff_data <- read_csv(diff_path)
final_path <- paste0(main_path, "/data/merged_data/final_data_all_three.csv")
final_data <- read_csv(final_path)



diff_data <- diff_data %>% filter(year_diff=="2018-2008")

diff_data <- diff_data %>% left_join(final_data, by=c("site" = "site", "year_i"="year"))

# Define predictors and response
predictors <- c("diff_perc_CBC_MSIZ", "diff_perc3", "perc3", "diff_temperature_moyenne24h",
                "diff_precipitation_somme24h", "diff_radiation_somme24h")

y <- "diff_Total_Abundance_woodland"
y_vars <- c("diff_Total_Abundance_woodland",
            "diff_Total_Abundance_urban",
            "diff_Total_Abundance_all",
            "diff_Total_Abundance_generalist",
           "diff_Total_Abundance_farmland")

# predictors <- c("perc3", "temperature_moyenne24h",
#                 "precipitation_somme24h", "radiation_somme24h")
# 
# y <- "Total_Abundance_woodland"
# 
predictor_names <- predictors

pretty_names <- setNames(predictors, predictor_names)
pretty_names["(Intercepts)"] <- "Intercept"

graph_deviation_multi(y_vars, predictors, diff_data, pretty_names, standardise=TRUE)



