library(dplyr)


count_total <- function(data_column){
  count <- data_column |> unique() |> length()
  return(count)
}

count_cummulative <- function(data, time_column){
  table <- data |> 
    dplyr::filter(!is.na(.data[[time_column]])) |> 
    dplyr::arrange(.data[[time_column]])
  table$count <- 1:nrow(table)
  return(table)
}
