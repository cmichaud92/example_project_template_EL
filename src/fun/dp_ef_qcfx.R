
################################################################
#           DataPlus EF application QAQC functions             #
################################################################

library(tidyverse)
library(lubridate)

# These functions create "flag" cols based on the given criteria.  Then return only rows containing a flag

#--------------------
# Site table QC
#--------------------
site_qcfx <- function(site_data) {
  site_data %>% 
  mutate(rmi_flg = ifelse(start_rmi - end_rmi > 5, "FLAG", ""),
         datetime_flg = ifelse(as.numeric(enddatetime - startdatetime) * 60  < el_sec, "FLAG", ""),
         el_sec_flg = ifelse(el_sec > 7200 | el_sec < 1000, "FLAG", ""),
         NA_flg = ifelse(apply(select(., s_index:crew), 1, function(x){any(is.na(x))}), "FLAG", "")) %>% 
         filter_at(vars(ends_with("flg")), any_vars(. == "FLAG"))
}

#-------------------
# Fish table QC
#-------------------
fish_qcfx <- function(fish_data, site_data) { 
  
  native <- c("CS", "RZ", "HB", "BT", "FM", "BH", "RT", "SD", "CH")
  com_spp <- c("CS", "RZ", "HB", "BT", "SD", "FM", "BH", "RT", "SM", "BC",
               "LG", "BG", "GS", "GC", "BB", "YB", "WE", "GZ", "NP", "WS", "CH")
  site_data %>% 
    select(s_index, site_id, key_a) %>% 
    full_join(fish_data) %>% 
    mutate(orphan_flg = ifelse(is.na(s_index), "FLAG", ""),
           zero_catch_flg = ifelse(is.na(fish_id), "FLAG", ""),
           species_flg = ifelse(species %!in% com_spp, "FLAG", ""),
           tot_length_flg = ifelse(species %!in% c("CC", "GC", "NP") & tot_length > 1000, "FLAG", ""),
           weight_flg = ifelse(species %!in% c("CC", "GC", "NP") & weight > 2800, "FLAG", ""),
           disp_flg = ifelse(disp == "DE" & species %in% native |
                               disp == "RA" & species %!in% native, "FLAG", "")) %>% 
    filter_at(vars(ends_with("flg")), any_vars(. == "FLAG"))
}

#--------------------
# Pittag table QC
#--------------------
pit_qcfx <- function(pit_data, fish_data) {
  fish_data %>% 
    select(f_index, fish_id, species) %>% 
    full_join(pit_data) %>% 
    mutate(orphan_flg = ifelse(is.na(f_index), "FLAG", ""),
           nnf_flg = ifelse(pit_recap == "NNF", "FLAG", ""),
           pit_recap_flg = ifelse(is.na(pit_recap) & !is.na(pit_num) |
                                    is.na(pit_num) & !is.na(pit_recap), "FLAG", ""),
           invalid_pitnum_flg = case_when(pit_type == 134 & str_length(pit_num) != 14 ~ "FLAG",
                                          pit_type == 400 & str_length(pit_num) != 9 ~ "FLAG") )%>% 
    filter_at(vars(ends_with("flg")), any_vars(. == "FLAG"))
}

# ck2 <- site_qcfx(site_qc)
# 
# # Subset dataframe based on flag cols == TRUE and assess errors
# ck_site <- site_qctmp %>% 
#   filter_at(vars(ends_with("flg")), any_vars(. == "FLAG"))
# 
# ck_fish <- fish_qctmp %>% 
#   filter_at(vars(ends_with("flg")), any_vars(. == "FLAG"))
# 
# ck_pit <- pit_qctmp %>% 
#   filter_at(vars(ends_with("flg")), any_vars(. == "FLAG"))
