# Electrofishing Projects Data Management Template - 2020

This document introduces the workflow intended to streamline the data management
process for *electrofishing* projects.  The programs contained herein will handle
the processing and storage of data collected using the current DataPlus
Electrofishing Application (EF_v7).

The most up-to-date code is available on
[GitHub](https://github.com/cmichaud92/d_mgt_EF_v7). Click on the `code`
button and select `Download Zip`). Feel free to contact me with questions.  
If you discover bugs in the code or have suggestions: please open an issue
on github.


## Database

`"./src/db_build/EF_V7_sqlite_db.Rmd"`:

  * This file will create a SQLite database and deploy it to the `"./data/database"`
  directory.
    * Default database name: "test_data.sqlite" you can change this.
  * It will also create an html file detailing the database schema and views.

## Data ETL

If you intend to proof data following each pass, create sub-directories for each
pass, otherwise you may store all data in a single directory.

## File Description

### Extract, transform and QC
  * `"./src/etl/et_qc.R"` (extract, transform & QC script).
    * Imports the data from raw .dbf files
    * Creates row for `meta` table (modify to suit)
    * Modifies vars to correct data-types for database storage
    * Creates temporary qc "FLAG" columns to assist in error identification
    * Creates `proof_*.csv` files for each data table and exports to `"./data/proofed_csv"`

### Load to database
  * `"./src/etl/l_data_upload.R"` (loading script)
    * Imports formatted and cleaned data
    * Appends data to your SQLite database
      * **Note** The loading process can be completed only once for a particular
      dataset as, the database has `UNIQUE` constraints on certain fields.

### Export to STReaMS format
  * `"./src/fmt_export/EF_V7_STReaMS_fmt.R"`
    * Pulls data from STReaMS views (see below), transforms data and exports to correctly formatted and data-typed .xlsx file (ready to email)

## Views

The 123d project database includes 3 Views (*virtual* tables)

  * STReaMS_site: roughly equivalent to the STReaMS site-effort table
  * STReaMS_rare: roughly equivalent to the STReaMS rare table
  * STReaMS_ntf: roughly equivalent to the STReaMS nontagged fish table


## Database access

The easiest way to access data stored in SQLite is to use [DB Browser](https://sqlitebrowser.org/dl/).
Once the application is installed you can view the data in a more familiar excel-like
tabular format. This is very similar to the MS Access GUI. You may update
and delete data interactively and easily export to .csv.  

You may also access data through Program R using the BDI, dplyr and dbplyr packages.
Let me know if the access is of interest and I'll share some code.

Finally, data may be accessed using [SQLite Studio](https://sqlitestudio.pl/). This is a minimal SQL scripting GUI.



## Issues

If you discover bugs in the code or have suggestions to make this process easier
please open an issue on github or email me. :neckbeard:
