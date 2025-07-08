# ================================================ #
# ================== Packages ==================== #
# ================================================ #

library(tidyverse)
library(dplyr)
library(readr)
library(tidyr)

# ================================================ #
# ================= Main path ==================== #
# ================================================ #

main_path <- "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP"

# ================================================ #
# ================= Functions ==================== #
# ================================================ #

create_climate_controls <- function(climate_data, bird_data) {
  bird_data$lat10 <- as.integer(round(bird_data$latitude*10)) #On transforme les lat/lon 
  bird_data$lon10 <- as.integer(round(bird_data$longitude*10)) #en entier pour join
  bird_data$year <- bird_data$annee
  #return(bird_data)
  climate_controls <- bird_data %>%
                    select(site, year, lat10, lon10) %>%
                    left_join(climate_data, by=c("lat10", "lon10", "year")) %>%
                    select(site, year, var_clim, value)
  
  df_wide <- climate_controls %>%
    pivot_wider(
      id_cols = c(site, year),
      names_from = var_clim,
      values_from = value
    ) %>%
    select(-'NA')
  
  return(df_wide)
}

load_bird_data <- function(bird_path) {
  bird_data <- read.csv(bird_path, sep = ",")
  
  bird_data <- bird_data %>%
    select(site, annee, longitude, latitude, passage) %>% 
    distinct() %>%
    filter(passage == "OK_1_and_2") # Keeps only (site, year) with 2 surveys
  
  return(bird_data)
}

load_climate_data <- function(climate_data_path) {
  climate_data <- read.csv(climate_data_path, sep = ",")
  return(climate_data)
}

write_climate_controls <- function(climate_controls, output_path) {
  readr::write_csv(climate_controls, output_path)
}

# ================================================ #
# ==================== Call ====================== #
# ================================================ #

bird_path <- paste0(main_path, "/data/biodiversity/STOC/countingdata_2007_2023.csv")
climate_data_path <- paste0(main_path, "/data/control_variables/climate/climate_data.csv")
output_path <- paste0(main_path, "/data/control_variables/climate/climate_controls.csv")

climate_data <- load_climate_data(climate_data_path)
bird_data <- load_bird_data(bird_path)
climate_controls <- create_climate_controls(climate_data, bird_data)

write_climate_controls(climate_controls, output_path)




