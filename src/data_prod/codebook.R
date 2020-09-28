

###########################################################
#                     Code Book 123d                      #
###########################################################

library(dataMaid)
library(readr)


# ------ Needs lots of work ------

site_tbl <- read_csv("./123d_analysis_2020/data/123d_2020_site.csv")





#-----------------------------------------------------------
# Add Label and short description attributes to the datasets
#-----------------------------------------------------------

# Site data

attr(site_tbl$site_id, "label") <- "Primary key"
attr(site_tbl$project_code, "shortDescription") <- "UCREFRP Project short code"
attr(site_tbl$year, "shortDescription") <- "Year collected"
attr(site_tbl$river, "shortDescription") <- "NHD river name"
attr(site_tbl$reach, "shortDescription") <- "UDWR Moab reach name"
attr(site_tbl$pass, "shortDescription") <- "Sequential number of pass with respect to this project"

attr(site_tbl$startdatetime, "shortDescription") <- "Time at which sampling began"
attr(site_tbl$startdatetime, "label") <- "YYYY-MM-DD HH:MM:SS"

attr(site_tbl$enddatetime, "shortDescription") <- "Time at which sampling ended"
attr(site_tbl$enddatetime, "label") <- "YYYY-MM-DD HH:MM:SS"

attr(site_tbl$start_rmi, "shortDescription") <- "River mile at which sampling began (distance from confluence). Corrected Belknap Miles estimated to the nearest 1/10 of a mile"
attr(site_tbl$start_rmi, "label") <- "miles"

attr(site_tbl$end_rmi, "shortDescription") <- "River mile at which sampling ended (distance from confluence). Corrected Belknap Miles estimated to the nearest 1/10 of a mile"
attr(site_tbl$end_rmi, "label") <- "miles"

attr(site_tbl$shoreline, "shortDescription") <- "Side of river sampling occurred: B - both, R - right, L - left"

attr(site_tbl$el_sec, "shortDescription") <- "Sampling effort"
attr(site_tbl$el_sec, "label") <- "seconds"

attr(site_tbl$boat, "shortDescription") <- "Name of boat used during sampling"
attr(site_tbl$crew, "shortDescription") <- "Initials of crewmembers"
attr(site_tbl$site_notes, "shortDescription") <- "Information related to site data"

attr(site_tbl$cond_amb, "shortDescription") <- "Ambient conductivity"
attr(site_tbl$cond_amb, "label") <- "microSiemens/cm"

attr(site_tbl$cond_spec, "shortDescription") <- "Specific conductivity"
attr(site_tbl$cond_spec, "label") <- "microSiemens/cm"

attr(site_tbl$rvr_temp, "shortDescription") <- "Water temperature (main channel)"
attr(site_tbl$rvr_temp, "label") <- "degrees Celsius"

attr(site_tbl$secchi, "shortDescription") <- "Visibility to depth (main channel)"
attr(site_tbl$secchi, "label") <- "milimeters"

attr(site_tbl$water_notes, "shortDescription") <- "Information related to water data"
attr(site_tbl$principal, "shortDescription") <- "Principal investigator for the project"
attr(site_tbl$agency, "shortDescription") <- "Agency affiliation of the principal investigator and project"
attr(site_tbl$gear_type, "shortDescription") <- "Gear used in sampling: pulsed DC electrofisher"

attr(site_tbl$last_modified, "shortDescription") <- "Date of codebook and .csv creation"
attr(site_tbl$last_modified, "label") <- "YYYY-MM-DD HH:MM:SS"


# Fish data











#----------------------------------------------------------------
# Codebooks for Site and Fish tables

makeCodebook(site_tbl,
             output = "html",
             reportTitle = paste0("Project 123d - Walleye removal, ",
                                  yoi,
                                  ", Site table (123d_2020_site.csv)"),

             file = paste0("./data/codebook/123d_",
                           yoi,
                           "_site.Rmd"))

makeCodebook(fish_tbl,
             output = "html",
             reportTitle = paste0("Project 123d - Walleye removal, ",
                                  yoi,
                                  ", Site table (123d_2020_fish.csv)"),
             file = paste0("./data/codebook/123d_",
                           yoi,
                           "_fish.Rmd"))

#-------------------------------------------------------------------
