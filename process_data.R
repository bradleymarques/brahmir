# Include utility functions
source("utils.R")

# Import raw data
stars <- import_and_clean_stars()
planets <- import_and_clean_exoplanet_eu_catalog()

# Add XYZ Cartesian coordinates to planet data
planets <- add_cartesian_coordinates(planets)

# Try to match each planet to the nearest star
# Calculating all possible distances would be very inefficient, so only consider
planets <- add_stars_to_planets(stars = stars, planets = planets, threshold = 1)

# Get planet count per star
stars <- add_planet_counts(stars, planets)

# Add additional data
stars <- add_temperature_and_wavelength(stars)
stars <- add_color(stars)

# (OPTIONAL) Plots
# plot_positions(stars, planets)
# plot_stars(stars)

# Write the data out
write.table(
  planets,
  file = "output/planets.csv",
  sep = ";",
  na = "",
  dec = ".",
  row.names = FALSE,
  col.names = TRUE
)

write.table(
  stars,
  file = "output/stars.csv",
  sep = ";",
  na = "",
  dec = ".",
  row.names = FALSE,
  col.names = TRUE
)

# Write samples of the data out
write.table(
  head(planets, 5),
  file = "output/samples/planets.csv",
  sep = ";",
  na = "",
  dec = ".",
  row.names = FALSE,
  col.names = TRUE
)

write.table(
  head(stars, 5),
  file = "output/samples/stars.csv",
  sep = ";",
  na = "",
  dec = ".",
  row.names = FALSE,
  col.names = TRUE
)
