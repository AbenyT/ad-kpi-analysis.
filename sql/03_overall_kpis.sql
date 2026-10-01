-- 03_overall_kpis.sql
-- Account-level totals and KPIs for all 1,143 ads.
--
-- Rules used in every KPI file:
--   * KPIs are ratios of totals: SUM(spent) / SUM(clicks), never AVG(spent / clicks).
--   * NULLIF(denominator, 0) turns a division by zero into NULL instead of an error.
--   * CPA and conversion rate use approved_conversion (the conversions the advertiser accepted).
--   * MySQL keeps only 4 extra decimals when dividing, so percentages start from 100.0
--     (one decimal) to keep enough precision before ROUND().

-- 1. Totals
SELECT
    COUNT(*)                 AS ads,
    SUM(impressions)         AS impressions,
    SUM(clicks)              AS clicks,
    SUM(spent)               AS spent_usd,
    SUM(total_conversion)    AS total_conversions,
    SUM(approved_conversion) AS approved_conversions
FROM ads_clean;

-- 2. Core KPIs
SELECT
    ROUND(100.0  * SUM(clicks)              / NULLIF(SUM(impressions), 0), 4) AS ctr_pct,         -- clicks per 100 impressions
    ROUND(         SUM(spent)               / NULLIF(SUM(clicks), 0), 2)      AS cpc_usd,         -- cost per click
    ROUND(1000   * SUM(spent)               / NULLIF(SUM(impressions), 0), 2) AS cpm_usd,         -- cost per 1,000 impressions
    ROUND(         SUM(spent)               / NULLIF(SUM(approved_conversion), 0), 2) AS cpa_usd, -- cost per approved conversion
    ROUND(100.0  * SUM(approved_conversion) / NULLIF(SUM(clicks), 0), 2)      AS conv_rate_pct    -- approved conversions per 100 clicks
FROM ads_clean;

-- 3. Same KPIs on total conversions, plus how many conversions get approved
SELECT
    ROUND(         SUM(spent)               / NULLIF(SUM(total_conversion), 0), 2)  AS cpa_total_usd,
    ROUND(100.0  * SUM(total_conversion)    / NULLIF(SUM(clicks), 0), 2)            AS conv_rate_total_pct,
    ROUND(100.0  * SUM(approved_conversion) / NULLIF(SUM(total_conversion), 0), 2)  AS approval_rate_pct
FROM ads_clean;
