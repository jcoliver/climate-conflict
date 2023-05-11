# Combine flood data with weather data (temp, precip, drought)
# Jeff Oliver
# jcoliver@arizona.edu
# 2023-05-08

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

# A list that will hold one data frame for each year; will bind all together 
# after process is finished
combined_list <- list()
for (one_year in flooding_years) {
  # Extract the weather variables for one year
  weather_data <- grid_combined_4country %>%
    dplyr::filter(year == one_year) %>%
    dplyr::select(xcoord, ycoord, temp, prec_gpcp, droughtcrop_speibase)
  # Don't have weather data for all years, so only proceed if we do
  if (nrow(weather_data) > 0) {
    # Convert weather data to a raster for easier extraction
    weather_raster <- terra::rast(x = weather_data, type = "xyz")
    # Pull out flood data for just this year
    flood_data <- flooding_mun_4country %>%
      dplyr::filter(year == one_year)
    # Use terra to extract values for lat/long coords in flood dataset
    # y must be a two-column data frame (x, y)
    weather_columns <- terra::extract(x = weather_raster,
                              y = flood_data[, c("long", "lat")])
    # Add those weather variables back to data frame for this year; we do not 
    # need the first column, which is an (uninformative) ID column
    flood_data <- flood_data %>%
      bind_cols(weather_columns[, 2:4])
    # Reset to default rownames
    rownames(flood_data) <- NULL
    # Add to the combined list indexed by character year
    combined_list[[as.character(one_year)]] <- flood_data
  } else {
    message("Missing weather data for ", one_year, ".")
  }
}

# Combine all data for which there are weather data
combined_data <- combined_list %>%
  bind_rows()

# Restrict columns to those of interest
output_data <- combined_data %>%
  dplyr::select(municipality, year, month, lat, long, temp, 
                droughtcrop_speibase, prec_gpcp)

# | municipality | flooding_mun_4country.RData |
#   | year | flooding_mun_4country.RData |
#   | month | flooding_mun_4country.RData |
#   | lat | flooding_mun_4country.RData |
#   | long | flooding_mun_4country.RData |
#   | temperature | grid_combined_4country.RData |
#   | drought | grid_combined_4country.RData |
#   | precipitation | grid_combined_4country.RData |
#   | flood | flooding_mun_4country.RData |
#   | count of conflict event | ??? |
#   | conflict zone | ??? |

################################################################################
# Initial tests below here on single year of data

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
