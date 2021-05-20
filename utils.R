require(dplyr)

##
# Cleans up a string by:
#
#   - removing leading and trailing whitespace
#   - removing multiple spaces and replacing with a single space
#
clean_string <- function(input) {
  gsub("\\s+", " ", trimws(input))
}


##
# Imports and cleans data from the HGY dataset. This dataset contains ~100k stars
# closest to Sol
#
import_and_clean_stars <- function(file="source_data/hygdata_v3.csv") {
  read.csv2(file = file, header = TRUE, sep = ",", dec = ".", na.strings = "") %>%
    dplyr::rename(
      hyg_database_id = id,
      hipparcos_catalog_id = hip,
      henry_draper_catalog_id = hd,
      harvard_revised_catalog_id = hr,
      gliese_catalog_id = gl,
      bayer_flamsteed_designation = bf,
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
    ) %>%
    mutate(
      bayer_flamsteed_designation = clean_string(bayer_flamsteed_designation),
      proper_name = clean_string(proper_name),
      spectral_type = clean_string(spectral_type),
      color_index = clean_string(color_index)
    ) %>%
    mutate(
      star_id = row_number()
    ) %>%
    relocate(star_id)
}

##
# Imports ~4700 exoplanet data from exoplanet.eu_catalog.csv
#
import_and_clean_exoplanet_eu_catalog <- function(file="source_data/exoplanet.eu_catalog.csv") {
  planets <- read.csv2(file = file, header = TRUE, sep = ",") %>%
    dplyr::rename(
      planet_name = "X..name",
    ) %>%
    mutate(
      planet_name = clean_string(planet_name),
      star_name = clean_string(star_name),
    ) %>%
    mutate(
      planet_id = row_number()
    ) %>%
    relocate(
      planet_id
    )
}
