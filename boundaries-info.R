# Create administrative boundary information (and download data if necessary)
# Jeff Oliver
# jcoliver@arizona.edu
# 2023-05-26

library(geodata) # downloading municipality administrative boundaries
library(dplyr)   # the pipe that is not a pipe

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
    rm(ctry_data)
  }
  rm(ctry_code)
}
rm(row_i)

# Make a column with file path information
boundaries_info <- boundaries_info %>%
  mutate(filename = paste0("data/gadm/", tolower(ctry_code), "/gadm41_",
                           ctry_code, "_2_pk.rds"))
