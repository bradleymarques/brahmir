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

# (OPTIONAL) Plot the data as a sense-check
# plot_data(stars, planets)

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
