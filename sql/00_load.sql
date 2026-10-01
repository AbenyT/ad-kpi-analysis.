-- 00_load.sql
-- Load the raw Kaggle CSV into MySQL as table "ads".
-- Column names are kept exactly as in the CSV; renaming and type fixes happen in 02_clean.sql.
-- Spent is stored as DOUBLE so no precision is lost at load time.

DROP TABLE IF EXISTS ads;

CREATE TABLE ads (
    ad_id               INT,
    xyz_campaign_id     INT,
    fb_campaign_id      INT,
    age                 VARCHAR(10),
    gender              VARCHAR(10),
    interest            INT,
    Impressions         INT,
    Clicks              INT,
    Spent               DOUBLE,
    Total_Conversion    INT,
    Approved_Conversion INT
);

-- The file uses old Mac line endings (\r), so the line terminator is set explicitly.
-- The path is relative to the project root (run_sql.py runs from there).
LOAD DATA LOCAL INFILE 'data/KAG_conversion_data.csv'
INTO TABLE ads
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\r'
IGNORE 1 LINES;

-- Confirm the load: expect 1,143 rows and 11 columns
SELECT
    (SELECT COUNT(*) FROM ads) AS row_count,
    (SELECT COUNT(*) FROM information_schema.columns
      WHERE table_schema = DATABASE() AND table_name = 'ads') AS column_count;

-- Load warnings would mean bad values were silently converted; expect 0
SHOW COUNT(*) WARNINGS;

-- Preview the first 5 rows
SELECT * FROM ads LIMIT 5;
