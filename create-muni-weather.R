# Extract weather data for each municipality on an annual basis
# Jeff Oliver
# jcoliver@arizona.edu
# 2023-05-19

# Load libraries
library(geodata) # downloading municipality administrative boundaries
library(sf)      # reading in shapefiles
library(terra)   # raster functions
library(dplyr)   # data wrangling

# Municipality bounaries are from GADM, https://gadm.org
# NAME_1 = department (ADM1)
# NAME_2 = municipality (ADM2)
# Retrieved (if necessary) via geodata::gadm()

# Create a single data frame with the following columns:
# country | municipality | temp | prec_gpcp | droughtcrop_speibase | year
# This will later be joined with flood and conflict data

# Four countries: El Salvador, Guatemala, Honduras, Mexico

# Make a data frame for easier iteration and file path information
boundaries_info <- data.frame(dir_name = c("el-salvador", "guatemala", 
                                          "honduras", "mexico"),
                             ctry_code = c("SLV", "GTM", "HND", "MEX"))

# Check for boundary data files; download them if they do not exist locally
for (row_i in 1:nrow(boundaries_info)) {
  ctry_code <- boundaries_info$ctry_code[row_i]
  if (!file.exists(paste0("data/gadm/", tolower(ctry_code), "/gadm41_",
                          ctry_code, "_2_pk.rds"))) {
    message("Downloading ADM2 data for ", ctry_code)
    ctry_data <- geodata::gadm(country = ctry_code,
                               level = 2,
                               path = paste0("data/gadm/", tolower(ctry_code)))
  }
}

# Make a column with file path information
boundaries_info <- boundaries_info %>%
  mutate(filename = paste0("data/gadm/", tolower(ctry_code), "/gadm41_",
                           ctry_code, "_2_pk.rds"))

# Load in weather data
load(file = "data/grid_combined_4country.RData")

# Find all the years for which we have weather data
years <- sort(unique(grid_combined_4country$year))

# List to hold data, one element per country, indexed by directory name
all_countries_list <- vector(mode = "list", length = nrow(boundaries_info))
names(all_countries_list) <- boundaries_info$dir_name

# Takes a couple of minutes, mostly as it works on the data for Mexico
for (row_i in 1:nrow(boundaries_info)) {
  dir_name <- boundaries_info$dir_name[row_i]
  message("Processing weather for directory ", dir_name)
  # Read in the municipality boundaries for the country of interest
  muni_vectors <- readRDS(file = boundaries_info$filename[row_i])
  
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
     # to list() with named elements for the municipality and department; 
     # otherwise throws annoying "New names" message and requires subsequent 
     # assignment for the column where shapeName data end up. Also, 
     #   + drop the manufactured ID column
     #   + add a column for the current year
     muni_data <- dplyr::bind_cols(list(municipality = muni_vectors$NAME_2, 
                                        department = muni_vectors$NAME_1,
                                        muni_weather)) %>%
       dplyr::select(-ID) %>%
       dplyr::mutate(year = year_i)
     
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

