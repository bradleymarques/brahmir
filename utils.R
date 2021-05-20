require(dplyr)

##
# Imports and cleans data from the HGY dataset. This dataset contains ~100k stars
# closest to Sol
#
import_and_clean_stars <- function(file="source_data/hygdata_v3.csv") {
  read.csv2(file = file, header = TRUE, sep = ",", dec = ".", na.strings = "") %>%
    dplyr::select(
      hyg_database_id = id,
      hipparcos_catalog_id = hip,
      henry_draper_catalog_id = hd,
      harvard_revised_catalog_id = hr,
      gliese_catalog_id = gl,
      bayer_flamsetted_designation = bf,
      proper_name = proper,
      right_ascension = ra,
      declination = dec,
      distance_from_sol = dist,
      visual_magnitude = mag,
      absolute_magnitude = absmag,
      spectral_type = spect,
      color_index = ci,
      constellation = con,
      luminosity = lum
    ) %>% # Filter out those whose distance is not known
    filter(
      distance_from_sol <= 25000
    )
}

##
# Imports ~4700 exoplanet data from exoplanet.eu_catalog.csv
#
import_and_clean_exoplanet_eu_catalog <- function(file="source_data/exoplanet.eu_catalog.csv") {
  planets <- read.csv2(file = file, header = TRUE, sep = ",")
}
