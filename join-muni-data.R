# Join municipality annual weather data with flood and conflict data
# Jeff Oliver
# jcoliver@arizona.edu
# 2023-05-19

library(dplyr)
library(stringi)  # Replacement of diacritcs etc. in place names
library(tidyr)    # Making complete matrix

# Load in weather data
# (see create-muni-weather.R)
muni_weather <- read.csv(file = "data/muni-weather.csv")

# Load in flooding data
load(file = "data/flooding_mun_4country.RData")

# TODO: At least one mispelled value in OtherCount: "Gutamala"

# TODO: What are "Country" and "OtherCount" columns? first few rows of flood 
# data have department = AHUACHAPAN and municipality = AHUACHAPAN, but multiple
# countries (this department + municipality is only in El Salvador)
# The lat/long coordinates refer to a spot in the Country column, so what are 
# department & municipality referring to?
flooding_mun_4country %>% 
  select(Country, OtherCount, municipality, department, lat, long) %>%
  head()

# Pull out just columns of interest from the flood dataset; needs some 
# de-duplication, so we start with larger sampling of columns
flood_data <- flooding_mun_4country %>%
  mutate(muni_lower = tolower(municipality),
         dept_lower = tolower(department)) %>%
  select(department, municipality, dept_lower, muni_lower, year, month, day, 
         Country, Dead) %>%
  distinct() %>%
  rename(country = Country,
         dead = Dead)

# Replace diacritics in department & municipality names so we can match with 
# flood data (which lacks any diacritic characters)
muni_weather <- muni_weather %>%
  mutate(department = stringi::stri_trans_general(department, 
                                                  id = "Latin-ASCII"),
         municipality = stringi::stri_trans_general(municipality,
                                                    id = "Latin-ASCII"))

# Create dept_lower & muni_lower column for easier joining
muni_weather <- muni_weather %>%
  mutate(dept_lower = tolower(department),
         muni_lower = tolower(municipality))

# Summarize the flood data by country, department, municipality, year, and 
# month; prepare for join with weather data
flood_summary <- flood_data %>%
  group_by(country, dept_lower, muni_lower, year, month) %>%
  summarize(flood_count = n()) %>%
  ungroup() %>%
  mutate(year = as.numeric(year),
         month = as.numeric(month))

# head(flood_summary)
# head(muni_weather)

# Make a "complete" version of flood summary, so each municipality has a row 
# for each year/month combination
# Doesn't currently work - ends up with municipalities in wrong country
# flood_complete <- flood_summary %>%
#   group_by(country, dept_lower, muni_lower) %>%
#   tidyr::complete(year, month,
#                   fill = list(flood_count = 0))
# Doesn't currently work - ends up with municipalities in wrong country
# flood_complete <- flood_summary %>%
#   tidyr::expand(nesting(country, dept_lower, muni_lower),
#                 year, month)
flood_complete <- flood_summary %>%
  tidyr::complete(year, month, nesting(country, dept_lower, muni_lower),
                  fill = list(flood_count = 0))

# Testing behavior of complete
df <- data.frame(country = c("Me", "Me", "El", "El"),
                 dept = c("A", "B", "C", "D"),
                 year = c(1995, 1993, 1995, 1994),
                 month = c(1, 2, 3, 4), 
                 flood_count = c(NA, 2, 1, NA))
df_complete <- df %>% 
  tidyr::complete(year, month, nesting(country, dept),
                  fill = list(flood_count = 0))
table(df_complete$country, df_complete$dept)
df_complete
df_complete %>% filter(country == "Me")
# Join weather data with flood data; year ranges are different:
#  + flood_summary: 1985-2019
#  + muni_weather: 1980-2010
# For now, only include years that intersect
# muni_combined <- muni_weather %>%
#   full_join(flood_summary, 
#             by = c("country", "dept_lower", "muni_lower", "year")) %>%
#   select(-c(dept_lower, muni_lower)) %>%
#   filter(year %in% intersect(muni_weather$year, flood_summary$year))
muni_combined <- muni_weather %>%
  full_join(flood_complete, 
            by = c("country", "dept_lower", "muni_lower", "year")) %>%
  select(-c(dept_lower, muni_lower)) %>%
  filter(year %in% intersect(muni_weather$year, flood_summary$year))

# head(muni_combined)

# Not all year/month/municipality combinations have a value for flood_count so 
# the value of month and year are NA; will want to make complete dataset, 
# filling a value of 0 for flood_count for all year/month combinations where 
# there is _not_ already a value in the flood_count column. Probably want to do 
# this _before_ the join, so climate data (precip, temp, drought) are repeated 
# appropriately

# How large would a complete dataset be? How many separate municipalities are 
# there?
muni_count <- muni_combined %>% 
  group_by(country, department, municipality) %>%
  summarize(count = n()) %>%
  nrow()
# How many year/month combinations are there?
year_month <- length(unique(x = muni_combined$year)) * 12
# Estimated number of rows in complete data
complete_size <- muni_count * year_month
# 1054248

# Make data frame of all year/month combinations, filling in a value of 0 where
# flood_count is NA
muni_complete <- muni_combined %>%
  group_by(country, department, municipality) %>%
  tidyr::complete(year, month, fill = list(flood_count = 0))
  # tidyr::complete(country, municipality, department, year, month,
  #          fill = list(flood_count = 0))

# Testing to see how big; some gymnastics for vector recycling
df <- data.frame(department = unique(x = muni_combined$department))
df$year <- 1
df$year[] <- 1985:2010
df$month <- 1
df$month[] <- 1:12
df$value <- NA_integer_

df_complete <- df %>%
  tidyr::complete(department, year, month,
                  fill = list(value = 0))

summary(muni_combined)
# TODO: Add conflict data once text encoding gets sorted out

# Load in conflict event data
load(file = "data/GEDEvent_v22_1.RData")
