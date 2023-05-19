# Join municipality annual weather data with flood and conflict data
# Jeff Oliver
# jcoliver@arizona.edu
# 2023-05-19

library(dplyr)

# Load in weather data
# (see create-muni-weather.R)
muni_weather <- read.csv(file = "data/muni-weather.csv")

# Load in flooding data
load(file = "data/flooding_mun_4country.RData")

# Pull out just columns of interest from the flood dataset
flood_data <- flooding_mun_4country %>%
  select(Country, municipality, year, month)

# Summarize the flood data by country, municipality, year, and month
flood_summary <- flood_data %>%
  group_by(Country, municipality, year, month) %>%
  summarize(flood_count = n()) %>%
  ungroup() %>%
  mutate(year = as.numeric(year),
         month = as.numeric(month))

# Join the weather data by municipality & year; start by creating dummy column 
# muni_lower in each dataset for easier joining; remove original municipality 
# column from from flood data before join
muni_weather <- muni_weather %>%
  mutate(muni_lower = tolower(municipality))
flood_summary <- flood_summary %>%
  mutate(muni_lower = tolower(municipality)) %>%
  select(-municipality)

# TODO: getting many-to-many warning here that should be addressed
muni_combined <- flood_summary %>%
  full_join(muni_weather, by = c("Country" = "country", "muni_lower", "year"))

head(muni_weather)


# TODO: Add conflict data once text encoding gets sorted out

# Load in conflict event data
load(file = "data/GEDEvent_v22_1.RData")
