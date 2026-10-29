library(readr)
library(dplyr)


match_coordinates <- function(df, coord){
  cities <- df |> 
    dplyr::select(Arbeitsort) |> 
    unique() |>
    mutate(Arbeitsort = 
             stringr::word(Arbeitsort, 1, 1) |>
             stringr::str_extract(pattern = "[a-zA-Z]+")) |>
    unique() |>
    dplyr::pull(Arbeitsort)
  
  coord <- coord |> dplyr::filter(city %in% cities)
  return(coord)
}
