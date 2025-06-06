library(terra)

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

