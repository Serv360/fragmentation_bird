
library(tidyverse)
library(dplyr)
library(rlang)

create_groups <- function(data, col_to_group1, col_to_group2, threshold_vector, threshold_connectivity, treatment_group_names) {
  print(treatment_group_names)
  data <- data %>% 
    mutate(treatment_group = case_when(
      !!sym(col_to_group1) < threshold_vector[1] & !!sym(col_to_group2) < threshold_connectivity  ~ treatment_group_names[1],  # < -0.1
      !!sym(col_to_group1) > threshold_vector[2] & !!sym(col_to_group2) < threshold_connectivity ~ treatment_group_names[2],
      !!sym(col_to_group2) < threshold_connectivity ~ treatment_group_names[3],
      !!sym(col_to_group1) < threshold_vector[1] & !!sym(col_to_group2) >= threshold_connectivity ~ treatment_group_names[4],
      !!sym(col_to_group1) > threshold_vector[2] & !!sym(col_to_group2) >= threshold_connectivity ~ treatment_group_names[5],
      !!sym(col_to_group2) >= threshold_connectivity ~ treatment_group_names[6]  # Outside all defined ranges
    ))
  print(col_to_group1)
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
  
  # Output table
  summary(model)
}


diff_path <- "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/merged_data/difference_data_all_three.csv"
diff_data <- read_csv(diff_path)
final_path <- "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/merged_data/final_data_all_three.csv"
final_data <- read_csv(final_path)

final_data <- final_data %>% filter(year != 2012) %>% filter(perc4 < 0.2) %>%
    mutate(dummy_year = ifelse(year == 2008, 0,
                               ifelse(year == 2018, 1, NA)))

diff_data <- diff_data %>% filter(year_diff == "2018-2008") %>% filter(abs(diff_CBC_MSIZ) < 500000) %>%
  inner_join(final_data, by=c("site", "alt", "group", "longitude", "latitude", "year_i"="year")) %>%
  select(c("site", "alt", "group", "longitude", "latitude", "year_i", "diff_CBC_MSIZ", "CBC_MSIZ", "diff_MSIZ", "MSIZ"))

col_to_group1 <- "diff_CBC_MSIZ"
col_to_group2 <- "CBC_MSIZ"
treatment_group_names <- c("low_conn_neg_diff", "low_conn_pos_diff", "low_conn_control", "high_conn_neg_diff", "high_conn_pos_diff", "high_conn_control")
threshold_vector <- c(-10000, 10000)
threshold_connectivity <- 600000

grouped_diff_data <- create_groups(diff_data, col_to_group1, col_to_group2, threshold_vector, threshold_connectivity, treatment_group_names)

joined_data <- final_data %>% 
  left_join(grouped_diff_data, by=c("site", "alt", "group", "longitude", "latitude")) 

x_controls <- c("temperature_moyenne24h", "precipitation_somme24h", "radiation_somme24h", "alt", "latitude")
y <- "Total_Abundance_woodland"
dum_y <- "dummy_year"



dummy_groups <- paste0("dummy_", treatment_group_names)[-3]

run_diffindiffs(joined_data, y, dum_y, dummy_groups, x_controls, col_to_stand, standardise=FALSE)

print(grouped_diff_data %>%
        count(treatment_group))

