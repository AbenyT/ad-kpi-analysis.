-- 01_data_check.sql
-- Data quality checks on the raw "ads" table before any KPI is calculated.

-- 1. Row count and unique ads (expect 1,143 and 1,143)
SELECT
    COUNT(*)              AS row_count,
    COUNT(DISTINCT ad_id) AS unique_ad_ids
FROM ads;

-- 2. Column names and types
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = DATABASE() AND table_name = 'ads'
ORDER BY ordinal_position;

-- 3. Nulls per column (COUNT(col) skips NULLs, so COUNT(*) - COUNT(col) = nulls)
SELECT
    COUNT(*) - COUNT(ad_id)               AS null_ad_id,
    COUNT(*) - COUNT(xyz_campaign_id)     AS null_campaign,
    COUNT(*) - COUNT(fb_campaign_id)      AS null_fb_campaign,
    COUNT(*) - COUNT(age)                 AS null_age,
    COUNT(*) - COUNT(gender)              AS null_gender,
    COUNT(*) - COUNT(interest)            AS null_interest,
    COUNT(*) - COUNT(Impressions)         AS null_impressions,
    COUNT(*) - COUNT(Clicks)              AS null_clicks,
    COUNT(*) - COUNT(Spent)               AS null_spent,
    COUNT(*) - COUNT(Total_Conversion)    AS null_total_conv,
    COUNT(*) - COUNT(Approved_Conversion) AS null_approved_conv
FROM ads;

-- 4. Duplicate ad_id (expect no rows)
SELECT ad_id, COUNT(*) AS times_seen
FROM ads
GROUP BY ad_id
HAVING COUNT(*) > 1;

-- 5. Rows with zero values in the KPI inputs
SELECT
    SUM(Impressions = 0)         AS zero_impressions,
    SUM(Clicks = 0)              AS zero_clicks,
    SUM(Spent = 0)               AS zero_spent,
    SUM(Total_Conversion = 0)    AS zero_total_conv,
    SUM(Approved_Conversion = 0) AS zero_approved_conv
FROM ads;

-- 6. Logic checks: values that contradict each other (expect 0 except the last one)
SELECT
    SUM(Clicks > Impressions)                         AS clicks_gt_impressions,
    SUM(Approved_Conversion > Total_Conversion)       AS approved_gt_total,
    SUM(Impressions < 0 OR Clicks < 0 OR Spent < 0
        OR Total_Conversion < 0 OR Approved_Conversion < 0) AS negative_values,
    SUM(Clicks = 0 AND Spent > 0)                     AS spent_without_clicks,
    SUM(Clicks > 0 AND Spent = 0)                     AS clicks_without_spent,
    SUM(Clicks = 0 AND Total_Conversion > 0)          AS conversions_without_clicks
FROM ads;

-- 6b. How much do the zero-click ads matter? Share of rows, spend and conversions.
SELECT
    SUM(Clicks = 0)                                                   AS zero_click_ads,
    ROUND(100 * SUM(Clicks = 0) / COUNT(*), 1)                        AS pct_of_ads,
    ROUND(100 * SUM(CASE WHEN Clicks = 0 THEN Spent END)
              / NULLIF(SUM(Spent), 0), 2)                             AS pct_of_spend,
    ROUND(100 * SUM(CASE WHEN Clicks = 0 THEN Approved_Conversion END)
              / NULLIF(SUM(Approved_Conversion), 0), 1)               AS pct_of_approved_conv
FROM ads;

-- 7. Category values: are labels clean and consistent?
SELECT 'age' AS field, age AS value, COUNT(*) AS ads FROM ads GROUP BY age
UNION ALL
SELECT 'gender', gender, COUNT(*) FROM ads GROUP BY gender
UNION ALL
SELECT 'campaign', CAST(xyz_campaign_id AS CHAR), COUNT(*) FROM ads GROUP BY xyz_campaign_id
UNION ALL
SELECT 'interest (distinct)', CAST(COUNT(DISTINCT interest) AS CHAR), COUNT(*) FROM ads
ORDER BY field, value;
