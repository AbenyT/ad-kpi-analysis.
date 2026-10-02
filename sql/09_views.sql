-- 09_views.sql
-- Final KPI views for the dashboard. Every view reads from ads_clean.
--
-- Two kinds of view:
--   * v_ads           : one row per ad with readable labels and additive measures.
--                       Charts that must follow dashboard filters (campaign, age, gender)
--                       compute KPIs from it as SUM(...) / SUM(...).
--   * v_kpi_*         : pre-calculated KPIs, one per analysis in 03-08.
--
-- KPI rules (same as 03-08): ratios of totals, NULLIF guards, approved conversions for CPA.
-- Text labels built in SQL (campaign, gender, segment) get an explicit collation.
-- Without it MySQL gives them the collation of the connection that created the view, and
-- Metabase filters fail with "Illegal mix of collations".

-- 1. Row-level base view with labels
CREATE OR REPLACE VIEW v_ads AS
SELECT
    ad_id,
    campaign_id,
    CONVERT(CONCAT('Campaign ', campaign_id) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci AS campaign,
    fb_campaign_id,
    age_group,
    CONVERT(CASE gender WHEN 'F' THEN 'Female' WHEN 'M' THEN 'Male' END USING utf8mb4) COLLATE utf8mb4_0900_ai_ci AS gender,
    interest_id,
    impressions,
    clicks,
    spent,
    total_conversion,
    approved_conversion
FROM ads_clean;

-- 2. Account-level KPIs (one row)
CREATE OR REPLACE VIEW v_kpi_overall AS
SELECT
    COUNT(*)                                                                    AS ads,
    SUM(impressions)                                                            AS impressions,
    SUM(clicks)                                                                 AS clicks,
    SUM(spent)                                                                  AS spent_usd,
    SUM(total_conversion)                                                       AS total_conv,
    SUM(approved_conversion)                                                    AS approved_conv,
    ROUND(100.0 * SUM(clicks)              / NULLIF(SUM(impressions), 0), 4)    AS ctr_pct,
    ROUND(        SUM(spent)               / NULLIF(SUM(clicks), 0), 2)         AS cpc_usd,
    ROUND(1000  * SUM(spent)               / NULLIF(SUM(impressions), 0), 2)    AS cpm_usd,
    ROUND(        SUM(spent)               / NULLIF(SUM(approved_conversion), 0), 2) AS cpa_usd,
    ROUND(100.0 * SUM(approved_conversion) / NULLIF(SUM(clicks), 0), 2)         AS conv_rate_pct,
    ROUND(        SUM(spent)               / NULLIF(SUM(total_conversion), 0), 2) AS cpa_total_usd,
    ROUND(100.0 * SUM(approved_conversion) / NULLIF(SUM(total_conversion), 0), 2) AS approval_rate_pct
FROM ads_clean;

-- 3. KPIs per campaign
CREATE OR REPLACE VIEW v_kpi_campaign AS
SELECT
    campaign_id,
    CONVERT(CONCAT('Campaign ', campaign_id) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci         AS campaign,
    COUNT(*)                                                                    AS ads,
    SUM(impressions)                                                            AS impressions,
    SUM(clicks)                                                                 AS clicks,
    SUM(spent)                                                                  AS spent_usd,
    SUM(approved_conversion)                                                    AS approved_conv,
    ROUND(100.0 * SUM(clicks)              / NULLIF(SUM(impressions), 0), 4)    AS ctr_pct,
    ROUND(        SUM(spent)               / NULLIF(SUM(clicks), 0), 2)         AS cpc_usd,
    ROUND(1000  * SUM(spent)               / NULLIF(SUM(impressions), 0), 2)    AS cpm_usd,
    ROUND(        SUM(spent)               / NULLIF(SUM(approved_conversion), 0), 2) AS cpa_usd,
    ROUND(100.0 * SUM(approved_conversion) / NULLIF(SUM(clicks), 0), 2)         AS conv_rate_pct,
    ROUND(100.0 * SUM(approved_conversion) / NULLIF(SUM(total_conversion), 0), 2) AS approval_rate_pct,
    ROUND(100.0 * SUM(spent)               / SUM(SUM(spent)) OVER (), 2)        AS spend_share_pct,
    ROUND(100.0 * SUM(approved_conversion) / SUM(SUM(approved_conversion)) OVER (), 2) AS conv_share_pct
FROM ads_clean
GROUP BY campaign_id;

-- 4. KPIs per age group
CREATE OR REPLACE VIEW v_kpi_age AS
SELECT
    age_group,
    COUNT(*)                                                                    AS ads,
    SUM(impressions)                                                            AS impressions,
    SUM(clicks)                                                                 AS clicks,
    SUM(spent)                                                                  AS spent_usd,
    SUM(approved_conversion)                                                    AS approved_conv,
    ROUND(100.0 * SUM(clicks)              / NULLIF(SUM(impressions), 0), 4)    AS ctr_pct,
    ROUND(        SUM(spent)               / NULLIF(SUM(clicks), 0), 2)         AS cpc_usd,
    ROUND(1000  * SUM(spent)               / NULLIF(SUM(impressions), 0), 2)    AS cpm_usd,
    ROUND(        SUM(spent)               / NULLIF(SUM(approved_conversion), 0), 2) AS cpa_usd,
    ROUND(100.0 * SUM(approved_conversion) / NULLIF(SUM(clicks), 0), 2)         AS conv_rate_pct,
    ROUND(100.0 * SUM(approved_conversion) / NULLIF(SUM(total_conversion), 0), 2) AS approval_rate_pct,
    ROUND(100.0 * SUM(spent)               / SUM(SUM(spent)) OVER (), 2)        AS spend_share_pct,
    ROUND(100.0 * SUM(approved_conversion) / SUM(SUM(approved_conversion)) OVER (), 2) AS conv_share_pct
FROM ads_clean
GROUP BY age_group;

-- 5. KPIs per gender
CREATE OR REPLACE VIEW v_kpi_gender AS
SELECT
    CONVERT(CASE gender WHEN 'F' THEN 'Female' WHEN 'M' THEN 'Male' END USING utf8mb4) COLLATE utf8mb4_0900_ai_ci AS gender,
    COUNT(*)                                                                    AS ads,
    SUM(impressions)                                                            AS impressions,
    SUM(clicks)                                                                 AS clicks,
    SUM(spent)                                                                  AS spent_usd,
    SUM(approved_conversion)                                                    AS approved_conv,
    ROUND(100.0 * SUM(clicks)              / NULLIF(SUM(impressions), 0), 4)    AS ctr_pct,
    ROUND(        SUM(spent)               / NULLIF(SUM(clicks), 0), 2)         AS cpc_usd,
    ROUND(1000  * SUM(spent)               / NULLIF(SUM(impressions), 0), 2)    AS cpm_usd,
    ROUND(        SUM(spent)               / NULLIF(SUM(approved_conversion), 0), 2) AS cpa_usd,
    ROUND(100.0 * SUM(approved_conversion) / NULLIF(SUM(clicks), 0), 2)         AS conv_rate_pct,
    ROUND(100.0 * SUM(approved_conversion) / NULLIF(SUM(total_conversion), 0), 2) AS approval_rate_pct,
    ROUND(100.0 * SUM(spent)               / SUM(SUM(spent)) OVER (), 2)        AS spend_share_pct,
    ROUND(100.0 * SUM(approved_conversion) / SUM(SUM(approved_conversion)) OVER (), 2) AS conv_share_pct
FROM ads_clean
GROUP BY gender;

-- 6. KPIs per interest: all 40 interests, eligible = spend >= 10 x account CPA (rule from 07),
--    cpa_rank = 1 for the cheapest eligible interest, NULL for interests that are not ranked.
CREATE OR REPLACE VIEW v_kpi_interest AS
WITH account AS (
    SELECT SUM(spent) / NULLIF(SUM(approved_conversion), 0) AS account_cpa
    FROM ads_clean
),
per_interest AS (
    SELECT
        interest_id,
        COUNT(*)                                                                 AS ads,
        SUM(impressions)                                                         AS impressions,
        SUM(clicks)                                                              AS clicks,
        SUM(spent)                                                               AS spent_usd,
        SUM(approved_conversion)                                                 AS approved_conv,
        ROUND(100.0 * SUM(clicks)              / NULLIF(SUM(impressions), 0), 4) AS ctr_pct,
        ROUND(        SUM(spent)               / NULLIF(SUM(clicks), 0), 2)      AS cpc_usd,
        ROUND(1000  * SUM(spent)               / NULLIF(SUM(impressions), 0), 2) AS cpm_usd,
        SUM(spent) / NULLIF(SUM(approved_conversion), 0)                         AS cpa_exact,
        ROUND(100.0 * SUM(approved_conversion) / NULLIF(SUM(clicks), 0), 2)      AS conv_rate_pct
    FROM ads_clean
    GROUP BY interest_id
),
flagged AS (
    SELECT p.*,
           CASE WHEN p.spent_usd >= 10 * a.account_cpa THEN 1 ELSE 0 END         AS is_eligible,
           ROUND(100.0 * p.cpa_exact / a.account_cpa, 0)                         AS cpa_index
    FROM per_interest p
    CROSS JOIN account a
)
SELECT
    interest_id, ads, impressions, clicks, spent_usd, approved_conv,
    ctr_pct, cpc_usd, cpm_usd,
    ROUND(cpa_exact, 2)                                                          AS cpa_usd,
    conv_rate_pct, cpa_index,
    CASE WHEN is_eligible = 1 THEN 'yes' ELSE 'no' END                           AS eligible,
    CASE WHEN is_eligible = 1
         THEN ROW_NUMBER() OVER (PARTITION BY is_eligible
                                 ORDER BY CASE WHEN cpa_exact IS NULL THEN 1 ELSE 0 END, cpa_exact)
    END                                                                          AS cpa_rank
FROM flagged;

-- 7. KPIs per campaign x age x gender: all 24 segments, eligible = >= 10 approved conversions (rule from 08)
CREATE OR REPLACE VIEW v_kpi_segment AS
WITH account AS (
    SELECT SUM(spent) / NULLIF(SUM(approved_conversion), 0) AS account_cpa,
           SUM(spent)                                       AS account_spent
    FROM ads_clean
),
segments AS (
    SELECT
        campaign_id,
        age_group,
        gender,
        COUNT(*)                                                                 AS ads,
        SUM(impressions)                                                         AS impressions,
        SUM(clicks)                                                              AS clicks,
        SUM(spent)                                                               AS spent_usd,
        SUM(approved_conversion)                                                 AS approved_conv,
        SUM(CASE WHEN clicks = 0 THEN approved_conversion ELSE 0 END)            AS free_approved_conv,
        ROUND(100.0 * SUM(clicks)              / NULLIF(SUM(impressions), 0), 4) AS ctr_pct,
        ROUND(        SUM(spent)               / NULLIF(SUM(clicks), 0), 2)      AS cpc_usd,
        SUM(spent) / NULLIF(SUM(approved_conversion), 0)                         AS cpa_exact,
        ROUND(100.0 * SUM(approved_conversion) / NULLIF(SUM(clicks), 0), 2)      AS conv_rate_pct
    FROM ads_clean
    GROUP BY campaign_id, age_group, gender
),
flagged AS (
    SELECT s.*,
           CASE WHEN s.approved_conv >= 10 THEN 1 ELSE 0 END                     AS is_eligible,
           ROUND(100.0 * s.spent_usd / a.account_spent, 2)                       AS spend_share_pct,
           ROUND(100.0 * s.cpa_exact / a.account_cpa, 0)                         AS cpa_index
    FROM segments s
    CROSS JOIN account a
)
SELECT
    CONVERT(CONCAT('Campaign ', campaign_id, ' | ', age_group, ' | ',
           CASE gender WHEN 'F' THEN 'Female' WHEN 'M' THEN 'Male' END) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci AS segment,
    campaign_id,
    age_group,
    CONVERT(CASE gender WHEN 'F' THEN 'Female' WHEN 'M' THEN 'Male' END USING utf8mb4) COLLATE utf8mb4_0900_ai_ci AS gender,
    ads, impressions, clicks, spent_usd, spend_share_pct, approved_conv, free_approved_conv,
    ctr_pct, cpc_usd,
    ROUND(cpa_exact, 2)                                                          AS cpa_usd,
    conv_rate_pct, cpa_index,
    CASE WHEN is_eligible = 1 THEN 'yes' ELSE 'no' END                           AS eligible,
    CASE WHEN is_eligible = 1
         THEN ROW_NUMBER() OVER (PARTITION BY is_eligible ORDER BY cpa_exact)
    END                                                                          AS cpa_rank
FROM flagged;

-- Check 1: list the views
SELECT table_name AS view_name
FROM information_schema.views
WHERE table_schema = DATABASE()
ORDER BY table_name;

-- Check 2: every view must add up to the account totals ($58,705.23 spend, 1,079 approved conversions)
SELECT 'v_ads'          AS view_name, COUNT(*) AS view_rows, SUM(spent)     AS spent_usd, SUM(approved_conversion) AS approved_conv FROM v_ads
UNION ALL SELECT 'v_kpi_overall',  COUNT(*), SUM(spent_usd), SUM(approved_conv) FROM v_kpi_overall
UNION ALL SELECT 'v_kpi_campaign', COUNT(*), SUM(spent_usd), SUM(approved_conv) FROM v_kpi_campaign
UNION ALL SELECT 'v_kpi_age',      COUNT(*), SUM(spent_usd), SUM(approved_conv) FROM v_kpi_age
UNION ALL SELECT 'v_kpi_gender',   COUNT(*), SUM(spent_usd), SUM(approved_conv) FROM v_kpi_gender
UNION ALL SELECT 'v_kpi_interest', COUNT(*), SUM(spent_usd), SUM(approved_conv) FROM v_kpi_interest
UNION ALL SELECT 'v_kpi_segment',  COUNT(*), SUM(spent_usd), SUM(approved_conv) FROM v_kpi_segment;

-- Check 3: spot-check KPIs against earlier results
SELECT 'overall CPA (03): 54.41'           AS expected, cpa_usd AS actual FROM v_kpi_overall
UNION ALL SELECT 'campaign 1178 CPA (04): 63.83', cpa_usd FROM v_kpi_campaign WHERE campaign_id = 1178
UNION ALL SELECT 'age 45-49 CPA (05): 99.76',     cpa_usd FROM v_kpi_age      WHERE age_group = '45-49'
UNION ALL SELECT 'Male CPA (06): 41.44',          cpa_usd FROM v_kpi_gender   WHERE gender = 'Male'
UNION ALL SELECT 'interest rank 1 = 101 (07)',    interest_id FROM v_kpi_interest WHERE cpa_rank = 1
UNION ALL SELECT 'eligible interests (07): 26',   COUNT(*) FROM v_kpi_interest WHERE eligible = 'yes'
UNION ALL SELECT 'worst segment CPA (08): 137.76', MAX(cpa_usd) FROM v_kpi_segment WHERE eligible = 'yes'
UNION ALL SELECT 'eligible segments (08): 16',    COUNT(*) FROM v_kpi_segment WHERE eligible = 'yes';
