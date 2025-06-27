
library(tidyverse)
library(dplyr)

create_groups <- function(data, col_to_group, threshold_vector, treatment_group_names) {
  
  data <- data %>% mutate(treatment_group = ifelse(col_to_group < threshold_vector[1], treatment_group_names[1], 
                                     ifelse(col_to_group < threshold_vector[2], treatment_group_names[2], 
                                     ifelse(col_to_group > threshold_vector[4], treatment_group_names[4],
                                     ifelse(col_to_group > threshold_vector[3], treatment_group_names[3],
                                     "control")
                                     ))))
  for (treatment_group_name in treatment_group_names) {
    column_name <- paste0("dummy_", treatment_group_name)
    data <- data %>% mutate(!!column_name := ifelse(col_to_group == treatment_group_name, 1, 0))
  }
  return(data)
}

run_diffindiffs <- function(data, y, dum_y, dummy_groups, x_controls, col_to_stand, standardise=FALSE) {
  if (standardise) {
    data <- data %>%
      mutate(across(col_to_stand, scale))
  }
  
  formula_interaction <- paste(paste0(dummy_groups, " * ", dum_y), collapse = " + ")
  
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

final_data <- final_data %>% filter(year != 2012) %>%
    mutate(dummy_year = ifelse(year == 2008, 0,
                               ifelse(year == 2018, 1, NA)))

diff_data <- diff_data %>% filter(year_diff == "2018-2008")

col_to_group <- "diff_perc_MSIZ"
treatment_group_names <- c("very_negative", "negative", "positive", "very_positive")

grouped_diff_data <- create_groups(diff_data, col_to_group, threshold_vector, treatment_group_names)

joined_data <- final_data %>% 
  left_join(grouped_diff_data, by=c("site", "alt", "group", "longitude", "latitude")) 

threshold_vector <- c(-0.1, -0.01, 0.01, 0.1)
x_controls <- c() # c("temperature_moyenne24h", "precipitation_somme24h", "radiation_somme24h", "alt", "latitude")
y <- "Total_Abundance_woodland"
dum_y <- "dummy_year"

dummy_groups <- paste0("dummy_", treatment_group_names)

run_diffindiffs(joined_data, y, dum_y, dummy_groups, x_controls, col_to_stand, standardise=FALSE)

