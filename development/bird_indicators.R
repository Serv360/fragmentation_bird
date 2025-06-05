library(vegan)  # for diversity metrics
library(tidyverse)
library(dplyr)

compute_category_indicators <- function(bird_data, traits_data) {
  # Merge bird abundance data with trait info
  birds_joined <- bird_data %>%
    rename(pk_species = species) %>%
    left_join(traits_data, by = "pk_species") %>%
    filter(!is.na(habitat_specialisation))  # remove unmatched species
  
  # Aggregate abundance by site-year-category-species
  agg <- birds_joined %>%
    group_by(site, annee, habitat_specialisation, pk_species) %>%
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
        Simpson_Diversity = diversity(data, index = "simpson")
      )
    })
  
  return(indicators_list)
}

load_data <- function(bird_path, species_path) {
  bird_data <- read.csv(bird_path, sep = ",")
  traits_data <- read.csv(species_path, sep = ",")
  return(list(bird = bird_data, traits = traits_data))
}

bird_path <- "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/biodiversity/STOC/countingdata_2007_2023.csv"
species_path <- "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/biodiversity/STOC/species_stoc.csv"

full_data <- load_data(bird_path, species_path)
bird_data <- full_data$bird
traits_data <- full_data$traits

indicators <- compute_category_indicators(bird_data, traits_data)
