-- 04_kpis_campaign.sql
-- KPIs per campaign (campaign_id = the advertiser's xyz_campaign_id).
-- Same rules as 03_overall_kpis.sql: ratios of totals, NULLIF guards, approved conversions for CPA.
--
-- Extra columns:
--   spend_share_pct / conv_share_pct : share of account spend and of approved conversions.
--                                      A campaign whose spend share is above its conversion share is overspending.
--   cpa_index : campaign CPA / account CPA * 100. 100 = account average, below 100 = cheaper conversions.

-- 1. Volume and KPIs per campaign
SELECT
    campaign_id,
    COUNT(*)                                                                    AS ads,
    SUM(impressions)                                                            AS impressions,
    SUM(clicks)                                                                 AS clicks,
    SUM(spent)                                                                  AS spent_usd,
    SUM(approved_conversion)                                                    AS approved_conv,
    SUM(total_conversion)                                                       AS total_conv,
    ROUND(100.0 * SUM(clicks)              / NULLIF(SUM(impressions), 0), 4)    AS ctr_pct,
    ROUND(        SUM(spent)               / NULLIF(SUM(clicks), 0), 2)         AS cpc_usd,
    ROUND(1000  * SUM(spent)               / NULLIF(SUM(impressions), 0), 2)    AS cpm_usd,
    ROUND(        SUM(spent)               / NULLIF(SUM(approved_conversion), 0), 2) AS cpa_usd,
    ROUND(100.0 * SUM(approved_conversion) / NULLIF(SUM(clicks), 0), 2)         AS conv_rate_pct,
    ROUND(100.0 * SUM(approved_conversion) / NULLIF(SUM(total_conversion), 0), 2) AS approval_rate_pct
FROM ads_clean
GROUP BY campaign_id
ORDER BY spent_usd DESC;

-- 2. Budget efficiency: share of spend vs share of results, and CPA vs the account average
SELECT
    campaign_id,
    ROUND(100.0 * SUM(spent)               / SUM(SUM(spent))               OVER (), 2) AS spend_share_pct,
    ROUND(100.0 * SUM(approved_conversion) / SUM(SUM(approved_conversion)) OVER (), 2) AS conv_share_pct,
    ROUND(100.0 * SUM(clicks)              / SUM(SUM(clicks))              OVER (), 2) AS click_share_pct,
    ROUND(100.0 * (SUM(spent) / NULLIF(SUM(approved_conversion), 0))
                / (SUM(SUM(spent)) OVER () / NULLIF(SUM(SUM(approved_conversion)) OVER (), 0)), 0) AS cpa_index
FROM ads_clean
GROUP BY campaign_id
ORDER BY campaign_id;

-- 3. Reconciliation: campaigns must add up to the account totals (1,143 ads, $58,705.23, 1,079 approved)
SELECT
    SUM(ads) AS ads, SUM(spent_usd) AS spent_usd, SUM(approved_conv) AS approved_conv
FROM (
    SELECT campaign_id, COUNT(*) AS ads, SUM(spent) AS spent_usd, SUM(approved_conversion) AS approved_conv
    FROM ads_clean
    GROUP BY campaign_id
) AS per_campaign;

-- 4. Robustness check: how much do zero-click, zero-spend ads (view-through conversions) flatter each campaign?
--    cpa_paid_only_usd counts only conversions from ads that received clicks.
SELECT
    campaign_id,
    SUM(clicks = 0)                                                             AS zero_click_ads,
    SUM(CASE WHEN clicks = 0 THEN approved_conversion ELSE 0 END)               AS free_approved_conv,
    ROUND(100.0 * SUM(CASE WHEN clicks = 0 THEN approved_conversion ELSE 0 END)
                / NULLIF(SUM(approved_conversion), 0), 1)                       AS free_conv_pct,
    ROUND(SUM(spent) / NULLIF(SUM(CASE WHEN clicks > 0 THEN approved_conversion ELSE 0 END), 0), 2)
                                                                                AS cpa_paid_only_usd
FROM ads_clean
GROUP BY campaign_id
ORDER BY campaign_id;
