
#####################################################################
#              Analysis data query from STReaMS                     #
#####################################################################


library(tidyverse)
library(dbplyr)
library(lubridate)
library(DBI)
library(UCRBtools)


#-------------------------------------
# User defined variables
#-------------------------------------

# Year of interest
yoi <- 2019

# Project(s) of interest
poi <- "123d"


#-------------------------------------
# Fetch data
#-------------------------------------

# Must be logged into CSU via pulse secure

# All sensitive information is stored in config.yml file "datawarehouse"
dw <- config::get("datawarehouse")

# Establish connection
con <- dbConnect(odbc::odbc(),
                 Driver = dw$driver,
                 Server = dw$server,
                 UID    = dw$uid,
                 PWD    = dw$pwd,
                 Port   = dw$port,
                 Database = dw$database
)

# dbDisconnect(con)

#------------------------------------------------
# Create pointers to requisite data
#------------------------------------------------

# Ancillary tables
#study_p <- tbl(con, "TBL_StudyEvent") %>% collect
person_p <- tbl(con, "TBL_Person") %>%
  select(PersonID = ID,
         FirstName, LastName)

study_p <- tbl(con, "TBL_Study") %>%
  select(StudyID = ID,
         StudyCode = Code,
         StudyName = Name)

gear_p <- tbl(con, "LKU_GearType") %>%
  select(GearTypeID = ID,
         GearCode = Code)

org_p <- tbl(con, "TBL_Org") %>%
  select(OrgID = ID,
         OrgName = Name)

rvr_p <- tbl(con, "LKU_HydroArea") %>%
  select(RiverID = ID,
         rvr_code = Code,
         rvr_name = Name,
         BasinID)

spp_p <- tbl(con, "LKU_Species") %>%
  rename(SpeciesID = ID,
         SpeciesCode = Code)

indiv_p <- tbl(con, "TBL_Individual") %>%
  rename(IndividualID = ID)

enc_p <- tbl(con, "TBL_Encounter") %>%
  rename(EncounterID = ID,
         EncounterNotes = Notes)

tag_p <- tbl(con, "TBL_Tag") %>%
  rename(TagID = ID,
         TagTypeID = TagType) %>%
  left_join(rename(tbl(con, "D_TagType"),
                   TagTypeID = ID), by = "TagTypeID")

disp_p <- tbl(con, "LKU_DispositionType") %>%
  rename(DispositionTypeID = ID,
         DispositionTypeCode = Code)

sex_p <- tbl(con, "D_Sex") %>%
  select(Sex = ID,
         SexCode = Code)
# Site-effort data
site_p <- tbl(con, "TBL_StudyEvent") %>%
  rename(StudyEventID = ID) %>%
  filter(year(StartDateTime) == yoi) %>%
  left_join(study_p, by = "StudyID") %>%
  left_join(gear_p, by = "GearTypeID") %>%
  left_join(org_p, by = "OrgID") %>%
  left_join(rvr_p, by = "RiverID") %>%
  left_join(person_p, by = "PersonID") %>%
  filter(StudyCode == poi)

# Nontagged fish bin
ntf_p <- tbl(con, "BIN_NonTaggedFish") %>%
  semi_join(site_p, by = "SampleNumber") %>%
  inner_join(spp_p, by = c("Species" = "spp_code"))

# Rare-fish

rare_p <- left_join(enc_p, indiv_p, by = "IndividualID") %>%
  semi_join(site_p, by = "SampleNumber") %>%
  left_join(tag_p, by = "IndividualID") %>%
  left_join(spp_p, by = "SpeciesID") %>%
  left_join(disp_p, by = "DispositionTypeID") %>%
  left_join(sex_p, by = "Sex")





#---------------------------------------------
# Import subset data
#---------------------------------------------

# Site table ------------------------------------
site_str <- site_p %>%
  collect()%>%
  rename_all(tolower) %>%
  mutate(year = year(startdatetime),
         mid_rmi = round(startrmi + endrmi) / 2, 1,
         cond_spec = NA,
         water_notes = NA,
         principal = paste(lastname, firstname, sep = ", "),
         agency = sub("[a-z]+", "", orgname),
         last_modified = now()) %>%
  reach(RiverCode = .$rvr_code, rmi = .$mid_rmi) %>%
  inner_join(tbl_reach, by = c("reach" = "rch_code", "rvr_code")) %>%

  select(
    site_id = samplenumber,
    project_code = studycode,
    year, rvr_name, rch_name,
    rvr_code,
    rch_code = reach,
    pass,
    startdatetime,
    enddatetime,
    start_rmi = startrmi,
    end_rmi = endrmi,
    el_sec = electrofishingseconds,
    shoreline, boat, crew,
    site_notes = notes,
    cond_amb = conductivity,
    cond_spec,
    rvr_temp = rivertemperature,
    secchi = turbidity,
    water_notes, principal, agency,
    gear = gearcode,
    last_modified
    )

# Nontagged fish table --------------------------------
ntf_str <- ntf_p %>%
  collect() %>%
  rename_all(tolower) %>%
  mutate(tubercles = NA,
         ray_ct = NA,
         epsg = ifelse(!is.na(utmx), 32612, NA)) %>%
  select(site_id = samplenumber,
         datetime,
         rmi = rivermile,
         spp_code = species,
         com_name, sci_name,
         tot_length = length,
         weight, sex, ripe,
         tubercles, ray_ct,
         disp_code = dispositiontype,
         loc_x = utmx,
         loc_y = utmy,
         epsg,
         floy_num_1 = floytag1,
         floy_color_1 = floytag1color,
         floy_recap_1 = recap1,
         floy_num_2 = floytag2,
         floy_color_2 = floytag2color,
         floy_recap_2 = recap2,
         fish_notes = notes
         )


# Rare fish table -------------------------------------
rare_str <- rare_p %>%
  collect() %>%
  rename_all(tolower) %>%
  mutate(epsg = ifelse(!is.na(utmx), 32612, NA),
         pit_notes = NA) %>%
  select(
    site_id = samplenumber,
    datetime = encounterdatetime,
    rmi = rivermile,
    spp_code = speciescode,
    com_name = commonname,
    sci_name = scientificname,
    tot_length = length,
    weight,
    sex = sexcode,
    ripe = ripeflag,
    tubercles =tuberclesflag,
    ray_ct = raycount,
    disp_code = dispositiontypecode,
    loc_x = utmx,
    loc_y = utmy,
    epsg,
    fish_notes = encounternotes,
    pit_recap = recapture,
    pit_num = tagcode,
    pit_type = tagtype

  )

fish <- bind_rows(rare_str, ntf_str)%>%
  mutate_at(c("floy_recap_1", "floy_recap_2"), function(x) ifelse(x == 0, NA, x)) %>%
  mutate(pit_recap = ifelse(is.na(pit_recap), FALSE, pit_recap))


dbDisconnect(con)

write_csv(site_str, "./123d_2019_site_STR.csv")
write_csv(fish, "./123d_2019_fish_STR.csv")
