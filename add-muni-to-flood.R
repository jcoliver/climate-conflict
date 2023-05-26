# Extract country, department, and municipality information for flood data
# Jeff Oliver
# jcoliver@arizona.edu
# 2023-05-26

# Load libraries
library(sf)      # reading in shapefiles, querying points in polygons
library(dplyr)   # data wrangling

# Load in administrative boundaries information (will download data if it does 
# not already exist on disk). Creates data frame boundaries_info
source(file = "boundaries-info.R")

# Load in original flood data
load(file = "data/flooding_mun_4country.RData")

# Remove country, department, municipality data, which are not accurate
flood_data <- flooding_mun_4country %>%
  rename(OriginalCountry = Country) %>%
  mutate(country = NA_character_,
         department = NA_character_,
         municipality = NA_character_) %>%
  rename(longitude = long,
         latitude = lat)
rm(flooding_mun_4country)

# For each country (each row in the boundaries_info data frame), do points in 
# polygon test for rows in the flood data. Update department and municipality 
# information as appropriate
# Name_1 = department
# Name_2 = municipality
wgs84 <- "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"
# To work with sf::st_within, we need flood data in sf format
flood_data_sf <- sf::st_as_sf(x = flood_data,
                              coords = c("longitude", "latitude"),
                              crs = wgs84) # TODO: an assumption!
for (country_i in 1:nrow(boundaries_info)) {
  message("Extracting information for ", boundaries_info$ctry_code[country_i])
  muni_vectors <- readRDS(file = boundaries_info$filename[country_i])
  # Query rows in flood data coordinates
  muni_sf <- sf::st_as_sf(muni_vectors)

  # Returns a sparse matrix with number of elements equal to number of rows in 
  # flood data. Values in each element indicate index of muni_sf (and thus 
  # muni_vectors) in which point lies. 0-length integer vectors indicate no 
  # match. Index of the sparse matrix indicates the row of flood_data_sf (and 
  # thus flood_data).
  flood_in <- sf::st_within(x = flood_data_sf, y = muni_sf)
  # Extract values for extraction of department & municipality names
  # Start by extracting first element of each list element
  muni_index <- unlist(lapply(X = flood_in, FUN = "[", 1))
  # Add the new (temporary) columns to the flood data
  flood_data$new_coun <- muni_vectors$COUNTRY[muni_index]
  flood_data$new_dept <- muni_vectors$NAME_1[muni_index]
  flood_data$new_muni <- muni_vectors$NAME_2[muni_index]
  
  # Update department & municipality columns if no value already exists
  flood_data <- flood_data %>%
    mutate(country = if_else(is.na(country),
                             true = new_coun,
                             false = country),
           department = if_else(is.na(department), 
                                true = new_dept,
                                false = department),
           municipality = if_else(is.na(municipality),
                                  true = new_muni,
                                  false = municipality)) %>%
    select(-c(new_coun, new_dept, new_muni))
}

# Reality check to see which rows had no data
missing_adm <- which(is.na(flood_data$department))
# spot checks indicate lat/long coordinates are in different countries (e.g. 
# Nicaragua & USA)
# flood_data[1:5, ]
# flood_data[missing_adm[(length(missing_adm) - 5):length(missing_adm)], ]

write.csv(x = flood_data,
          file = "data/flood-data.csv",
          row.names = FALSE)
