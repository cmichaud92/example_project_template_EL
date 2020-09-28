
#######################################
#         UCRBtools package           #
#######################################

# I hastily built this package to provide easy sharing of a couple
# useful funtions (dbf_io, reach, life_stage) and useful datasets
# for mapping full river and reach names to their abbreviations as
# well as and common and scientific names to species codes

# UCRBtools is not on cran so `install.packages("UCRBtools")` will not work
# You will need to install from github and need devtools() to do it

# See if you have devtools installed and install it if not

require(devtools)

install_github("cmichaud92/UCRBtools")

# You only need to do this once and you will need
# this package for all database ETL scripts
