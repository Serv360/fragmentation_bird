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
  summary(model)
}

regression_table_double <- function(data, y, x, x2, x_controls, col_to_stand, interaction=TRUE, standardise=TRUE) {
  # Build formula
  
  if (standardise) {
    data <- data %>%
      mutate(across(col_to_stand, scale))
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

y_diff <- "diff_Total_Abundance_woodland"
x_diff <- "diff_perc_MSIZ"
x2_diff <- ""
x_controls_diff <- c("temperature_moyenne24h", "precipitation_somme24h", "radiation_somme24h", "alt", "latitude", "Total_Abundance_woodland")
col_to_stand <- c(x_controls_diff, y_diff, x_diff)

diff_data <- diff_data %>% filter(year_diff=="2018-2008")
diff_data <- diff_data %>%
  left_join(final_data, by=c("site", "alt", "group", "longitude", "latitude", "year_i"="year")) %>% 
    filter(perc4 < 0.2)

regression_table_long(diff_data, y_diff, x_diff, x2_diff, x_controls_diff, col_to_stand, interaction=FALSE, standardise=FALSE)

# ================================================ #

# y_diff <- "diff_Total_Abundance_woodland"
# x_diff <- "diff_perc_CBC_MSIZ"
# x2_diff <- "truc"
# x_controls_diff <- c("temperature_moyenne24h", "precipitation_somme24h", "radiation_somme24h", "alt", "latitude")
# col_to_stand <- c(x_controls_diff, y_diff, x_diff)
# 
# diff_data <- diff_data %>% filter(year_diff!="2018-2008")
# diff_data <- diff_data %>% filter(diff_CBC_MSIZ < 20000000) %>%
#   left_join(final_data, by=c("site", "alt", "group", "longitude", "latitude", "year_i"="year")) %>%
#     filter(perc4 < 0.2)
# 
# 
# regression_table_double(diff_data, y_diff, x_diff, x2_diff, x_controls_diff, col_to_stand, interaction=FALSE, standardise=FALSE)

