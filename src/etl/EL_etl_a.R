
##############################################################
#                         EFproj ETL                         #
##############################################################


#-------------------------------
# Attach packages
#-------------------------------

library(tidyverse)
library(lubridate)
library(sf)
library(googlesheets4)
library(googledrive)
library(UCRBtools)
library(DBI)

# source functions
source("./src/fun/dp_ef_qcfx_csv.R")

# build "exclude"
`%!in%` <- Negate(`%in%`)

config <- config::get(value = "example_config",
                      file = "T:/My Drive/data_mgt/projects/config.yml")

#------------------------
# Required variables
#------------------------

# Data set name: Use the directory name to create data identifier
 data_id <- "2020_example_1"

# data_id <- "example_1"

# Name of directory containing target dataset (local)
# dir_name <- "dbf_123a_1/"
# dir_name <- paste0(data_id, "/")

# Data year (should be current year)
 data_yr <- year(now())


#-------------------------------
# Google Drive auth and io
#-------------------------------

# -----Authenticate to google drive-----

drive_auth(email = config$email)

gs4_auth(token = drive_token())


#------------------------------
# Fetch starting site_id
# from the database
#------------------------------

# ----- Connect to database -----

con <-  dbConnect(RSQLite::SQLite(), paste0(config$root_path, config$db_name))
dbListTables(con)


#----- Scrape 'max' site_id  from db and increment by 1 ------

# Adds 1 to the last sample number currently in the database
#start_num <- 1

start_num <- 1 +
  (tbl(con, "site") %>%
  pull(site_id) %>%
  max() %>%
  str_sub(start = -3) %>%
  as.integer())

dbDisconnect(con)

#-------------------------------
# Import field data (dbf) from local source
#-------------------------------

# This creates a large list, each dbf table is a separate list element

data <- dbf_io(file_path_in = paste0(config$dbf_path, data_id)) %>%
  map(rename_all, tolower) %>%
  compact()


#-------------------------------
# Create row for meta table
#-------------------------------

# Add project_code and principal!!!!!
# This is only required for the first data set each year

meta <- tibble(
  project_code = config$proj,
  year = data_yr,
  principal_fname = config$pi_fname,
  principal_lname = config$pi_lname,
  agency = config$agency,
  data_type = config$data_type
)


#------------------------------
# Extract data from list
#------------------------------

# Combine like tables and...
# Remove "Z" and complete easy qc

# Site data
site_tmp <- map_df(data[grepl("site", names(data))], bind_rows) %>%
  mutate_all(na_if, "Z")                                                # Converts "Z"s to NA

# Water data
water_tmp <- map_df(data[grepl("water", names(data))], bind_rows) %>%
  mutate_at(c("cond_amb", "cond_spec", "rvr_temp", "secchi"),
            function(x) {ifelse(x == 0, NA, x)}) %>%                    # Converts 0's to NA
  mutate_all(na_if, "Z")                                                # Converts "Z"s to NA

# Fish data
fish_tmp <- map_df(data[grepl("fish", names(data))], bind_rows) %>%
  mutate_at(c("ilat", "ilon", "tot_length", "st_length", "weight"),     # Converts 0's to NA
            function(x) {ifelse(x == 0, NA, x)}) %>%
  mutate_all(na_if, "Z") %>%                                            # Converts "Z"s to NA
  mutate(ray_ct = na_if(ray_ct, "N"),
         tubercles = ifelse(species %in% spp_nat, tubercles, NA),        # Cleans up additional vars
         rep_cond = toupper(rep_cond))

# Pittag
pit_tmp <- map_df(data[grepl("pittag", names(data))], bind_rows) %>%
  filter(!is.na(pit_num)) %>%
  mutate_all(na_if, "Z")                                                # Converts "Z"s to NA

# Floytag
floy_tmp <- map_df(data[grepl("floytag", names(data))], bind_rows) %>%
  filter(!is.na(floy_num)) %>%
  mutate_all(na_if, "Z") %>%
  select(-floy_id)

# Vial
vial_tmp <- map_df(data[grepl("vial", names(data))], bind_rows) %>%
  mutate_all(na_if, "Z")

#------------------------------
# Modify data
#------------------------------

# Create sample_number and index,
# Create fnl table structures

# Site table

site <- site_tmp %>%
  mutate(startdatetime = as.POSIXct(paste(mdy(date), starttime)),         # Replace `date` and `time` with `datetime`
         enddatetime = as.POSIXct(paste(mdy(date), endtime)),
         el_sec = effort_sec + (effort_min * 60),                         # Convert effort to seconds
         project = tolower(project),
         year = year(startdatetime)) %>%                                  # Add year varaible

  arrange(startdatetime) %>%                                              # this orders data for indexing

  mutate(s_index = row_number(),                                          # add index for qc/site_id
         site_num_crct = s_index + (start_num - 1),
         site_id = paste(project,
                         year(startdatetime),                    # Create sample number
                         str_pad(site_num_crct, 3, "left", "0"),
                         sep = "_")) %>%

  left_join(tbl_reach, by = c("reach" = "rch_code")) %>%                   # Add rvr_code variable

  select(s_index, site_id, project,
         year, river = rvr_code,
         reach, pass,
         startdatetime, enddatetime,
         start_rmi, end_rmi,
         shoreline, el_sec,
         boat, crew,
         site_notes, key_a) %>%

  mutate_at(vars(ends_with("rmi")), function(x) {ifelse(.$reach %in% c("DESO", "ECHO"),  # Simple Belknap correction
                                                        x + 120, x)})



samp_n <- select(site, key_a, site_id, t_stamp = startdatetime, reach)       # Create site_id df and apply to all tables.


# Water_qual table

water <- left_join(water_tmp, samp_n, by = "key_a") %>%
  rename(water_id = key_ab,
         water_notes = h2o_notes) %>%
  arrange(t_stamp) %>%
  select(water_id, site_id,
         cond_amb, cond_spec,
         rvr_temp, secchi,
         water_notes, key_a)

# Fish table

fish_1 <- left_join(fish_tmp, samp_n, by = "key_a") %>%
  mutate(datetime = as.POSIXct(paste(as.Date(t_stamp), time))) %>%
  arrange(datetime) %>%
  mutate(f_index = row_number()) %>%
  mutate_at(vars(ends_with("rmi")), function(x) {ifelse(.$reach %in% c("DESO", "ECHO"),
                                                        x + 120, x)}) %>%
  select(f_index,
         fish_id = key_aa,
         site_id, reach,
         rmi, datetime,
         species, tot_length,
         weight, sex,
         rep_cond, tubercles,
         ray_ct, disp,
         fish_notes, key_a,
         ilon, ilat)

fish_sf <- fish_1 %>%                                     # Convert long-lat to UTMs
  group_by(site_id, rmi) %>%
  summarise(ilon = mean(ilon, na.rm = TRUE),
            ilat = mean(ilat, na.rm = TRUE),
            .groups = "drop") %>%
  filter(!is.na(ilon)) %>%
  st_as_sf(coords = c("ilon", "ilat"), crs = 4326) %>%
  st_transform(crs = 32612) %>%
  mutate(loc_x = st_coordinates(geometry)[, 1],
         loc_y = st_coordinates(geometry)[, 2],
         epsg = 32612) %>%
  st_drop_geometry() %>%
  select(site_id, rmi, loc_x, loc_y, epsg)

fish <- full_join(fish_1, fish_sf, by = c("site_id", "rmi")) %>%
  select(-c(ilat, ilon))

# Pittag table

pittag <- left_join(pit_tmp, samp_n, by = "key_a") %>%
  rename(pit_id = key_aaa,
         fish_id = key_aa) %>%
  left_join(select(fish, fish_id, datetime, species), by = c("fish_id")) %>%
  arrange(datetime) %>%
  mutate(p_index = row_number(),
         pit_num = toupper(pit_num)) %>%
  select(p_index, pit_id, fish_id, site_id,
         species,pit_type, pit_num, pit_recap,
         pit_notes, key_a)

# Floytag table

floytag <- left_join(floy_tmp, samp_n, by = "key_a") %>%
  rename(floy_id = key_aab,
         fish_id = key_aa) %>%
  left_join(select(fish, fish_id, datetime, species), by = c("fish_id")) %>%
  arrange(datetime) %>%
  mutate(fl_index = row_number()) %>%
  select(fl_index, floy_id, fish_id, site_id,
         species, floy_color, floy_num, floy_recap,
         floy_notes)

#------------------------------
# QC data.tables
#------------------------------
ck_site <- site_qcfx(site_data = site) %>%
  mutate_if(is.POSIXct, force_tz, tzone = "UTC")


ck_fish <- fish_qcfx(fish_data = fish, site_data = site) %>%
  mutate_if(is.POSIXct, force_tz, tzone = "UTC")

ck_pit <- pit_qcfx(pit_data = pittag, fish_data = fish)

ck_floy <- floy_qcfx(floy_data = floytag, fish_data = fish)

ck_stat <- stats_qcfx(site_data = site, fish_data = fish, spp = c("SM"))

ck_vial <- vial_tmp

#------------------------------
# Upload data to google drive
#------------------------------

gs4_create(
  name = paste(data_id, "raw", sep = "_"),
  sheets = list(meta = meta,
                stats = ck_stat,
                ck_site = ck_site,
                ck_fish = ck_fish,
                ck_pit = ck_pit,
#                ck_floy = ck_floy,
#                ck_vial = ck_vial,
                water = water)
  )

# Create a directory on google drive to store project specific data and move file
# This moves data to 'project_template_test/' in google drive. Otherwise sheets is
# created in the google drive root directory

drive_mv(paste(data_id, "raw", sep = "_"),
         path = gsub("^.*?Drive/","",config$root_path))

## End
