require(dplyr)
require(celestial)
require(nabor)
require(plotly)

WEINS_DISPLACEMENT_CONSTANT <- 2898000 # nanometers x Kelvin

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
# Imports and cleans data from the HGY dataset. This dataset contains ~100k
# stars closest to Sol
#
import_and_clean_stars <- function(file="source_data/hygdata_v3.csv") {
  read.csv2(
    file = file,
    header = TRUE,
    sep = ",",
    dec = ".",
    na.strings = ""
  ) %>%
    dplyr::select(
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
      luminosity = lum,
      x,
      y,
      z,
      velocity_x = vx,
      velocity_y = vy,
      velocity_z = vz
    ) %>% # Filter out those whose distance is not known
    filter(
      distance_from_sol <= 25000
    ) %>%
    mutate(
      bayer_flamsteed_designation = clean_string(bayer_flamsteed_designation),
      proper_name = clean_string(proper_name),
      spectral_type = clean_string(spectral_type),
      color_index = as.numeric(color_index),
      absolute_magnitude = as.numeric(absolute_magnitude)
    ) %>%
    arrange(distance_from_sol) %>%
    mutate(star_id = row_number()) %>%
    relocate(star_id)
}

##
# Imports ~4700 exoplanet data from exoplanet.eu_catalog.csv
#
import_and_clean_exoplanet_eu_catalog <- function(file="source_data/exoplanet.eu_catalog.csv") {
  planets <- read.csv2(file = file, header = TRUE, sep = ",", na.strings = "") %>%
    dplyr::rename(
      planet_name = "X..name",
    ) %>%
    mutate(
      planet_name = clean_string(planet_name),
      star_name = clean_string(star_name),
      ra = as.numeric(ra),
      dec = as.numeric(dec),
      star_distance = as.numeric(star_distance)
    ) %>%
    mutate(
      planet_id = row_number()
    ) %>%
    relocate(
      planet_id
    )

  planets$alternate_names[planets$alternate_names == ""] <- NA
  planets$star_alternate_names[planets$star_alternate_names == ""] <- NA

  return(planets)
}

##
# Adds cartesian coordinates to planetary data.frame
#
add_cartesian_coordinates <- function(planets) {
# Convert from right ascension (ra) and declination (dec) to XYZ coordinates
planet_xyz <- planets %>%
  dplyr::select(planet_id, ra, dec, star_distance) %>%
  mutate(
    coords = sph2car(long = ra, lat = dec, radius = star_distance, deg = TRUE)
  ) %>%
  mutate(
    x = coords[, 1],
    y = coords[, 2],
    z = coords[, 3]
  ) %>%
  dplyr::select(planet_id, x, y, z)

  return(dplyr::left_join(planets, planet_xyz, by = "planet_id"))
}

add_stars_to_planets <- function(stars, planets, threshold=1) {
  star_data <- stars %>% dplyr::select(x, y, z)
  planet_data <- planets %>% dplyr::select(x, y, z)

  nearest_neighbours <- as.data.frame(
    knn(
      data = star_data,
      query = planet_data,
      k = 1,
      radius = 5 # parsecs
    )
  )

  planets$star_id <- nearest_neighbours$nn.id
  planets$distance_to_host_star <- nearest_neighbours$nn.dists

  planets$star_id[planets$star_id == 0] <- NA

  return(planets)
}

add_planet_counts <- function(stars, planets) {
  planet_counts <- stars %>%
    dplyr::select(star_id) %>%
    full_join(dplyr::select(planets, planet_id, star_id), by = "star_id") %>%
    filter(!is.na(planet_id)) %>%
    group_by(star_id) %>%
    summarize(planet_count = n(), .groups = "drop")

  stars <- stars %>%
    left_join(planet_counts, by = "star_id")

  stars$planet_count[is.na(stars$planet_count)] <- 0

  return(stars)
}

add_temperature_and_wavelength <- function(stars) {
  stars <- stars %>%
    mutate(temperature = color_index_to_temperature(color_index)) %>%
    mutate(peak_wavelength = temperature_to_wavelength(temperature))
}

add_color <- function(stars) {
  color_table <- read.csv2(
    file = "source_data/color_index_to_color_table.csv",
    header = TRUE,
    sep = ";",
    dec = ".",
    na.strings = ""
  )
  color_data <- color_table$color_index
  star_data <- stars$color_index

  nearest_neighbours <- as.data.frame(
    knn(
      data = color_data,
      query = star_data,
      k = 1
    )
  )

  stars$color_id <- nearest_neighbours$nn.idx

  stars <- stars %>% left_join(
    dplyr::select(
      color_table,
      color_id,
      hex_color,
      red_color,
      green_color,
      blue_color
    ),
    by = "color_id"
  )

  return(stars)
}

##
# https://www.quora.com/How-can-I-derive-an-RGB-value-from-the-color-index-of-stars
#
color_index_to_temperature <- function(color_index) {
  4600 * (
    (1.0 / (0.92 * color_index + 1.7)) +
    (1.0 / (0.92 * color_index + 0.62))
  )
}

##
# https://www.quora.com/How-can-I-derive-an-RGB-value-from-the-color-index-of-stars
#
temperature_to_wavelength <- function(temperature) {
  (WEINS_DISPLACEMENT_CONSTANT / temperature)
}

################################################################################
# Plotting functions

plot_positions <- function(stars, planets) {
  p <- sample_n(stars, 10000) %>%
  dplyr::select(x, y, z) %>%
    mutate(type = "star") %>%
    rbind(
      dplyr::select(planets, x, y, z) %>%
      mutate(type = "planet")
    )

  plot_ly(p, x = ~x, y = ~y, z = ~z, color = ~type, opacity = 0.2)
}

plot_stars <- function(stars) {
  data <- sample_n(stars, 10000)

  fig <- plot_ly(type = "scatter3d", mode = "markers")
  fig <- fig %>% add_trace(
    x = data$x,
    y = data$y,
    z = data$z,
    opacity = 1,
    marker = list(
      color = data$hex,
      size = data$absolute_magnitude
    )
  )
  fig
}
