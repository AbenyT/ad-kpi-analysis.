-- 07_kpis_interest.sql
-- KPIs per interest (Facebook interest category), top 10 and bottom 10 by CPA.
-- Same rules as 03_overall_kpis.sql: ratios of totals, NULLIF guards, approved conversions for CPA.
--
-- Minimum spend: an interest is ranked only if it spent at least 10 x the account CPA
-- (enough budget to buy ~10 conversions at average cost). Smaller interests have CPAs
-- driven by a handful of conversions, so ranking them would reward luck.
-- The threshold is calculated from the data, not hard-coded.

-- 1. Coverage: how many interests qualify, and how much of the budget they represent
WITH account AS (
    SELECT SUM(spent) / NULLIF(SUM(approved_conversion), 0) AS account_cpa,
           SUM(spent)                                       AS account_spent
    FROM ads_clean
),
per_interest AS (
    SELECT interest_id, SUM(spent) AS spent
    FROM ads_clean
    GROUP BY interest_id
)
SELECT
    ROUND(10 * a.account_cpa, 2)                                       AS min_spend_usd,
    COUNT(*)                                                           AS interests_total,
    SUM(p.spent >= 10 * a.account_cpa)                                 AS interests_ranked,
    SUM(p.spent <  10 * a.account_cpa)                                 AS interests_excluded,
    ROUND(100.0 * SUM(CASE WHEN p.spent >= 10 * a.account_cpa THEN p.spent ELSE 0 END)
                / a.account_spent, 2)                                  AS spend_covered_pct
FROM per_interest p
CROSS JOIN account a
GROUP BY a.account_cpa, a.account_spent;

-- 2. Top 10 (lowest CPA) and bottom 10 (highest CPA) among eligible interests
WITH account AS (
    SELECT SUM(spent) / NULLIF(SUM(approved_conversion), 0) AS account_cpa
    FROM ads_clean
),
per_interest AS (
    SELECT
        interest_id,
        COUNT(*)                                                                 AS ads,
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
ranked AS (
    SELECT
        p.*,
        ROUND(100.0 * p.cpa_exact / a.account_cpa, 0)                            AS cpa_index,
        -- NULL CPA (spend but no approved conversion) is the worst outcome, so it ranks last
        ROW_NUMBER() OVER (ORDER BY p.cpa_exact IS NULL, p.cpa_exact ASC)        AS rank_best,
        ROW_NUMBER() OVER (ORDER BY p.cpa_exact IS NULL DESC, p.cpa_exact DESC)  AS rank_worst
    FROM per_interest p
    CROSS JOIN account a
    WHERE p.spent_usd >= 10 * a.account_cpa
)
SELECT
    CASE WHEN rank_best <= 10 THEN 'top 10' ELSE 'bottom 10' END AS list_name,
    CASE WHEN rank_best <= 10 THEN rank_best ELSE rank_worst END AS rank_in_list,
    interest_id, ads, clicks, spent_usd, approved_conv,
    ctr_pct, cpc_usd, cpm_usd,
    ROUND(cpa_exact, 2) AS cpa_usd,
    conv_rate_pct, cpa_index
FROM ranked
WHERE rank_best <= 10 OR rank_worst <= 10
ORDER BY list_name DESC, rank_in_list;

-- 3. Summary: top 10 vs bottom 10 as groups (KPIs recalculated from the groups' totals)
WITH account AS (
    SELECT SUM(spent) / NULLIF(SUM(approved_conversion), 0) AS account_cpa
    FROM ads_clean
),
per_interest AS (
    SELECT interest_id, SUM(spent) AS spent, SUM(approved_conversion) AS approved_conv
    FROM ads_clean
    GROUP BY interest_id
),
ranked AS (
    SELECT
        p.interest_id,
        ROW_NUMBER() OVER (ORDER BY p.spent / NULLIF(p.approved_conv, 0) IS NULL,
                                    p.spent / NULLIF(p.approved_conv, 0) ASC)  AS rank_best,
        ROW_NUMBER() OVER (ORDER BY p.spent / NULLIF(p.approved_conv, 0) IS NULL DESC,
                                    p.spent / NULLIF(p.approved_conv, 0) DESC) AS rank_worst
    FROM per_interest p
    CROSS JOIN account a
    WHERE p.spent >= 10 * a.account_cpa
)
SELECT
    CASE WHEN r.rank_best <= 10 THEN 'top 10' ELSE 'bottom 10' END                AS list_name,
    SUM(c.spent)                                                                  AS spent_usd,
    ROUND(100.0 * SUM(c.spent) / (SELECT SUM(spent) FROM ads_clean), 2)           AS spend_share_pct,
    SUM(c.approved_conversion)                                                    AS approved_conv,
    ROUND(SUM(c.spent) / NULLIF(SUM(c.approved_conversion), 0), 2)                AS cpa_usd,
    ROUND(100.0 * SUM(c.approved_conversion) / NULLIF(SUM(c.clicks), 0), 2)      AS conv_rate_pct
FROM ranked r
JOIN ads_clean c ON c.interest_id = r.interest_id
WHERE r.rank_best <= 10 OR r.rank_worst <= 10
GROUP BY list_name
ORDER BY list_name DESC;
