-- dashboard_questions.sql
-- SQL for the 13 Metabase questions (charts) on the Ad KPI dashboard.
-- Paste each block into Metabase: + New -> SQL query -> database "Ad KPI (MySQL)".
--
-- {{campaign}}, {{age_group}} and {{gender}} are Metabase Field Filters, mapped to
-- V Ads -> Campaign, V Ads -> Age Group and V Ads -> Gender. When a filter is empty,
-- Metabase replaces it with a condition that is always true, so the query covers all ads.
-- This file is NOT part of the run_sql.py pipeline (MySQL cannot run the {{ }} syntax).
--
-- KPI rules (same as sql/03-08): ratios of totals, NULLIF guards, approved conversions for CPA.

-- ============================================================
-- KPI cards (visualization: Number)
-- ============================================================

-- Q01 | KPI - Spend (USD)
SELECT SUM(spent) AS spend_usd
FROM v_ads
WHERE {{campaign}} AND {{age_group}} AND {{gender}};

-- Q02 | KPI - CTR (%)
SELECT ROUND(100.0 * SUM(clicks) / NULLIF(SUM(impressions), 0), 4) AS ctr_pct
FROM v_ads
WHERE {{campaign}} AND {{age_group}} AND {{gender}};

-- Q03 | KPI - CPC (USD)
SELECT ROUND(SUM(spent) / NULLIF(SUM(clicks), 0), 2) AS cpc_usd
FROM v_ads
WHERE {{campaign}} AND {{age_group}} AND {{gender}};

-- Q04 | KPI - CPM (USD)
SELECT ROUND(1000 * SUM(spent) / NULLIF(SUM(impressions), 0), 2) AS cpm_usd
FROM v_ads
WHERE {{campaign}} AND {{age_group}} AND {{gender}};

-- Q05 | KPI - CPA (USD, approved conversions)
SELECT ROUND(SUM(spent) / NULLIF(SUM(approved_conversion), 0), 2) AS cpa_usd
FROM v_ads
WHERE {{campaign}} AND {{age_group}} AND {{gender}};

-- Q06 | KPI - Conversion rate (%, approved conversions per click)
SELECT ROUND(100.0 * SUM(approved_conversion) / NULLIF(SUM(clicks), 0), 2) AS conv_rate_pct
FROM v_ads
WHERE {{campaign}} AND {{age_group}} AND {{gender}};

-- ============================================================
-- Bar charts (visualization: Bar)
-- ============================================================

-- Q07 | CPA by campaign
SELECT campaign, ROUND(SUM(spent) / NULLIF(SUM(approved_conversion), 0), 2) AS cpa_usd
FROM v_ads
WHERE {{campaign}} AND {{age_group}} AND {{gender}}
GROUP BY campaign, campaign_id
ORDER BY campaign_id;

-- Q08 | CTR by campaign
SELECT campaign, ROUND(100.0 * SUM(clicks) / NULLIF(SUM(impressions), 0), 4) AS ctr_pct
FROM v_ads
WHERE {{campaign}} AND {{age_group}} AND {{gender}}
GROUP BY campaign, campaign_id
ORDER BY campaign_id;

-- Q09 | CPA by age group
SELECT age_group, ROUND(SUM(spent) / NULLIF(SUM(approved_conversion), 0), 2) AS cpa_usd
FROM v_ads
WHERE {{campaign}} AND {{age_group}} AND {{gender}}
GROUP BY age_group
ORDER BY age_group;

-- Q10 | CTR by age group
SELECT age_group, ROUND(100.0 * SUM(clicks) / NULLIF(SUM(impressions), 0), 4) AS ctr_pct
FROM v_ads
WHERE {{campaign}} AND {{age_group}} AND {{gender}}
GROUP BY age_group
ORDER BY age_group;

-- Q11 | CPA by gender
SELECT gender, ROUND(SUM(spent) / NULLIF(SUM(approved_conversion), 0), 2) AS cpa_usd
FROM v_ads
WHERE {{campaign}} AND {{age_group}} AND {{gender}}
GROUP BY gender
ORDER BY gender;

-- Q12 | CTR by gender
SELECT gender, ROUND(100.0 * SUM(clicks) / NULLIF(SUM(impressions), 0), 4) AS ctr_pct
FROM v_ads
WHERE {{campaign}} AND {{age_group}} AND {{gender}}
GROUP BY gender
ORDER BY gender;

-- ============================================================
-- Scatter plot (visualization: Scatter)
-- ============================================================

-- Q13 | Spend vs approved conversions (one dot per ad, coloured by campaign)
-- Largest campaign first: dots are drawn in row order, so the small campaigns stay visible on top.
SELECT ad_id, campaign, spent AS spend_usd, approved_conversion AS approved_conversions
FROM v_ads
WHERE {{campaign}} AND {{age_group}} AND {{gender}}
ORDER BY campaign_id DESC;
