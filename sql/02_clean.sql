-- 02_clean.sql
-- Build "ads_clean" from the raw "ads" table:
--   * snake_case, self-explanatory column names
--   * exact money type for spend (DECIMAL, rounded to cents; removes float noise like 1.429999948)
--   * NOT NULL, primary key and CHECK rules that encode the checks from 01_data_check.sql
-- All 1,143 rows are kept. Zero-click ads have zero spend but still bring
-- (view-through) conversions, so dropping them would understate results.

DROP TABLE IF EXISTS ads_clean;

CREATE TABLE ads_clean (
    ad_id               INT           NOT NULL,
    campaign_id         INT           NOT NULL,  -- was xyz_campaign_id (the advertiser's campaign)
    fb_campaign_id      INT           NOT NULL,  -- Facebook's ad set id
    age_group           VARCHAR(5)    NOT NULL,  -- '30-34', '35-39', '40-44', '45-49'
    gender              CHAR(1)       NOT NULL,  -- 'F' or 'M'
    interest_id         SMALLINT      NOT NULL,  -- Facebook interest category code
    impressions         INT           NOT NULL,
    clicks              INT           NOT NULL,
    spent               DECIMAL(10,2) NOT NULL,  -- USD
    total_conversion    INT           NOT NULL,  -- all conversions (e.g. enquiries)
    approved_conversion INT           NOT NULL,  -- conversions the advertiser approved (e.g. purchases)
    PRIMARY KEY (ad_id),
    CONSTRAINT chk_non_negative CHECK (impressions >= 0 AND clicks >= 0 AND spent >= 0
                                       AND total_conversion >= 0 AND approved_conversion >= 0),
    CONSTRAINT chk_clicks       CHECK (clicks <= impressions),
    CONSTRAINT chk_conversions  CHECK (approved_conversion <= total_conversion),
    CONSTRAINT chk_gender       CHECK (gender IN ('F', 'M'))
);

INSERT INTO ads_clean
SELECT
    ad_id,
    xyz_campaign_id,
    fb_campaign_id,
    TRIM(age),
    UPPER(TRIM(gender)),
    interest,
    Impressions,
    Clicks,
    ROUND(Spent, 2),
    Total_Conversion,
    Approved_Conversion
FROM ads;

-- Check 1: nothing lost or changed. Raw and clean must match on rows and every total.
SELECT 'raw ads'   AS source, COUNT(*) AS row_count, SUM(Impressions) AS impressions, SUM(Clicks) AS clicks,
       ROUND(SUM(Spent), 2) AS spent, SUM(Total_Conversion) AS total_conv, SUM(Approved_Conversion) AS approved_conv
FROM ads
UNION ALL
SELECT 'ads_clean', COUNT(*), SUM(impressions), SUM(clicks),
       SUM(spent), SUM(total_conversion), SUM(approved_conversion)
FROM ads_clean;

-- Check 2: final column names and types
SELECT column_name, column_type, is_nullable, column_key
FROM information_schema.columns
WHERE table_schema = DATABASE() AND table_name = 'ads_clean'
ORDER BY ordinal_position;

-- Check 3: preview
SELECT * FROM ads_clean ORDER BY ad_id LIMIT 5;
