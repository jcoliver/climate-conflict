# Climate Conflict

Data manipulation for project investigating conflict zones and extreme climate 
events

## Summary

This repository holds code (and some data) to create datasets for analysis on 
the level of municipality (ADM2) for four countries (El Salvador, Guatemala,
Honduras, and Mexico). The goal is to ultimately create a tabular dataset with 
the following columns:

+ country (ADM 0)
+ department (ADM 1)
+ municipality (ADM 2)
+ year
+ month
+ temperature
+ drought
+ precipitation
+ number of floods
+ number conflict events
+ total area of conflict events (on hold)

## Data

Descriptions of original data sets with relevant columns listed.

+ Conflict Site 4-2006.xls: a geocoded conflict zone
  + ID: conflict identifier
  + Year: Year of observation. 
  + Coordinate: Latitude & Longitude of the geographical center of the conflict 
  zone. 
  + Radius: The radius of the conflict zone is given in 50 kilometer intervals, 
  rounded upwards. If a conflict took place within a single spot the radius is 
  set at 50 kilometers. 
  + Conflict area: Area of the conflict zone in square kilometers. 
+ ConflictSite 4-2010.xls: a geocoded conflict zone
  + ID: conflict identifier
  + Year: Year of observation. 
  + Coordinate: Latitude & Longitude of the geographical center of the conflict 
  zone. 
  + Radius: The radius of the conflict zone is given in 50 kilometer intervals, 
  rounded upwards. If a conflict took place within a single spot the radius is 
  set at 50 kilometers. 
  + Conflict area: Area of the conflict zone in square kilometers. 
+ flooding_mun_4country.RData: flood event data frame
  + year_start & month_start: the year and month flood started
  + year_end & month_end: the year and month flood ended
  + coordinate: decimal latitude & longitude
  + municipality: municipality in which the flood occurred
  + area: size of area affected by floods
  + displaced: total number of pop displaced due to floods
  + dead: deaths due to floods
+ GEDEvent_v22_1.rds: a conflict event point data frame
  + id: identifier for each conflict event
  + active_year: year that conflict event occurred
  + coordinate: decimal latitude & longitude
+ grid_combined_4country.RData: climate data frame; standardized spatial grid 
structure with global coverage at a resolution of 0.5 x 0.5 decimal degrees. 
  + gid: grid cell identifier
  + coordinate: decimal longitude (xcoord) & latitude (ycoord)
  + year: year of measurement
  + temp: yearly mean temperature (in degrees Celsius) in the cell 
  + prec_gpcp: gives the yearly total amount of precipitation (in millimeters) 
  in the cell
  + droughtcrop_speibase: proportion of main crop growing season experienced 
  drought

## Scripts

Scripts, in order of execution.

1. boundaries-info.R: Create dataframe with administrative boundary data 
information (directory name, country code, and path to shapefile)
1. create-muni-weather.R: Extract weather data for each municipality on an 
annual basis. Uses administrative boundaries from GADM to extract mean values 
from rasterized weather data.
1. add-muni-to-flood.R: Add country, department, and municipality to each point 
in flood event data. Based on GADM boundaries.
1. add-muni-to-conflict.R: Add country, department, and municipality to each 
point in conflict data. Based on GADM boundaries.
1. join-muni-data.R: Join municipality weather data with flood and conflict data 
for each municipality

## Other information

Marshall, B., Solomon, M.H. & Edward, M. 2015. Climate and conflict. Annual Review of
Economics. DOI:[10.1146/annurev-economics-080614-115430](https://doi.org/10.1146/annurev-economics-080614-115430)