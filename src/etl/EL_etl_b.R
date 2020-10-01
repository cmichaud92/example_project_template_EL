
###################################################################
#                      EF_V7  Database loading                    #
###################################################################

library(tidyverse)
library(lubridate)
library(DBI)
library(googledrive)
library(googlesheets4)


#-------------------------------
# Enter user defined variables
#-------------------------------

# Name of google sheets document containing PROOFED data to upload
# proof_data <- "Exact file name as it appears in Google drive"

# proof_data <- "final_example_1"
 proof_data <- "final_example_1"
# proof_data <- "final_example_3"


#-------------------------------
# Fetch config
#-------------------------------
config <- config::get("example_config")

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


#-----Locate database-----

el_db <- drive_get(paste0(config$db_path, config$db_name))

tmp <- tempfile(fileext = ".sqlite")
drive_download(el_db, path = tmp, overwrite = TRUE)

con <-  dbConnect(RSQLite::SQLite(), tmp)
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


# Archive old database version in googledrive
drive_mv(el_db, path = paste0(config$db_arch,
                              "arch_",
                              format(as.Date(Sys.Date()), "%Y%m%d"),
                              "_",
                              config$db_name))

# Upload the updated database version to googledrive
drive_upload(media = tmp,
             path = config$db_path,
             name = config$db_name)

# Disconnect

dbDisconnect(con)

## End
