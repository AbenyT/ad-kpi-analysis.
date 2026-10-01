-- 06_kpis_gender.sql
-- KPIs per gender. Same rules as 03_overall_kpis.sql:
-- ratios of totals, NULLIF guards, approved conversions for CPA and conversion rate.

-- 1. Volume and KPIs per gender. WITH ROLLUP adds a Total row that must match the account totals.
SELECT
    IF(GROUPING(gender), 'Total', gender)                                       AS gender,
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
    ROUND(100.0 * SUM(approved_conversion) / NULLIF(SUM(total_conversion), 0), 2) AS approval_rate_pct
FROM ads_clean
GROUP BY gender WITH ROLLUP;

-- 2. Budget efficiency: share of spend vs share of approved conversions, and CPA index (100 = account average)
SELECT
    gender,
    ROUND(100.0 * SUM(spent)               / SUM(SUM(spent))               OVER (), 2) AS spend_share_pct,
    ROUND(100.0 * SUM(approved_conversion) / SUM(SUM(approved_conversion)) OVER (), 2) AS conv_share_pct,
    ROUND(100.0 * (SUM(spent) / NULLIF(SUM(approved_conversion), 0))
                / (SUM(SUM(spent)) OVER () / NULLIF(SUM(SUM(approved_conversion)) OVER (), 0)), 0) AS cpa_index
FROM ads_clean
GROUP BY gender
ORDER BY gender;

-- 3. Consistency check: female vs male CPA within each campaign and within each age group.
--    f_to_m_cpa_ratio > 1 means a female conversion costs more than a male one in that slice.
WITH slices AS (
    SELECT CONCAT('campaign ', campaign_id) AS slice, gender, spent, approved_conversion FROM ads_clean
    UNION ALL
    SELECT CONCAT('age ', age_group),               gender, spent, approved_conversion FROM ads_clean
)
SELECT
    slice,
    ROUND(SUM(CASE WHEN gender = 'F' THEN spent END)
        / NULLIF(SUM(CASE WHEN gender = 'F' THEN approved_conversion END), 0), 2) AS cpa_female_usd,
    ROUND(SUM(CASE WHEN gender = 'M' THEN spent END)
        / NULLIF(SUM(CASE WHEN gender = 'M' THEN approved_conversion END), 0), 2) AS cpa_male_usd,
    ROUND((SUM(CASE WHEN gender = 'F' THEN spent END)
             / NULLIF(SUM(CASE WHEN gender = 'F' THEN approved_conversion END), 0))
        / NULLIF(SUM(CASE WHEN gender = 'M' THEN spent END)
             / NULLIF(SUM(CASE WHEN gender = 'M' THEN approved_conversion END), 0), 0), 2) AS f_to_m_cpa_ratio,
    SUM(CASE WHEN gender = 'F' THEN approved_conversion END)                      AS conv_female,
    SUM(CASE WHEN gender = 'M' THEN approved_conversion END)                      AS conv_male
FROM slices
GROUP BY slice
ORDER BY slice;
