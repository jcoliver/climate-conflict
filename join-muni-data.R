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

# Pull out just columns of interest from the flood dataset; needs some 
# de-duplication, so we start with larger sampling of columns
flood_data <- flooding_mun_4country %>%
  mutate(muni_lower = tolower(municipality)) %>%
  select(-c(department, munID_str, id, municipality)) %>%
  distinct() %>%
  rename(country = Country) %>%
  select(country, muni_lower, year, month)

# Create muni_lower column for easier joining
muni_weather <- muni_weather %>%
  mutate(muni_lower = tolower(municipality))

# Summarize the flood data by country, municipality, year, and month; prepare 
# for join with weather data
flood_summary <- flood_data %>%
  group_by(country, muni_lower, year, month) %>%
  summarize(flood_count = n()) %>%
  ungroup() %>%
  mutate(year = as.numeric(year),
         month = as.numeric(month))

head(flood_summary)
head(muni_weather)
# TODO: getting many-to-many warning here that should be addressed; one case is 
# in the weather data; should really only have one row per country/muni/year in 
# that data set...
# country  municipality     temp prec_gpcp droughtcrop_speibase year    muni_lower
# 1 El Salvador Santo Domingo 26.59833  1650.678           0.00000000 1992 santo domingo
# 2 El Salvador Santo Domingo 25.06667  1650.678           0.08333334 1992 santo domingo
muni_combined <- muni_weather %>%
  full_join(flood_summary, by = c("country", "muni_lower", "year")) %>%
  select(-muni_lower)

head(muni_weather)


# TODO: Add conflict data once text encoding gets sorted out

# Load in conflict event data
load(file = "data/GEDEvent_v22_1.RData")
