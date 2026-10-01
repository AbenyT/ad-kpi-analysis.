-- 05_kpis_age.sql
-- KPIs per age group. Same rules as 03_overall_kpis.sql:
-- ratios of totals, NULLIF guards, approved conversions for CPA and conversion rate.

-- 1. Volume and KPIs per age group. WITH ROLLUP adds a Total row that must match the account totals.
SELECT
    IF(GROUPING(age_group), 'Total', age_group)                                 AS age_group,
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
GROUP BY age_group WITH ROLLUP;

-- 2. Budget efficiency: share of spend vs share of approved conversions, and CPA index (100 = account average)
SELECT
    age_group,
    ROUND(100.0 * SUM(spent)               / SUM(SUM(spent))               OVER (), 2) AS spend_share_pct,
    ROUND(100.0 * SUM(approved_conversion) / SUM(SUM(approved_conversion)) OVER (), 2) AS conv_share_pct,
    ROUND(100.0 * (SUM(spent) / NULLIF(SUM(approved_conversion), 0))
                / (SUM(SUM(spent)) OVER () / NULLIF(SUM(SUM(approved_conversion)) OVER (), 0)), 0) AS cpa_index
FROM ads_clean
GROUP BY age_group
ORDER BY age_group;

-- 3. Consistency check: CPA by age inside each campaign.
--    Campaign 1178 is ~95% of spend, so the overall age pattern could just reflect it.
--    If the same pattern appears within each campaign, it is a real age effect.
SELECT
    age_group,
    ROUND(SUM(CASE WHEN campaign_id = 916  THEN spent END)
        / NULLIF(SUM(CASE WHEN campaign_id = 916  THEN approved_conversion END), 0), 2) AS cpa_916_usd,
    ROUND(SUM(CASE WHEN campaign_id = 936  THEN spent END)
        / NULLIF(SUM(CASE WHEN campaign_id = 936  THEN approved_conversion END), 0), 2) AS cpa_936_usd,
    ROUND(SUM(CASE WHEN campaign_id = 1178 THEN spent END)
        / NULLIF(SUM(CASE WHEN campaign_id = 1178 THEN approved_conversion END), 0), 2) AS cpa_1178_usd,
    SUM(CASE WHEN campaign_id = 916 THEN approved_conversion END)                   AS conv_916
FROM ads_clean
GROUP BY age_group
ORDER BY age_group;
