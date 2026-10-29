library(meteo)
library(stringr)
library(readr)


source("R/get-data.R")


df <- get_data()

cities <- df |> 
  dplyr::select(Arbeitsort) |> 
  unique() |>
  mutate(Arbeitsort = stringr::word(Arbeitsort, 1, 1) |>
           stringr::str_to_lower() |>
           stringr::str_extract(pattern = "[a-z]+")) |>
  dplyr::pull(Arbeitsort)
cities

coord <- data.frame("city"=cities, "lon"=NA, "lat"=NA)[0,]
for(city in cities){
  try( coord[coord$city == city, c("lon", "lat")] <- meteo::get_coordinates(location_name = city) ) # failed due to too many requests...
}

coord$source <- "Nominatim geocoding service based on OpenStreetMap data"

readr::write_csv(coord, "data/city_coordinates_downloaded.csv")
