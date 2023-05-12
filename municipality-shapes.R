# municipality-level weather data
# Jeff Oliver
# jcoliver@arizona.edu
# 2023-05-12

# Load libraries
library(sf)    # reading in shapefiles
library(terra) # raster functions
library(dplyr) # data wrangling

# Currently a proof of concept, where mean values for each municipality are 
# extracted for the three weather variables (temperature, precipitation, 
# drought) for one year (1995) and one country (El Salvador)
# Next step is to do this for all four countries, across all years of data and 
# create a single data frame with the following columns:
# Country | Municipality | Year | temp | prec_gpcp | droughtcrop_speibase
# This will then be joined with flood and conflict data

# Four countries: El Salvador, Guatemala, Honduras, Mexico

# Subnational Administrative Boundaries level 2 (ADM2) are municipalities
# https://www.geoboundaries.org/index.html#getdata
# Use geoBounaries
# municipality names are in the shapeName field, polygon is in the geometry
# field

el_salvador <- sf::st_read("data/municipality-shapefiles/el-salvador/geoBoundaries-SLV-ADM2.shp")
# guatemala <- sf::st_read("data/municipality-shapefiles/guatemala/geoBoundaries-GTM-ADM2.shp")
# honduras <- sf::st_read("data/municipality-shapefiles/honduras/geoBoundaries-HND-ADM2.shp")
# mexico <- sf::st_read("data/municipality-shapefiles/mexico/geoBoundaries-MEX-ADM2.shp")

# Ultimately will like a score for each municipality for each of the weather
# variables. Weather variables can be rasterized, then we can use the polygon 
# of the municipality to extract a mean (?) for each weather variable.

# Load in weather data
load(file = "data/grid_combined_4country.RData")

# Select only those weather data of interest for one year (1995)
weather_1995 <- grid_combined_4country %>%
  dplyr::filter(year == 1995) %>%
  dplyr::select(xcoord, ycoord, temp, prec_gpcp, droughtcrop_speibase)

# Convert weather data to raster
weather_ras <- terra::rast(x = weather_1995, type = "xyz")

# From documentation of terra::extract
# Turn it into a SpatVector
slv_v <- terra::vect(el_salvador)
# Use the SpatVector to extract mean values from the weather SpatRaster
slv_weather <- extract(x = weather_ras,
                       y = slv_v,
                       mean, 
                       na.rm = TRUE)
# Join those means with municipality names
slv_data <- bind_cols(slv_v$shapeName, slv_weather)
colnames(slv_data)[1] <- "municipality"
head(slv_data)
