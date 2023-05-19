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
# drought). Start with an approach for one year (1995) and one country (El 
# Salvador)

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

################################################################################
# Next, an approach for all years for one country.

# Read in the shapefile of municipality boundaries for the country of interest
# (El Salvador)
muni_shapes <- sf::st_read("data/municipality-shapefiles/el-salvador/geoBoundaries-SLV-ADM2.shp")

# Turn this shape into a SpatVector
muni_vectors <- terra::vect(muni_shapes)

# Load in weather data
load(file = "data/grid_combined_4country.RData")

# Find all the years for which we have weather data
years <- sort(unique(grid_combined_4country$year))

# Use vectorization to apply to all years, ignoring Demeter a bit
muni_data_list <- base::lapply(X = years, 
                               FUN = function(year_i) {
     # Pull out weather variables for one year and select columns of interest
     weather_df <- grid_combined_4country %>%
       dplyr::filter(year == year_i) %>%
       dplyr::select(xcoord, ycoord, temp, prec_gpcp, droughtcrop_speibase)
     
     # Convert weather data to raster
     weather_ras <- terra::rast(x = weather_df, type = "xyz")
     
     # Use the municipality SpatVector to extract mean values from the weather 
     # SpatRaster
     muni_weather <- extract(x = weather_ras,
                             y = muni_vectors,
                             mean, 
                             na.rm = TRUE)
     # Add municipality names to this weather data frame; have to wrap in a call 
     # to list() with named element for the municipality; otherwise throws 
     # annoying "New names" message and requires subsequent assignment for the 
     # column where shapeName data end up. Also, 
     #   + drop the manufactured ID column
     #   + add a column for the current year
     muni_data <- dplyr::bind_cols(list(municipality = muni_vectors$shapeName, 
                                        muni_weather)) %>%
       dplyr::select(-ID) %>%
       dplyr::mutate(year = year_i) %>%
     return(muni_data)
  })
# Bind data for all years into a single data frame
all_muni <- dplyr::bind_rows(muni_data_list)

################################################################################

# Finally, do this across all years of data and for all four countries, then
# create a single data frame with the following columns:
# Country | Municipality | Year | temp | prec_gpcp | droughtcrop_speibase
# This will then be joined with flood and conflict data

# Four countries: El Salvador, Guatemala, Honduras, Mexico

