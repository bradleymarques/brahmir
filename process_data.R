# Include useful utility functions
source("utils.R")

# Import raw data
stars <- import_and_clean_stars()
planets_1 <- import_and_clean_exoplanet_eu_catalog()