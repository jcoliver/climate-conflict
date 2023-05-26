# Join municipality annual weather data with flood and conflict data
# Jeff Oliver
# jcoliver@arizona.edu
# 2023-05-19

library(dplyr)
library(stringi)  # Replacement of diacritcs etc. in country names
library(tidyr)    # Making complete matrix

# Load in weather data
# (see create-muni-weather.R)
muni_weather <- read.csv(file = "data/muni-weather.csv")

# Load in flooding data
# load(file = "data/flooding_mun_4country.RData")
flood_data <- read.csv(file = "data/flood-data.csv")

# Only want to join on years with flood data *AND* weather data
year_intersect <- dplyr::intersect(x = flood_summary$year,
                                   y = muni_weather$year)

# Drop flood data rows missing municipality information & filter by year
flood_data <- flood_data %>%
  filter(!is.na(municipality)) %>%
  filter(year %in% year_intersect)

# Flood data uses a diacritic for México, but weather data does not, update 
# values in weather data for consistency; filter by year
muni_weather <- muni_weather %>%
  mutate(country = gsub(pattern = "Mexico",
                        replacement = "México", 
                        x = country)) %>%
  filter(year %in% year_intersect)

# Summarize the flood data by country, department, municipality, year, and 
# month; prepare for join with weather data
flood_summary <- flood_data %>%
  group_by(country, department, municipality, year, month) %>%
  summarize(flood_count = n()) %>%
  ungroup() %>%
  mutate(year = as.numeric(year),
         month = as.numeric(month))

# Little reality check on summarize (should evaluate as TRUE)
nrow(flood_data) == sum(flood_summary$flood_count)

# Reality check
# Are any municipalities in flood dataset *NOT* in the muni_weather data?
missing_munis <- dplyr::setdiff(x = flood_summary$municipality,
                                y = muni_weather$municipality)
length(missing_munis) # Should evaluate as 0

# Make a "complete" version of flood summary, so each municipality has a row 
# for each year/month combination

# However, not all municipalities are necessarily represented in the flood 
# data, so we need the union of municipalities from weather and flood data to 
# start. Will just do the ugly thing of binding rows. Apologies.
# Start by creating data frame of all municipalities present in weather data 
# but absent from flood data
munis_to_add <- dplyr::setdiff(x = muni_weather %>% select(country, department, municipality),
                               y = flood_summary %>% select(country, department, municipality))
# Add dummy values so making the complete matrix will work
munis_to_add <- munis_to_add %>%
  mutate(year = flood_summary$year[1],
         month = flood_summary$month[1],
         flood_count = 0)

# Add a row of each of the municipalities to the flood_summary object
flood_summary <- flood_summary %>%
  bind_rows(munis_to_add)

# Make a complete matrix, where each country/department/municipality 
# combination has a row for each year/month combination
flood_complete <- flood_summary %>%
  tidyr::complete(year, month, nesting(country, department, municipality),
                  fill = list(flood_count = 0))

# Now (finally!) join the weather data with the flood data
muni_combined <- muni_weather %>%
  left_join(flood_complete, by = c("year", "country", "department", 
                                   "municipality"))
# summary(muni_combined)

# Write to disk (probably a temporary solution - 80 MB csv file...)
write.csv(file = "data/muni-weather-flood.csv",
          x = muni_combined,
          row.names = FALSE)

# TODO: Add conflict data once text encoding gets sorted out

# Load in conflict event data
load(file = "data/GEDEvent_v22_1.RData")
