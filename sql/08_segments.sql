-- 08_segments.sql
-- Combined segments: campaign x age group x gender (3 x 4 x 2 = 24 segments).
-- Same rules as 03_overall_kpis.sql: ratios of totals, NULLIF guards, approved conversions for CPA.
--
-- Minimum volume: a segment is ranked only if it has at least 10 approved conversions,
-- so its CPA is not driven by one or two lucky conversions.
-- (The spend rule from 07_kpis_interest.sql would keep only 9 segments, almost all from
-- campaign 1178, so the best and worst lists would overlap.)

-- 1. All segments with KPIs, largest spend first. "eligible" marks segments that are ranked below.
SELECT
    campaign_id,
    age_group,
    gender,
    COUNT(*)                                                                    AS ads,
    SUM(clicks)                                                                 AS clicks,
    SUM(spent)                                                                  AS spent_usd,
    ROUND(100.0 * SUM(spent) / SUM(SUM(spent)) OVER (), 2)                      AS spend_share_pct,
    SUM(approved_conversion)                                                    AS approved_conv,
    ROUND(100.0 * SUM(clicks)              / NULLIF(SUM(impressions), 0), 4)    AS ctr_pct,
    ROUND(        SUM(spent)               / NULLIF(SUM(clicks), 0), 2)         AS cpc_usd,
    ROUND(        SUM(spent)               / NULLIF(SUM(approved_conversion), 0), 2) AS cpa_usd,
    ROUND(100.0 * SUM(approved_conversion) / NULLIF(SUM(clicks), 0), 2)         AS conv_rate_pct,
    IF(SUM(approved_conversion) >= 10, 'yes', 'no')                             AS eligible
FROM ads_clean
GROUP BY campaign_id, age_group, gender
ORDER BY spent_usd DESC;

-- 2. Best 5 (lowest CPA) and worst 5 (highest CPA) eligible segments
WITH account AS (
    SELECT SUM(spent) / NULLIF(SUM(approved_conversion), 0) AS account_cpa
    FROM ads_clean
),
segments AS (
    SELECT
        campaign_id, age_group, gender,
        SUM(clicks)                                                              AS clicks,
        SUM(spent)                                                               AS spent_usd,
        SUM(approved_conversion)                                                 AS approved_conv,
        SUM(spent) / NULLIF(SUM(approved_conversion), 0)                         AS cpa_exact,
        ROUND(100.0 * SUM(approved_conversion) / NULLIF(SUM(clicks), 0), 2)      AS conv_rate_pct
    FROM ads_clean
    GROUP BY campaign_id, age_group, gender
    HAVING SUM(approved_conversion) >= 10
),
ranked AS (
    SELECT
        s.*,
        ROUND(100.0 * s.cpa_exact / a.account_cpa, 0)       AS cpa_index,
        ROW_NUMBER() OVER (ORDER BY s.cpa_exact ASC)        AS rank_best,
        ROW_NUMBER() OVER (ORDER BY s.cpa_exact DESC)       AS rank_worst
    FROM segments s
    CROSS JOIN account a
)
SELECT
    CASE WHEN rank_best <= 5 THEN 'best 5' ELSE 'worst 5' END   AS list_name,
    CASE WHEN rank_best <= 5 THEN rank_best ELSE rank_worst END AS rank_in_list,
    campaign_id, age_group, gender, clicks, spent_usd, approved_conv,
    ROUND(cpa_exact, 2) AS cpa_usd,
    conv_rate_pct, cpa_index
FROM ranked
WHERE rank_best <= 5 OR rank_worst <= 5
ORDER BY list_name, rank_in_list;

-- 3. Summary: best 5 vs worst 5 as groups, plus all other segments
WITH segments AS (
    SELECT
        campaign_id, age_group, gender,
        SUM(spent) / NULLIF(SUM(approved_conversion), 0) AS cpa_exact,
        SUM(approved_conversion) >= 10                   AS is_eligible
    FROM ads_clean
    GROUP BY campaign_id, age_group, gender
),
labelled AS (
    SELECT
        campaign_id, age_group, gender,
        CASE
            WHEN NOT is_eligible THEN 'other'
            WHEN ROW_NUMBER() OVER (PARTITION BY is_eligible ORDER BY cpa_exact ASC)  <= 5 THEN 'best 5'
            WHEN ROW_NUMBER() OVER (PARTITION BY is_eligible ORDER BY cpa_exact DESC) <= 5 THEN 'worst 5'
            ELSE 'other'
        END AS list_name
    FROM segments
)
SELECT
    IF(GROUPING(l.list_name), 'Total', l.list_name)                             AS list_name,
    COUNT(DISTINCT l.campaign_id, l.age_group, l.gender)                        AS segments,
    SUM(c.spent)                                                                AS spent_usd,
    ROUND(100.0 * SUM(c.spent) / (SELECT SUM(spent) FROM ads_clean), 2)         AS spend_share_pct,
    SUM(c.approved_conversion)                                                  AS approved_conv,
    ROUND(100.0 * SUM(c.approved_conversion)
                / (SELECT SUM(approved_conversion) FROM ads_clean), 2)          AS conv_share_pct,
    ROUND(SUM(c.spent) / NULLIF(SUM(c.approved_conversion), 0), 2)              AS cpa_usd
FROM labelled l
JOIN ads_clean c
  ON c.campaign_id = l.campaign_id AND c.age_group = l.age_group AND c.gender = l.gender
GROUP BY l.list_name WITH ROLLUP;

-- 4. Robustness check for eligible segments: share of conversions from zero-click (free) ads,
--    and CPA counting only conversions from ads that received clicks.
SELECT
    campaign_id, age_group, gender,
    SUM(approved_conversion)                                                    AS approved_conv,
    SUM(CASE WHEN clicks = 0 THEN approved_conversion ELSE 0 END)               AS free_approved_conv,
    ROUND(100.0 * SUM(CASE WHEN clicks = 0 THEN approved_conversion ELSE 0 END)
                / NULLIF(SUM(approved_conversion), 0), 1)                       AS free_conv_pct,
    ROUND(SUM(spent) / NULLIF(SUM(approved_conversion), 0), 2)                  AS cpa_usd,
    ROUND(SUM(spent) / NULLIF(SUM(CASE WHEN clicks > 0 THEN approved_conversion ELSE 0 END), 0), 2)
                                                                                AS cpa_paid_only_usd
FROM ads_clean
GROUP BY campaign_id, age_group, gender
HAVING SUM(approved_conversion) >= 10
ORDER BY cpa_paid_only_usd;
