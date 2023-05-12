# Test rasterizing of weather data
# Jeff Oliver
# jcoliver@arizona.edu
# 2023-05-12

# Load libraries
library(terra)
library(dplyr)

# Load in weather data
load(file = "data/grid_combined_4country.RData")

# Select only those weather data of interest for one year (1995)
weather_1995 <- grid_combined_4country %>%
  dplyr::filter(year == 1995) %>%
  dplyr::select(xcoord, ycoord, temp, prec_gpcp, droughtcrop_speibase)
  
# Convert weather data to raster
weather_ras <- terra::rast(x = weather_1995, type = "xyz")

# Plot precipitation
plot(weather_ras[["prec_gpcp"]])

# Add points where we have precip data
points(x = weather_1995$xcoord, y = weather_1995$ycoord, cex = 0.1)

# Plot temperature
plot(weather_ras[["temp"]])

# Add points where we have precip data
points(x = weather_1995$xcoord, y = weather_1995$ycoord, cex = 0.1)

# Plot drought
plot(weather_ras[["droughtcrop_speibase"]])

# Add points where we have precip data
points(x = weather_1995$xcoord, y = weather_1995$ycoord, cex = 0.1)
