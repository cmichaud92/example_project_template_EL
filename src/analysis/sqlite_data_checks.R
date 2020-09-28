
############################################################
#      EL project SQLite database quick stats              #
############################################################

library(dplyr)
library(dbplyr)
library(DBI)
library(lubridate)
library(UCRBtools)
library(googledrive)
library(lubridate)
library(ggplot2)
library(gt)

theme_set(theme_bw())

config <- config::get("example_config")
#----------------------------------------------------
# User defined parameters
#----------------------------------------------------

# Year of interest
yoi <- 2020

#-------------------------------
# Google Drive auth and io
#-------------------------------

# ----- Authenticate to google drive -----

drive_auth(email = config$email)


# ----- Locate database -----

el_db <- drive_get(paste0(config$db_path, config$db_name))

tmp <- tempfile(fileext = ".sqlite")
drive_download(el_db, path = tmp, overwrite = TRUE)


# ----- Connect to database -----

con <-  dbConnect(RSQLite::SQLite(), tmp)
# dbListTables(con)



#-------------------------------------------
# Stats fx:  similar to the one used in `etl_a` script
#            but adds `reach` to grouping

stats_qcfx <- function(site_data, fish_data) {
    f <- fish_data %>%
        filter(species == "SM") %>%
        group_by(site_id) %>%
        summarise(SM = n(),
                  .groups = "drop")
    site_data %>%
        left_join(f, by = "site_id") %>%
        group_by(reach, pass) %>%
        summarise(n_site = n(),
                  effort_hr = round(sum(el_sec) / 3600, 2),
                  SM = sum(SM, na.rm = TRUE),
                  cpue = round(SM / effort_hr, 2),
                  .groups = "drop")
}

site <- tbl(con, "site") %>%
    filter(year == yoi) %>%
    collect()

fish <- tbl(con, "fish") %>%
    inner_join(site, by = "site_id", copy = TRUE) %>%
    collect()

stats_qcfx(site_data = site, fish_data = fish) %>%
    gt()


#---------------------------------
# More indepth data checks

# ----- Meta pointer -----

meta_p <- tbl(con, "meta") %>%
    filter(year %in% yoi) %>%
    mutate(principal = paste(principal_lname,
                             principal_fname,
                             sep = ", ")) %>%
    select(year, project_code, principal, agency, gear_type = data_type)


# -----Site pointer and site table-----

site_p <- tbl(con, "site") %>%
    rename(rvr_code = river,
           rch_code = reach) %>%
    left_join(select(tbl_river, rvr_code, rvr_name),
              by = "rvr_code", copy = TRUE) %>%
    left_join(select(tbl_reach, rch_code, rch_name),
              by = "rch_code", copy = TRUE) %>%
    left_join(tbl(con, "water_qual"), by = "site_id") %>%
    inner_join(meta_p, by = c("project_code", "year")) %>%
    select(-c(water_id))


site_tbl <- site_p %>%
    collect() %>%
    mutate_at(vars(contains("date")), as.POSIXct) %>%
    mutate(last_modified = now())%>%
    select(site_id, project_code, year,
           rvr_name, rch_name,
           everything())

# Checks

site_tbl %>%
    ggplot() +
    geom_histogram(aes(x = start_rmi), color = "black", binwidth = 5) +
    facet_wrap(~rch_code, scales = "free_x")

site_tbl %>%
    ggplot() +
    geom_histogram(aes(x = end_rmi), color = "black", binwidth = 5) +
    facet_wrap(~rch_code, scales = "free_x")

site_tbl %>%
    ggplot() +
    geom_histogram(aes(x = startdatetime), color = "black") +
    facet_wrap(~rch_code, scales = "free_x")


# -----Fish table-----

fish_tbl <- tbl(con, "fish") %>%
    left_join(select(site_p, site_id, rch_code, pass), by = "site_id") %>%
    left_join(tbl(con, "pittag"), by = "fish_id") %>%
    collect() %>%
    mutate_at(vars(contains("date")), as.POSIXct) %>%
    rename(spp_code = species) %>%
    left_join(select(tbl_spp, -nativity), by = "spp_code") %>%
    mutate(ripe = case_when(grepl("^INT+", rep_cond) ~ "N",
                            grepl("^EXP+", rep_cond) ~ "Y")) %>%
    select(fish_id:rmi, rch_code, pass, spp_code, com_name, sci_name, tot_length, weight, sex, ripe, tubercles:pit_notes)

# Checks
fish_tbl %>%
    ggplot() +
    geom_histogram(aes(x = rmi, fill = rch_code), color = "black")

fish_tbl %>%
    filter(!is.na(pit_num)) %>%
    ggplot() +
    geom_bar(aes(x = spp_code), color = "black")

fish_tbl %>%
    filter(spp_code == "SM") %>%
    ggplot() +
    geom_histogram(aes(x = tot_length), color = "black")

fish_tbl %>%
    filter(!is.na(pit_id)) %>%
    select(spp_code, rch_code, datetime, rmi, pit_num, pit_recap, pit_type) %>%
    gt()

# -----Floy table-----

floy_tbl <- tbl(con, "floytag") %>%
    left_join(select(fish_tbl, fish_id, spp_code, rmi, rch_code), by = "fish_id", copy = TRUE) %>%
    collect()

floy_tbl %>%
    gt()





dbDisconnect(con)
