# Extract weather data for each municipality on an annual basis
# Jeff Oliver
# jcoliver@arizona.edu
# 2023-05-19

# Load libraries
library(sf)    # reading in shapefiles
library(terra) # raster functions
library(dplyr) # data wrangling

# Shapefile data for municipality boundaries are from geoBoundaries
# https://www.geoboundaries.org/index.html#getdata
# Use geoBounaries
# Subnational Administrative Boundaries level 2 (ADM2) are municipalities
# municipality names are in the shapeName field, polygon is in the geometry
# field

# Create a single data frame with the following columns:
# country | municipality | temp | prec_gpcp | droughtcrop_speibase | year
# This will later be joined with flood and conflict data

# Four countries: El Salvador, Guatemala, Honduras, Mexico

# Make a data frame for easier iteration and file path information
shapefile_info <- data.frame(dir_name = c("el-salvador", "guatemala", 
                                          "honduras", "mexico"),
                             ctry_code = c("SLV", "GTM", "HND", "MEX"))
# Make a column with file path information
# Could use the simplified shapes, instead. Resolution is lower, but not by 
# much
shapefile_info <- shapefile_info %>%
  mutate(filename = paste0("data/municipality-shapefiles/", dir_name, 
                           "/geoBoundaries-", ctry_code, "-ADM2.shp"))
# Simplified version
# shapefile_info <- shapefile_info %>%
#   mutate(filename = paste0("data/municipality-shapefiles/", dir_name, 
#                            "/geoBoundaries-", ctry_code, "-ADM2_simplified.shp"))

# Load in weather data
load(file = "data/grid_combined_4country.RData")

# Find all the years for which we have weather data
years <- sort(unique(grid_combined_4country$year))

# List to hold data, one element per country, indexed by directory name
all_countries_list <- vector(mode = "list", length = nrow(shapefile_info))
names(all_countries_list) <- shapefile_info$dir_name

# Takes a couple of minutes, mostly as it works on the data for Mexico
for (row_i in 1:nrow(shapefile_info)) {
  dir_name <- shapefile_info$dir_name[row_i]
  message("Processing weather for directory ", dir_name)
  # Read in the shapefile of municipality boundaries for the country of interest
  muni_shapes <- sf::st_read(dsn = shapefile_info$filename[row_i], 
                             quiet = TRUE)
  
  # Turn this shape into a SpatVector
  muni_vectors <- terra::vect(muni_shapes)
  
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
  all_countries_list[[dir_name]] <- dplyr::bind_rows(muni_data_list)
}
# Bind data for all countries into a single data frame
all_countries <- dplyr::bind_rows(all_countries_list,
                                  .id = "country")
# Update the country names to more human-readable version; takes a couple of 
# seconds (>100,000 rows)
all_countries <- all_countries %>%
  mutate(country = tools::toTitleCase(country)) %>%
  mutate(country = gsub(pattern = "-", replacement = " ", x = country))
# Write to file
write.csv(x = all_countries,
          file = "data/muni-weather.csv",
          row.names = FALSE)
