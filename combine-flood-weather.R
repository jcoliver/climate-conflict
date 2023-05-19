# Combine flood data with weather data (temp, precip, drought)
# Jeff Oliver
# jcoliver@arizona.edu
# 2023-05-08

# DEPRECATED
# See join-muni-data.R

# Load libraries
library(terra)
library(dplyr)

# Load in two datasets
load(file = "data/flooding_mun_4country.RData")
load(file = "data/grid_combined_4country.RData")

# Select only those weather data of interest
grid_combined_4country <- grid_combined_4country %>%
  dplyr::select(gid, year, xcoord, ycoord, temp, prec_gpcp, droughtcrop_speibase)

# Convert year, month, & day to numeric
flooding_mun_4country <- flooding_mun_4country %>%
  mutate(year = as.numeric(year),
         month = as.numeric(month),
         day = as.numeric(day))


# TODO: May have to start with a loop approach, iterating over all years
# TODO: flood data range 1985-2019, but weather data are only up to 2010
flooding_years <- sort(unique(flooding_mun_4country$year))

# Make a list of SpatRasters, where each element in the list corresponds to one 
# year and each list element has three layers (temp, prec, drought)

# Testing just on 1995 data
test_1995 <- grid_combined_4country %>%
  dplyr::filter(year == 1995) %>%
  dplyr::select(xcoord, ycoord, temp, prec_gpcp, droughtcrop_speibase)

# Convert weather data to raster
test_1995_ras <- terra::rast(x = test_1995, type = "xyz")

# Testing on 1995 data
flood_1995 <- flooding_mun_4country %>%
  dplyr::filter(year == 1995)

# Use terra to extract values for lat/long coords in flood dataset
# y must be a two-column data frame (x, y)
temp <- terra::extract(x = test_1995_ras,
                       y = flood_1995[, c("long", "lat")])
# Add the extracted values back with bind_cols
flood_1995 <- flood_1995 %>%
  bind_cols(temp[, 2:4])
# Because rownames get weird
rownames(flood_1995) <- NULL
head(flood_1995)
head(flooding_mun_4country %>% filter(year == 1995))
