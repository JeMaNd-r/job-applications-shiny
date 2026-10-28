# load environmental variables
library(dotenv)
dotenv::load_dot_env(file = ".env")

# read environmental variables from .env
has_access_permission <- Sys.getenv("HAS_ACCESS_PERMISSION")
own_data_file <- Sys.getenv("OWN_DATA_FILE")
