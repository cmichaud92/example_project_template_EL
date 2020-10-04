
###################################################################
#                      EF_V7  Database loading                    #
###################################################################

library(tidyverse)
library(lubridate)
library(fs)
library(DBI)
library(googledrive)
library(googlesheets4)


#-------------------------------
# Enter user defined variables
#-------------------------------

# Name of google sheets document containing PROOFED data to upload
# proof_data <- "Exact file name as it appears in Google drive"

data_id <- "2020_example_3"

proof_data <- paste(data_id, "final",  sep = "_")
raw_data <- paste(data_id, "raw", sep = "_")

#-------------------------------
# Fetch config
#-------------------------------
 config <- config::get(value = "example_config",
                       file = "T:/My Drive/data_mgt/projects/config.yml")

#-------------------------------
# Google Drive auth and io
#-------------------------------

# -----Authenticate to google drive-----

drive_auth(email = config$email)

gs4_auth(token = drive_token())


# -----Locate proofed dataset-----

# If sets returns more than 1 observation LOOK carefully
# Google drive allows multiple identical file names!!!!!

sets <- drive_get(proof_data)


#-----Connect to database-----


con <-  dbConnect(RSQLite::SQLite(), paste0(config$root_path, config$db_name))
dbListTables(con)

# dbDisconnect(con)
#------------------------------
# Upload ID
#------------------------------

# For initial upload
# u_id <- 1

# For all additional uploads
# Fetch last upload_id value (max()) from the database increment +1
u_id <- 1 + (
  tbl(con, "site") %>%
  pull(upload_id) %>%
  max()
  )


#dbDisconnect(con)


#---------------------------
# Final data mods
#---------------------------

# Import data
site_tmp <- read_sheet(sets, range = "ck_site") %>%
  mutate_if(is.POSIXct, as.character) %>%
  rename(project_code = project) %>%
  mutate(upload_id = u_id)


fish_tmp <- read_sheet(sets, range = "ck_fish")%>%
  mutate_if(is.POSIXct, as.character)

pit_tmp <- read_sheet(sets, range = "ck_pit") %>%
  mutate_at("pit_type", as.character)

floy_tmp <- read_sheet(sets, range = "ck_floy")

water_tmp <- read_sheet(sets, range = "water")

meta <- read_sheet(sets, range = "meta")

#--------------------------------
# Remove index columns
#--------------------------------

site <- select(site_tmp, -c(matches("_flg$|_index$|^key_")))
fish <- select(fish_tmp, -c(matches("_flg$|_index$|^key_"), reach)) %>%
  filter(!is.na(fish_id))
pit <- select(pit_tmp, -c(species, matches("_flg$|_index$|^key_|^site")))

floy <- select(floy_tmp, -c(species, matches("_flg$|_index$|^key_|^site")))

water <- water_tmp %>%
  select(-key_a)



# Upload tables
dbWriteTable(con, name = "meta", value = meta, append = TRUE)

dbWriteTable(con, name = "site", value = site, append = TRUE)

dbWriteTable(con, name = "water_qual", value = water, append = TRUE)

dbWriteTable(con, name = "fish", value = fish, append = TRUE)

dbWriteTable(con, name = "pittag", value = pit, append = TRUE)

dbWriteTable(con, name = "floytag", value = floy, append = TRUE)


# Disconnect
dbDisconnect(con)


# Create backup database and copy to archive
file.copy(from = paste0(config$root_path, config$db_name),
          to = paste0(config$arch_path, "database/",format(as.Date(Sys.Date()), "%Y%m%d"),
                      "_", "uid-", u_id, "_", config$db_name),
          overwrite = TRUE)

# Move QC googlesheets to to archive
file_move(path = paste0(config$root_path, raw_data, ".gsheet"),
          new_path = paste0(config$arch_path, "data_qaqc/",
                            raw_data, ".gsheet"))

file_move(path = paste0(config$root_path, proof_data, ".gsheet"),
          new_path = paste0(config$arch_path, "data_qaqc/",
                            proof_data, ".gsheet"))


## End
