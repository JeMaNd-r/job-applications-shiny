library("lubridate")


process_data <- function(df){
  # clean dates
  df$Einreichung <- as.Date(vapply(df$Einreichung, function(x) {
    if (is.null(x) || length(x) == 0 || identical(x, "keine")) {
      return(NA_character_)
    }
    
    as.character(lubridate::parse_date_time(
      as.character(x),
      orders = c("ymd", "dmy")
    ))
  }, ""))
  df$Einreichung <- as.Date(df$Einreichung, format = "%Y-%m-%d")
  
  df$Deadline <- as.Date(vapply(df$Deadline, function(x) {
    if (is.null(x) || length(x) == 0 || identical(x, "keine")) {
      return(NA_character_)
    }
    
    as.character(lubridate::parse_date_time(
      as.character(x),
      orders = c("ymd", "dmy")
    ))
  }, ""))
  df$Deadline <- as.Date(df$Deadline, format = "%Y-%m-%d")
  
  df$`Letzter Kontakt` <- as.Date(vapply(df$`Letzter Kontakt`, function(x) {
    if (is.null(x) || length(x) == 0 || identical(x, "keine")) {
      return(NA_character_)
    }
    
    as.character(lubridate::parse_date_time(
      as.character(x),
      orders = c("ymd", "dmy")
    ))
  }, ""))
  df$`Letzter Kontakt` <- as.Date(df$`Letzter Kontakt`, format = "%Y-%m-%d")
  
  df <- df |> 
    dplyr::mutate(
      "Start" = ifelse(is.null(Start), NULL, as.character(Start)),
      "Befristung" = ifelse(is.null(Befristung), NULL, as.character(Befristung)))
  
  # replace character
  df$Arbeitsort <- gsub("ß", "ss", df$Arbeitsort, fixed = TRUE)
  df$Arbeitsort <- gsub("ä", "ae", df$Arbeitsort, fixed = TRUE)
  df$Arbeitsort <- gsub("ö", "oe", df$Arbeitsort, fixed = TRUE)
  df$Arbeitsort <- gsub("ü", "ue", df$Arbeitsort, fixed = TRUE)

  return(df)
}
