# ================================================ #
# ================== Packages ==================== #
# ================================================ #

library(vegan)  # for diversity metrics
library(tidyverse)
library(dplyr)

# ================================================ #
# ================= Main path ==================== #
# ================================================ #

main_path <- "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP"

# ================================================ #
# ================= Functions ==================== #
# ================================================ #

compute_category_indicators <- function(bird_data, traits_data) {
  # Merge bird abundance data with trait info
  birds_joined <- bird_data %>%
    rename(pk_species = species) %>%
    left_join(traits_data, by = "pk_species") %>%
    filter(!is.na(habitat_specialisation))  # remove unmatched species
  
  # Create one version with habitat category and one without (labeled "all")
  birds_with_category <- birds_joined %>% filter(!is.na(habitat_specialisation))
  birds_all <- birds_joined %>%
    mutate(habitat_specialisation = "all")
  
  # Combine both
  combined <- bind_rows(birds_with_category, birds_all)
  
  # Aggregate abundance by site-year-category-species
  agg <- combined %>%
    group_by(site, annee, habitat_specialisation, pk_species) %>% #Probably not necessary
    summarise(abundance = sum(abondance), .groups = "drop")
  
  # Reshape to wide format per category
  wide <- agg %>%
    pivot_wider(names_from = pk_species, values_from = abundance, values_fill = 0)
  
  # Split by category
  indicators_list <- wide %>%
    group_split(habitat_specialisation) %>%
    map_df(function(df) {
      category <- unique(df$habitat_specialisation)
      site_year <- df %>% select(site, annee)
      data <- df %>% select(-site, -annee, -habitat_specialisation)
      
      tibble(
        site = site_year$site,
        annee = site_year$annee,
        habitat_category = category,
        Total_Abundance = rowSums(data),
        Species_Richness = rowSums(data > 0),
        Shannon_Diversity = diversity(data, index = "shannon"),
        # H' = -\sum_1^S{p_i*log_2(p_i)} with p_i = n_i/N
        # H' shannon index, S number of species, n_i abundance for species i
        # N total abundance for all species
        # Therefore, if there are species with abundance 0 it doesn't change it.
        Simpson_Diversity = diversity(data, index = "simpson")
      )
    })
  
  return(indicators_list)
}

load_data <- function(bird_path, species_path) {
  bird_data <- read.csv(bird_path, sep = ",")
  traits_data <- read.csv(species_path, sep = ",")
  
  # Uses "unknown" when a species is not in a category
  traits_data <- traits_data %>%
    mutate(habitat_specialisation = case_when(
      habitat_specialisation %in% c("farmland", "urban", "woodland", "generalist") ~ habitat_specialisation,
      TRUE ~ "unknown"
    ))
  
  bird_data <- bird_data %>%
    filter(passage == "OK_1_and_2") # Keeps only (site, year) with 2 surveys
  
  return(list(bird = bird_data, traits = traits_data))
}

write_results <- function(indicators, output_path) {
  write.csv(indicators, output_path, row.names = FALSE)
} 

# ================================================ #
# ==================== Call ====================== #
# ================================================ #

bird_path <- paste0(main_path, "/data/biodiversity/STOC/countingdata_2007_2023.csv")
species_path <- paste0(main_path, "/data/biodiversity/STOC/species_stoc.csv")
output_path <- paste0(main_path, "/data/biodiversity/div_indicators/indicators.csv")

full_data <- load_data(bird_path, species_path)
bird_data <- full_data$bird
traits_data <- full_data$traits

indicators <- compute_category_indicators(bird_data, traits_data)

write_results(indicators, output_path)

