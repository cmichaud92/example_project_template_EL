---
title: "SQLite db build: Data Management Example"
date: "27 September, 2020"
output:
  html_document:
    keep_md: true
---





```sql
PRAGMA foreign_keys = ON
```

# Determine verison


```sql
select sqlite_version();
```


<div class="knitsql-table">


Table: 1 records

|sqlite_version() |
|:----------------|
|3.31.1           |

</div>

# Build tables

This program will create a database in the project root directory.  If the database and tables already exist in this directory, it will throw an error and exit.  Will not overwrite an existing table. This rmd produces both .html and .md outputs, these are useful for documentation of database schema.

### Meta-Table

This table includes metadata required by STReaMS and Heritage data submissions


```sql
CREATE TABLE meta (
meta_id INTEGER NOT NULL UNIQUE PRIMARY KEY,
project_code TEXT NOT NULL,
`year` INTEGER NOT NULL UNIQUE,
principal_fname TEXT NOT NULL,                      
principal_lname TEXT NOT NULL,
agency TEXT NOT NULL CHECK (agency IN ('UDWR-M', 'UDWR-V', 'CSU', 'FWS-GJ', 'FWS-V')),
data_type TEXT NOT NULL CHECK (data_type IN ('EL', 'SE', 'TR', 'ANT', 'OT'))
);
```


```sql

CREATE UNIQUE INDEX idx_meta_site ON meta (project_code, `year`);

```


```sql
PRAGMA index_list('meta');
```


<div class="knitsql-table">


Table: 3 records

|seq |name                    | unique|origin | partial|
|:---|:-----------------------|------:|:------|-------:|
|0   |idx_meta_site           |      1|c      |       0|
|1   |sqlite_autoindex_meta_2 |      1|u      |       0|
|2   |sqlite_autoindex_meta_1 |      1|u      |       0|

</div>


```sql

PRAGMA index_info('idx_meta_site');
```


<div class="knitsql-table">


Table: 2 records

|seqno | cid|name         |
|:-----|---:|:------------|
|0     |   1|project_code |
|1     |   2|year         |

</div>

### Site-Table


```sql
CREATE TABLE site (
site_id TEXT NOT NULL UNIQUE PRIMARY KEY,
project_code TEXT NOT NULL,
year INTEGER NOT NULL,
river TEXT NOT NULL CHECK (river IN ('CO', 'GR', 'SJ', 'LP', 'DO', 'PR', 'SR', 'OT')),
reach TEXT NOT NULL CHECK (reach IN ('LGR', 'LCO', 'WW', 'DESO', 'LDO', 'MGR', 'ECHO','MATH', 'USJ', 'MSJ', 'LSJ', 'LPCO', 'LPSJ', 'LSR', 'LPR', 'OT')),
pass INTEGER,
start_rmi REAL NOT NULL,
end_rmi REAL NOT NULL,
startdatetime TEXT NOT NULL,
enddatetime TEXT NOT NULL,
shoreline TEXT NOT NULL CHECK (shoreline IN ('R', 'L', 'B', 'OT', 'UNK')),
el_sec INTEGER NOT NULL CHECK (el_sec != 0),
boat TEXT,
crew TEXT,
site_notes TEXT,
upload_id INTEGER NOT NULL,
FOREIGN KEY (project_code, year) REFERENCES meta(project_code, year)
);
```


```r
# dbListFields(con, "site")
```



```r
# db_drop_table(con, "site")
```

### Water Quality-Table


```sql
CREATE TABLE water_qual (
water_id TEXT NOT NULL UNIQUE PRIMARY KEY,
site_id TEXT NOT NULL,
cond_amb INTEGER,
cond_spec INTEGER,
rvr_temp DECIMAL (4, 1),
secchi INTEGER,
water_notes TEXT,
FOREIGN KEY (site_id) REFERENCES site(site_id)
);

```

### Fish-Table


```sql
CREATE TABLE fish (
fish_id TEXT NOT NULL UNIQUE PRIMARY KEY,
site_id TEXT NOT NULL, 
datetime TEXT,
rmi REAL NOT NULL,
species TEXT NOT NULL CHECK (species IN ('BB', 'BC', 'BCT', 'BEAV', 'BFL', 'BFW', 'BG', 'BGGS', 'BH', 'BHLS', 'BHRZ', 'BHWS', 'BK', 'BLW', 'BM', 'BN', 'BR', 'BS', 'BT', 'BU', 'CC', 'CH', 'CHBT', 'CHHB', 'CHRT', 'CP', 'CR', 'CRCT', 'CS', 'CT', 'FB', 'FH', 'FM', 'FMLS', 'FR', 'GA', 'GC', 'GD', 'GS', 'GZ', 'HB', 'ID', 'IN', 'KO', 'KOI', 'LD', 'LG', 'LK', 'LM', 'LS', 'LSWS', 'MF', 'MS', 'MT', 'NP', 'PK', 'RB', 'RC', 'RD', 'RH', 'RS', 'RT', 'RTBT', 'RZ', 'RZWS', 'SB', 'SD', 'SM', 'SP', 'SS', 'SU', 'TM', 'TS', 'UC', 'UI', 'UM', 'WB', 'WC', 'WE', 'WF', 'WS', 'YB', 'YP')),
tot_length INTEGER CHECK (tot_length != 0), 
weight INTEGER CHECK (weight != 0),
sex TEXT CHECK (sex IN ('F', 'M', 'I', NULL)),
rep_cond TEXT CHECK (rep_cond IN ('EXP_EGG', 'EXP_MILT', 'INT_EGG', 'INT_MILT', 'SPENT', 'NOT', NULL)),
tubercles TEXT CHECK (tubercles IN ('Y', 'N', NULL)),
ray_ct TEXT,
disp TEXT NOT NULL CHECK (disp IN ('CT', 'DE', 'RT', 'FC', 'HA', 'DF', 'SS', 'DP', 'RA', 'TR', 'TL', 'UNK', 'OT')),
loc_x REAL CHECK (loc_x != 0),
loc_y REAL CHECK (loc_y != 0),
epsg INTEGER,
fish_notes TEXT,
FOREIGN KEY(site_id) REFERENCES site(site_id)
);

```

### Pittag-Table


```sql
CREATE TABLE pittag (
pit_id TEXT NOT NULL UNIQUE PRIMARY KEY,
fish_id TEXT NOT NULL,
pit_recap TEXT NOT NULL CHECK (pit_recap IN ('Y', 'N', 'NNF', 'UNK')),
pit_num TEXT NOT NULL,
pit_type TEXT NOT NULL CHECK (pit_type IN ('134', '400')),
pit_notes TEXT,
FOREIGN KEY (fish_id) REFERENCES fish(fish_id)
);
```

### Floytag-Table


```sql
CREATE TABLE floytag (
floy_id TEXT NOT NULL UNIQUE PRIMARY KEY,
fish_id TEXT NOT NULL,
floy_num TEXT NOT NULL,
floy_recap TEXT NOT NULL CHECK (floy_recap IN ('Y', 'N', 'UNK')),
floy_color TEXT CHECK(floy_color IN ('PUR', 'BRN', 'WHT', 'RED', 'YEL', 'GRN', 'OR', 'GRY', 'CL', 'OT')),
floy_ref INTEGER,
floy_notes TEXT,
FOREIGN KEY (fish_id) REFERENCES fish(fish_id)
);
```

### Vial-Table


```sql
CREATE TABLE vial (
vial_id TEXT NOT NULL UNIQUE PRIMARY KEY,
fish_id TEXT NOT NULL,
vial_num TEXT,
vial_type TEXT NOT NULL CHECK (vial_type IN ('LF', 'UIF', 'FIN', 'RAY', 'SCA', 'EYE', 'BLD', 'STO', 'GUT', 'OTO', 'MUS', 'OT')),
vial_notes TEXT,
FOREIGN KEY (fish_id) REFERENCES fish(fish_id)
);
```


## Build STReaMS views

These are virtual tables, saved queries which behave like a data.table


### Sample - Site-effort Datasheet


```sql
CREATE VIEW STReaMS_site (
    year,
    AGENCY,
    `PROJECT BIOLOGIST`,    
    PROGRAM,
    RIVER,
    REACH,
    `SAMPLE NUMBER`,
    PASS,
    GEAR,
    STARTRMI,
    ENDRMI,
    STARTDATETIME,
    ENDDATETIME,
    SHORELINE,
    `EL SEC`,
    BOAT,
    CONDUCTIVITY,
    CREW,
    `RIVER TEMP`,
    TURBIDITY
    
) AS
    SELECT
        site.year,
        agency,
        principal_lname || ', ' || principal_fname,
        site.project_code,
        river,
        reach,
        site.site_id,
        pass,
        ('EL') AS gear,
        start_rmi,
        end_rmi,
        startdatetime,
        enddatetime,
        shoreline,
        el_sec,
        boat,
        cond_amb,
        crew,
        rvr_temp,
        secchi
        
        
    FROM site
    LEFT JOIN 
    meta ON (
    site.project_code = meta.project_code AND
    site.year = meta.year
    )
    
    LEFT JOIN
    water_qual ON (
    site.site_id = water_qual.site_id
    )
    
```



### Rare Fish Datasheet


```sql
CREATE VIEW STReaMS_rare (
    pit_type,
    pit_num,
    AGENCY,
    `PROJECT BIOLOGIST`,
    RIVER,
    RMI,
    YEAR,
    `DATE TIME`,
    `SAMPLE NUMBER`,
    SPECIES,
    LENGTH,
    WEIGHT,
    SEX,
    RIPE,
    TUBERCLES,
    RAYS,
    RECAPTURE,
    DISP,
    GEAR,
    epsg,
    `UTM X`,
    `UTM Y`
    
) AS
    SELECT
        pit_type,
        pit_num,
        agency,
        principal_lname || ', ' || principal_fname,
        river,
        rmi,
        site.year,
        datetime,
        site.site_id,
        species,
        tot_length,
        weight,
        sex,
        rep_cond,
        tubercles,
        ray_ct,
        pit_recap,
        disp,
        ('EL') AS gear,
        epsg,
        loc_x,
        loc_y
        

    FROM fish
    LEFT JOIN
    site ON (
    site.site_id = fish.site_id
    )
    
    LEFT JOIN
    meta ON (
    site.year = meta.year
    )
    
    LEFT JOIN
    pittag ON (
    fish.fish_id = pittag.fish_id
    )
    
    WHERE species IN ('CS', 'RZ', 'HB', 'BT') OR pit_num NOT NULL
```


### Non-tagged Fish Datasheet


```sql
CREATE VIEW STReaMS_ntf (
    AGENCY,
    `PROJECT BIOLOGIST`,
    RIVER,
    RMI,
    YEAR,
    `DATE TIME`,
    `SAMPLE NUMBER`,
    SPECIES,
    LENGTH,
    WEIGHT,
    SEX,
    RIPE,
    floy_id,
    floy_num,
    floy_color,
    floy_recap,
    floy_ref,
    DISP,
    GEAR,
    epsg,
    `UTM X`,
    `UTM Y`,
    pit_num
    
) AS
    SELECT 
        agency,
        principal_lname || ', ' || principal_fname,
        river,
        rmi,
        site.year,
        datetime,
        site.site_id,
        species,
        tot_length,
        weight,
        sex,
        rep_cond,
        floy_id,
        floy_num,
        floy_color,
        floy_recap,
        floy_ref,
        disp,
        ('EL') AS gear,
        epsg,
        loc_x,
        loc_y,
        pit_num
  
    FROM fish
    LEFT JOIN
    site ON (
    site.site_id = fish.site_id
    )
    
    LEFT JOIN
    meta ON (
    site.year = meta.year
    )
    
    LEFT JOIN
    floytag ON (
    fish.fish_id = floytag.fish_id
    )
    
    LEFT JOIN
    pittag ON (
    fish.fish_id = pittag.fish_id
    )

    WHERE pittag.pit_num IS NULL AND fish.species NOT IN ('CS', 'RZ', 'HB', 'BT')
```




```r
drive_auth(email = config$email)

drive_upload(media = tmp_db,
             path = config$db_path,
             name = config$db_name)
```

```
## Local file:
##   * C:\Users\cmichaud\AppData\Local\Temp\1\Rtmpq6OseO\file30ac327f30dc.sqlite
## uploaded into Drive file:
##   * example_123a.sqlite: 1yTgcetIr-ALDlLde2CBLf5HFPPEM-aVx
## with MIME type:
##   * application/octet-stream
```

```r
dbDisconnect(con)
```
