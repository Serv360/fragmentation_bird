library(tidyverse)
library(ncdf4)
library(readr)
library(dplyr)

#=====# Climate data information #=====#

# Climate data was downloaded by hand with macros from the Copernicus website.
# It would be more relevant to use an API (package cdsapi with python e.g.).

#=====# Functions #=====#

get_box <- function(r) {
  # Get the extension of a .nc file
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
  
  grid <- expand.grid(lon = array_lon, lat = array_lat)
  
  return(list(nlon=nlon, nlat=nlat, lat=grid$lat, lon=grid$lon))
}

create_climate_annual_subset <- function(var_clim, year, climate_data_size, corresp_var_clim) {
  # Obtain a dataframe with the format (var_clim, year, lon, lat, value)
  # For a given year and a given var_clim
  var_clim_split = str_split(var_clim, "_")[[1]]
  var_clim_grandeur = var_clim_split[[1]]
  var_clim_aggreg = var_clim_split[[2]]
  value_aggreg = matrix(0, nrow=climate_data_size$nlon, ncol=climate_data_size$nlat)
  for (jour in seq(1, 365 + leap_year(year))) {
    date_current = as.Date(paste(year, "-01-01", sep=""), format = "%Y-%m-%d") + jour - 1
    path_agera5 = paste(data_climate_path,
                        "/data/copernicus_propre/", 
                        var_clim_grandeur, "/",
                        var_clim_aggreg, "/",
                        year, "/",
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
  
  value_aggreg <- as.vector(value_aggreg)
  
  value_tibble = as_tibble(cbind(lon10=climate_data_size$lon, 
                                 lat10=climate_data_size$lat, 
                                 value=value_aggreg))
  value_tibble$lat10 <- as.integer(round(value_tibble$lat10*10)) #On transforme les lat/lon 
  value_tibble$lon10 <- as.integer(round(value_tibble$lon10*10)) #en entier pour join
  
  value_tibble$year <- year
  value_tibble$var_clim <- var_clim
  return(value_tibble)
}

create_climate_annual_dataset <- function(var_clims, years, climate_data_size, corresp_var_clim, verbose=TRUE) {
  # Create a dataframe with the format (var_clim, year, lon, lat, value)
  # for all years and var_clims
  all_subsets <- list()
  for (var_clim in var_clims) {
    if (verbose) {print(paste("Climate variable :", var_clim, sep=" "))}
    for (year in years) {
      if (verbose) {print(paste(year, "", sep=" ", end=""))}
      subset_cur <- create_climate_annual_subset(var_clim, year, climate_data_size, corresp_var_clim)
      
      subset_cur$var_clim <- var_clim
      subset_cur$year <- year
      
      all_subsets[[length(all_subsets) + 1]] <- subset_cur
    }
    if (verbose) {print("")}
  }
  climate_tibble <- dplyr::bind_rows(all_subsets)
  return(climate_tibble)
}

write_climate_annual_data <- function(climate_tibble, output_path) {
  readr::write_csv(climate_tibble, output_path)
}

#=====# Global variables #=====#

data_climate_path <- "C:/Users/Serv3/Desktop/INSEE ENSAE/Cours/DSSS project"
var_clims = list("temperature_moyenne24h", "precipitation_somme24h", "radiation_somme24h")
years = seq(2008, 2022)
corresp_var_clim = list("temperature_moyenne24h" = "Temperature_Air_2m_Mean_24h", 
                        "precipitation_somme24h" = "Precipitation_Flux", 
                        "radiation_somme24h" = "Solar_Radiation_Flux")
output_path <- "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/control_variables/climate/climate_data.csv"

# bird_data <- load_bird_data(bird_path)
# climate_data_size <- get_size_climate_data(data_climate_path, var_clims)

# climate_tibble <- create_climate_annual_dataset(var_clims, years, climate_data_size, corresp_var_clim)
write_climate_annual_data(climate_tibble, output_path)


