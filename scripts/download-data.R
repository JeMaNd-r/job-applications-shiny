library("googlesheets4")
library("readr")

source("R/process-data.R")


# Download the csv file ones to provide some (fake) data for users.

# load google sheet named "Bewerbungen"
data <- googlesheets4::read_sheet(
  "https://docs.google.com/spreadsheets/d/119YsIeSaDFozVkoYpBXFmIXaAMwz7AY0jtOC3i2wGUE/edit?gid=0#gid=0"
)

# clean data
data_clean <- process_data(data)

# save as csv in data folder
if(!dir.exists("data/")){
  dir.create("data/")
}
readr::write_csv(data_clean, paste0("data/Applications_", Sys.Date(), ".csv"))
