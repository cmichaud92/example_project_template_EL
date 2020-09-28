
#-------------------------------
# Import field data (dbf) from local source
#-------------------------------

library(foreign)
library(purrr)
library(dplyr)

# ----- Define dbf_io -----

# Generalized function intended to import .dbf files from a DataPlus application.
# Function then returns a list of named tibbles (data frames)
# If compiling multiple efforts, need to grepl resulting list for tibble name
# as there may be multiple identically named tibbles in the output list

dbf_io <- function(file_path_in) {

    files <- list.files(path = file_path_in, pattern = '.dbf$', full.names = TRUE)

    dat_name <- list()

    dat_name <- as.list(stringr::str_extract(files, "(?<=\\+).*(?=\\.dbf)")) # Creates list-element names from file names


    data <- purrr::map(files, foreign::read.dbf, as.is = TRUE) # Read all dbf files, strings as characters (as.is)

    names(data) <- dat_name                                    # Set list-element names

    data <- purrr::map(data, tibble::as_tibble)                        # Converts df to tibbles

    data <- purrr::compact(data)                               # Removes all empty list elements

    data
}


# ----- Import data -----

# Specify path to data
dat_path <- "./data/dbf_123a_1"
# This creates a large list, each dbf table is a separate list element

data <- dbf_io(file_path_in = dat_path) %>%
    map(rename_all, tolower) %>%
    compact()

#------------------------------
# Extract data from list
#------------------------------

# Combine like tables: grepl based on table(dbf names)

# Site data
site_tmp <- map_df(data[grepl("site", names(data))], bind_rows)

# Water data
water_tmp <- map_df(data[grepl("water", names(data))], bind_rows)

# Fish data
fish_tmp <- map_df(data[grepl("fish", names(data))], bind_rows)

# Pittag
pit_tmp <- map_df(data[grepl("pittag", names(data))], bind_rows)

# Floytag
floy_tmp <- map_df(data[grepl("floytag", names(data))], bind_rows)

