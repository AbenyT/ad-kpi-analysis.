-- 00_load.sql
-- Load the raw Kaggle CSV into DuckDB as table "ads".
-- The file uses old Mac line endings (\r), so the newline is set explicitly.
-- Columns keep their original names and types here; cleaning happens in 02_clean.sql.

CREATE OR REPLACE TABLE ads AS
SELECT *
FROM read_csv(
    'data/KAG_conversion_data.csv',
    header   = true,
    delim    = ',',
    new_line = '\r'
);

-- Confirm the load: expect 1,143 rows and 11 columns
SELECT
    (SELECT COUNT(*) FROM ads)                                         AS row_count,
    (SELECT COUNT(*) FROM information_schema.columns
      WHERE table_name = 'ads')                                        AS column_count;

-- Preview the first 5 rows
SELECT * FROM ads LIMIT 5;
