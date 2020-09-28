# Extraction Transformation and Loading for Electrofishing Project

## About

The ETL process is divided into 2 parts (scripts).  The first extracts raw data
from .dbf files, runs transformations and QC routines and saves flagged data to
google sheets for interactive QC.  The second script simply loads proofed dataset
into an existing database. This document explains all modifications performed on
the data during this post processing phase.

## STEP 1. `et_qc_123d_YYYY`

*ln 11 - 25*: attaches dependencies and sources QC functions from a local script

* **Required user input**
  * *ln 35*: Project code
  * *ln 38*: Data ID - an intuitive name for the data (ie. Deso1)
  * *ln 41*: Directory name - name of the local directory containing raw data
  * *ln 44*: Year data collected - defaults to present Year
  * *ln 48*: Database name - name of the target Database (Google Drive)
  * *ln 51*: database path - include all parent directories and add trailing `/`
  * *ln 55*: email address for google authentication

*ln 64 - 80*: Authenticates to Google Drive and downloads database to temporary
directory (will recycle at close of session)

*ln 87-94*: Fetches last site_id and increments by 1

*ln 106 - 113*: Create metadata record associated with this dataset. Double check values
are correct (year, first and last name)

*ln 121 - 123*: Extracts raw data from .dbf, converts all column names to lower case.
The user can modify the file path to grab all or only part of the data. Output is
a large list.

*ln 133 - 160*: Binds all like named list elements into a data.frame.

  * Removes any categorical entries containing `Z`
  * Converts all numeric values = 0 to `NA` (0's are impossible)
  * Removes inapproperiate values from `ray_ct`
  * Removes records from pittag table that do not contain a pittag number
  * Removes records from floytag table that do not contain a floytag number

*ln 171 - 203*: Site table modify data types, create variables

  * Create `startdatetime` and `enddatetime` from date and time fields (95,96)
  * Create `el_sec` from `effort_min` and `effort_sec` (97)
  * Add project affiliation (98)
  * Create `year` from `startdatetime` (99)
  * Arrange from oldest to newest `startdatetime` (101)
  * Create `s_index` and `site_id` (103-106)
  * Add `rvr_code` variable (join on reach code) (110)
  * Belknap rmi correction (+120) to `start_rmi` and `end_rmi` for deso and echo
  (112,113)
  * Selects requisite vars for the site table (115 - 123)
  * Create site mini table to attach `site_id` to other tables (126)

*ln 208 - 215*: Water quality table

  * Append `site_id` to table (131)
  * Rename `key_ab` = `water_id` (132)
  * Arrange by `startdatetime` (134)
  * Selects requisite vars for the water_qual table (135 - 138)

*ln 219 - 264*: Fish table

  * Append site_id to table (142)
  * Create `datetime` from date and time variables (143)
  * Arrange by `datetime` (144)
  * Create `f_index` (for QC routines) (145)
  * Belknap rmi correction (+120) to `rmi` for deso and echo (146, 147)
  * Select requisite variables (148 - 157)
  * Convert lon-lat to UTMs (159 - 174)
