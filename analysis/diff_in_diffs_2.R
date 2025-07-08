# ================================================ #
# ================== Packages ==================== #
# ================================================ #

library(tidyverse)
library(dplyr)
library(rlang)
library(lmtest)
library(sandwich)

# ================================================ #
# ================= Main path ==================== #
# ================================================ #

main_path <- "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP"

# ================================================ #
# ================= Functions ==================== #
# ================================================ #

create_groups <- function(data, col_to_group, threshold_vector, treatment_group_names) {
  
  data <- data %>% 
    mutate(treatment_group = case_when(
      !!sym(col_to_group) < threshold_vector[1] ~ treatment_group_names[1],  # < -0.1
      !!sym(col_to_group) >= threshold_vector[1] & !!sym(col_to_group) < threshold_vector[2] ~ treatment_group_names[2],
      !!sym(col_to_group) >= threshold_vector[3] & !!sym(col_to_group) < threshold_vector[4] ~ treatment_group_names[3],
      !!sym(col_to_group) >= threshold_vector[4] ~ treatment_group_names[4],
      TRUE ~ "control"  # Outside all defined ranges
    ))
  print(col_to_group)
  for (treatment_group_name in treatment_group_names) {
    column_name <- paste0("dummy_", treatment_group_name)
    data <- data %>% mutate(!!column_name := ifelse(treatment_group == treatment_group_name, 1, 0))
  }
  return(data)
}

run_diffindiffs <- function(data, y, dum_y, dummy_groups, x_controls, col_to_stand, standardise=FALSE) {
  if (standardise) {
    data <- data %>%
      mutate(across(col_to_stand, scale))
  }
  
  formula_interaction <- paste(paste0(dum_y, " * ", dummy_groups), collapse = " + ")
  
  if (length(x_controls) > 0) {
    formula <- as.formula(paste(y, "~", formula_interaction, " + ", paste(x_controls, collapse = " + ")))
  } else {
    formula <- as.formula(paste(y, "~", formula_interaction))
  }
  
  # Run linear model
  model <- lm(formula, data = data)
  
  # Clustered standard errors by a column (e.g., cluster_id)
  cl_vcov <- vcovCL(model, cluster = ~site)
  
  # Print model summary with clustered SEs
  coeftest(model, vcov. = cl_vcov)
}

# ================================================ #
# ==================== Call ====================== #
# ================================================ #

diff_path <- paste0(main_path, "/data/merged_data/difference_data_all_three.csv")
diff_data <- read_csv(diff_path)
final_path <- paste0(main_path, "/data/merged_data/final_data_all_three.csv")
final_data <- read_csv(final_path)

final_data <- final_data %>% filter(perc4 < 0.2) %>%
    mutate(dummy_year = ifelse(year == 2008, 0, 1))

final_data <- bind_rows(
  final_data,
  final_data %>% filter(year == 2012) %>%
    mutate(dummy_year = 0)
)

diff_data <- diff_data %>% filter(year_diff != "2018-2008") %>% filter(abs(diff_CBC_MSIZ) < 20000000)

col_to_group <- "diff_perc_CBC_MSIZ"
treatment_group_names <- c("very_negative", "negative", "positive", "very_positive")
threshold_vector <- c(-0.1, -0.01, 0.01, 0.1)

grouped_diff_data <- create_groups(diff_data, col_to_group, threshold_vector, treatment_group_names)

joined_data <- final_data %>% 
  left_join(grouped_diff_data, by=c("site", "alt", "group", "longitude", "latitude", "year"="year_i"))

joined_data$year_diff <- as.factor(joined_data$year_diff)

x_controls <- c("temperature_moyenne24h", "precipitation_somme24h", "radiation_somme24h", "alt", "latitude", "year_diff")
y <- "Total_Abundance_woodland"
dum_y <- "dummy_year"

dummy_groups <- paste0("dummy_", treatment_group_names)

run_diffindiffs(joined_data, y, dum_y, dummy_groups, x_controls, col_to_stand, standardise=FALSE)

print(grouped_diff_data %>%
        count(treatment_group))

