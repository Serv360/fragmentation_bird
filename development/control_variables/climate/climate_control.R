library(terra)
library(tidyverse)
library(ncdf4)
# library(stringr)
# library(sp)
# library(sf)
# library(readxl)
# library(readr)
# library(jsonlite)
library(dplyr)

# Get the extension of a .nc file.
get_box <- function(r) {
  ext <- ext(r)
  
  # Get coordinate boundaries
  xmin <- xmin(ext)
  xmax <- xmax(ext)
  ymin <- ymin(ext)
  ymax <- ymax(ext)
  
  return(list(xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax))
}

# r <- rast("C:/Users/Serv3/Desktop/INSEE ENSAE/Cours/DSSS project/data/copernicus_propre/temperature/moyenne24h/2010/20100101.nc")
# res <- get_box(r)
# In my case: x:-4.95;9.05  y:40.45;52.95

leap_year <- function(year) {
  return(ifelse((year %%4 == 0 & year %%100 != 0) | year %%400 == 0, TRUE, FALSE))
}

merge_3 <- function(annee, culture, dept, var_clim, donnee_RPG, verbose=FALSE) {
  var_clim_split = str_split(var_clim, "_")[[1]]
  var_clim_grandeur = var_clim_split[[1]]
  var_clim_aggreg = var_clim_split[[2]]
  tab_var_clim = array(0, 365 + leap_year(annee))
  for (jour in seq(1, 365 + leap_year(annee))) {
    date_current = as.Date(paste(annee, "-01-01", sep=""), format = "%Y-%m-%d") + jour - 1
    path_agera5 = paste(data_climate_path,
                        "/data/copernicus_propre/", 
                        var_clim_grandeur, "/",
                        var_clim_aggreg, "/",
                        annee, "/",
                        format(date_current, "%Y%m%d"),
                        ".nc",
                        sep=""
    )
    nc_jour <- nc_open(path_agera5)
    array_lon <- ncvar_get(nc_jour, "lon")
    nlon <- dim(array_lon)
    array_lat <- ncvar_get(nc_jour, "lat")
    nlat <- dim(array_lat)
    value <- ncvar_get(nc_jour, corresp_var_clim[[var_clim]])
    
    nc_close(nc_jour)
    
    lat = array(0, dim=(nlon*nlat))
    i <- 0
    for (elt_lat in array_lat) {
      for (elt_lon in array_lon) {
        i <- i + 1
        lat[i] <- elt_lat
      }
    }
    
    lon = array(array_lon, dim=(nlon*nlat))
    value = as.vector(value)
    
    value_tibble = as_tibble(cbind(lon, lat, value))
    value_tibble$lat <- as.integer(round(value_tibble$lat*10)) #On transforme les lat/lon 
    value_tibble$lon <- as.integer(round(value_tibble$lon*10)) #en entier pour join
    #print(donnee_RPG)
    #print(value_tibble)
    coper_rpg_joined_jour = inner_join(value_tibble, bird_data, by=c("lat", "lon")) #inner_join on the column in common
    #parcelles de l'année, culture, dept avec les colonnes suivantes :
    #lat, lon, value var clim, id_parcel, surface, code_culture, culture D1, culture D2
    #Seul nous intéresse : la moyenne de la variable climatique ici
    #print(coper_rpg_joined_jour)
    valeur_moyenne = mean(coper_rpg_joined_jour$value, na.rm=TRUE) #Attention s'il y a des NA ici
    tab_var_clim[jour] <- valeur_moyenne
  }
  return(tab_var_clim)
}

get_size_climate_data <- function(data_climate_path, var_clims) {
  var_clim_split = str_split(var_clims[[1]], "_")[[1]]
  var_clim_grandeur = var_clim_split[[1]]
  var_clim_aggreg = var_clim_split[[2]]
  year = 2011
  date_cur = 20110101
  path_first = paste(data_climate_path,
                      "/data/copernicus_propre/", 
                      var_clim_grandeur, "/",
                      var_clim_aggreg, "/",
                      year, "/",
                      date_cur,
                      ".nc",
                      sep=""
  )
  nc_first <- nc_open(path_first)
  array_lon <- ncvar_get(nc_first, "lon")
  nlon <- dim(array_lon)
  array_lat <- ncvar_get(nc_first, "lat")
  nlat <- dim(array_lat)
  nc_close(nc_first)
  
  lat = array(0, dim=(nlon*nlat))
  i <- 0
  for (elt_lat in array_lat) {
    for (elt_lon in array_lon) {
      i <- i + 1
      lat[i] <- elt_lat
    }
  }
  
  lon = vector(array_lon, dim=(nlon*nlat))
  
  return(list(nlon=nlon, nlat=nlat, lat=lat, lon=lon))
}

create_climate_annual_subset <- function(var_clim, year, climate_data_size, corresp_var_clim) {
  # Obtain a dataframe with the format (var_clim, year, lon, lat, value)
  # For a given year and a given var_clim
  var_clim_split = str_split(var_clim, "_")[[1]]
  var_clim_grandeur = var_clim_split[[1]]
  var_clim_aggreg = var_clim_split[[2]]
  value_aggreg = matrix(0, nrow=climate_data_size$nlon, ncol=climate_data_size$nlat)
  for (jour in seq(1, 365 + leap_year(annee))) {
    date_current = as.Date(paste(annee, "-01-01", sep=""), format = "%Y-%m-%d") + jour - 1
    path_agera5 = paste(data_climate_path,
                        "/data/copernicus_propre/", 
                        var_clim_grandeur, "/",
                        var_clim_aggreg, "/",
                        annee, "/",
                        format(date_current, "%Y%m%d"),
                        ".nc",
                        sep=""
    )
    nc_jour <- nc_open(path_agera5)
    value <- ncvar_get(nc_jour, corresp_var_clim[[var_clim]])
    nc_close(nc_jour)
    
    # value <- as.vector(value)
    
    value_aggreg <- value_aggreg + value
  }
  
  # Small change depending of the type of aggregation
  if (var_clim_aggreg == "moyenne24h") {
    value_aggreg <- value_aggreg / 365 + leap_year(year)
  }
  
  value_tibble = as_tibble(cbind(lon, lat, value))
  value_tibble$lat <- as.integer(round(value_tibble$lat*10)) #On transforme les lat/lon 
  value_tibble$lon <- as.integer(round(value_tibble$lon*10)) #en entier pour join
}

create_climate_annual_dataset <- function(var_clims, years, climate_data_size, corresp_var_clim) {
  # Create a dataframe with the format (var_clim, year, lon, lat, value)
  # for all years and var_clims
  for (var_clim in var_clims) {
    for (year in years) {
      subset_cur <- create_annual_subset(var_clim, year, climate_data_size, corresp_var_clim)
      
    }
  }
}

load_bird_data <- function(bird_path) {
  bird_data <- read.csv(bird_path, sep = ",")

  bird_data <- bird_data %>%
    select(site, annee, longitude, latitude, passage) %>% 
    distinct() %>%
    filter(passage == "OK_1_and_2") # Keeps only (site, year) with 2 surveys
  
  return(bird_data)
}

data_climate_path <- "C:/Users/Serv3/Desktop/INSEE ENSAE/Cours/DSSS project"
bird_path <- "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/biodiversity/STOC/countingdata_2007_2023.csv"
var_clims = list("temperature_moyenne24h", "precipitation_somme24h", "radiation_somme24h")
years = seq(2008, 2022)
corresp_var_clim = list("temperature_moyenne24h" = "Temperature_Air_2m_Mean_24h", 
                        "precipitation_somme24h" = "Precipitation_Flux", 
                        "radiation_somme24h" = "Solar_Radiation_Flux")

bird_data <- load_bird_data(bird_path)
climate_data_size <- get_size_climate_data(data_climate_path, var_clims)



