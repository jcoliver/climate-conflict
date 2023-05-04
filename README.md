# Climate Conflict
Data manipulation for project investigating conflict zones and extreme climate 
events

## Data

+ Conflict Site 4-2006.xls: a geocoded conflict zone
  + ID: conflict identifier
  + Year: Year of observation. 
  + Coordinate: Latitude & Longitude of the geographical center of the conflict 
  zone. 
  + Radius: The radius of the conflict zone is given in 50 kilometer intervals, 
  rounded upwards. If a conflict took place within a single spot the radius is 
  set at 50 kilometers. 
  + Conflict area: Area of the conflict zone in square kilometers. 

+ flooding_mun_4country.RData: flood event data frame, including
  + year_start & month_start: the year and month flood started
  + year_end & month_end: the year and month flood ended
  + coordinate: decimal latitude & longitude
  + municipality: municipality in which the flood occurred
  + area: size of area affected by floods
  + displaced: total number of pop displaced due to floods
  + dead: deaths due to floods

+ GEDEvent_v22_1.RData: a conflict event point data frame
  + id: identifier for each conflict event
  + active_year: year that conflict event occurred
  + coordinate: decimal latitude & longitude

+ grid_combined_4country.RData: climate data frame; standardized spatial grid 
structure with global coverage at a resolution of 0.5 x 0.5 decimal degrees. 
Interested in starting with the following variables:
  + gid: grid cell identifier
  + coordinate: decimal longitude (xcoord) & latitude (ycoord)
  + year: year of measurement
  + temp: yearly mean temperature (in degrees Celsius) in the cell 
  + prec_gpcp: gives the yearly total amount of precipitation (in millimeters) 
  in the cell
  + droughtcrop_speibase: proportion of main crop growing season experienced 
  drought

+ World_Cities_shapefile.zip
