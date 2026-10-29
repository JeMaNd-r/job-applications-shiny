library("googlesheets4")
library("readr")

source("R/process-data.R")

get_data <- function(){
  # Depending on access permission, download data from Google Drive or read CSV file in data folder.
  
  if(own_data_file != ""){
    file_name = paste0("data/", own_data_file)
    try({
      df <- readr::read_csv(file_name)
      print("Data loaded from your own file")
      df <- process_data(df)
      print("Data processed")
      return(df)
    })
  } else {
    
    if(has_access_permission){
        file_name = paste0("data/Applications_", Sys.Date(), ".csv")
        if(file.exists(file_name)){
          df <- readr::read_csv(file_name)
          print("Data loaded from CSV file")
          return(df)
          
        } else {
          try({
            df <- googlesheets4::read_sheet(
              "https://docs.google.com/spreadsheets/d/119YsIeSaDFozVkoYpBXFmIXaAMwz7AY0jtOC3i2wGUE/edit?gid=0#gid=0"
            )
            print("Data loaded from Google Drive")
            df <- process_data(df)
            print("Data processed")
            return(df)
          })
          if(!base::exists("df")){
            files <- list.files("data/", pattern = "Applications_*", full.names = TRUE) |>
              sort(decreasing = TRUE)
            df <- readr::read_csv(files[1])
            print("Data loaded from CSV file")
          }
      }
    }
  }
  
  if(!base::exists("df")){
    df <- readr::read_csv("data/test_data.csv")
    print("Data loaded from test CSV file")
  }
  
  return(df)
}
