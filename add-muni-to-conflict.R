# Extract country, department, and municipality information for conflict data
# Jeff Oliver
# jcoliver@arizona.edu
# 2023-06-02

# Load libraries
library(sf)        # reading in shapefiles, querying points in polygons
library(dplyr)     # data wrangling
library(lubridate) # month extraction

# Load in administrative boundaries information (will download data if it does 
# not already exist on disk). Creates data frame boundaries_info
source(file = "boundaries-info.R")

# Load in conflict data
# originally retrieved from https://ucdp.uu.se/downloads/index.html#ged_global
# as a CSV file and saved as RDS to save space.
conflict_all <- readRDS(file = "data/GEDEvent_v22_1.rds")

# Select subset of columns of interest, restrict region = Americas, and add 
# columns for country, department, and municipality
conflict_data <- conflict_all %>%
  dplyr::select(id, year, latitude, longitude, region, date_start) %>%
  dplyr::filter(region == "Americas") %>%
  mutate(country = NA_character_,
         department = NA_character_,
         municipality = NA_character_)
rm(conflict_all)

# Want to extract month from the date_start column
conflict_data <- conflict_data %>%
  mutate(month = month(date_start)) %>%
  dplyr::select(-date_start)

# For each country (each row in the boundaries_info data frame), do points in 
# polygon test for rows in the conflict data. Update department and 
# municipality information as appropriate
# Name_1 = department
# Name_2 = municipality
wgs84 <- "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"
# To work with sf::st_within, we need conflict data in sf format
conflict_data_sf <- sf::st_as_sf(x = conflict_data,
                              coords = c("longitude", "latitude"),
                              crs = wgs84) # TODO: an assumption!
for (country_i in 1:nrow(boundaries_info)) {
  country_code <- boundaries_info$ctry_code[country_i]
  message("Extracting information for ", country_code)
  muni_vectors <- readRDS(file = boundaries_info$filename[country_i])
  # Query rows in conflict data coordinates
  muni_sf <- sf::st_as_sf(muni_vectors)

  # Returns a sparse matrix with number of elements equal to number of rows in 
  # conflict data. Values in each element indicate index of muni_sf (and thus 
  # muni_vectors) in which point lies. 0-length integer vectors indicate no 
  # match. Index of the sparse matrix indicates the row of conflict_data_sf 
  # (and thus conflict_data).
  conflict_in <- sf::st_within(x = conflict_data_sf, y = muni_sf)
  # Extract values for extraction of department & municipality names
  # Start by extracting first element of each list element
  muni_index <- unlist(lapply(X = conflict_in, FUN = "[", 1))
  # Add the new (temporary) columns to the conflict data
  conflict_data$new_coun <- muni_vectors$COUNTRY[muni_index]
  conflict_data$new_dept <- muni_vectors$NAME_1[muni_index]
  conflict_data$new_muni <- muni_vectors$NAME_2[muni_index]
  
  # Update department & municipality columns if no value already exists
  conflict_data <- conflict_data %>%
    mutate(country = if_else(is.na(country),
                             true = new_coun,
                             false = country),
           department = if_else(is.na(department), 
                                true = new_dept,
                                false = department),
           municipality = if_else(is.na(municipality),
                                  true = new_muni,
                                  false = municipality))
  # # Reality check, to see if any points were identified outside the original 
  # # country designation
  # conflict_data <- conflict_data %>%
  #   mutate(country_mismatch = if_else(!is.na(country) & !is.na(new_coun),
  #                                     true = country != new_coun,
  #                                     false = FALSE))
  # 
  # num_mismatches = sum(conflict_data$country_mismatch, na.rm = TRUE)
  # if (num_mismatches > 0) {
  #   message("Found ", num_mismatches, " country mismatches in ", country_code)
  #   one_mismatch <- which(conflict_data$country_mismatch)[1]
  #   message("See row ", one_mismatch, " for one example.")
  # }
  
  # Drop the temporary administrative info columns
  conflict_data <- conflict_data %>%
    select(-c(new_coun, new_dept, new_muni))
}

# Reality check to see which rows had no data
missing_adm <- which(is.na(conflict_data$department))
# spot checks indicate lat/long coordinates are in different countries (e.g. 
# Venezuela)
# conflict_data[missing_adm[(length(missing_adm) - 5):length(missing_adm)], ]
conflict_data <- conflict_data[-missing_adm, ]

write.csv(x = conflict_data,
          file = "data/conflict-data.csv",
          row.names = FALSE)
