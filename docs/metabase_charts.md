# Build the dashboard charts in Metabase

Tested with Metabase v0.63.19. The SQL for every chart is in
[`metabase/dashboard_questions.sql`](../metabase/dashboard_questions.sql) (Q01–Q13).

Every chart is a **SQL question** with three **Field Filters** (`{{campaign}}`, `{{age_group}}`, `{{gender}}`).
The KPI formulas stay in SQL, and the charts follow the dashboard filters in step 15.

## 0. Create a collection

**+ New → Collection** → name it `Ad KPI Analysis` → **Create**. Save every question in it.

## 1. Build the template question (once)

1. **+ New → SQL query**. If asked, choose the database **Ad KPI (MySQL)**.
2. Paste the SQL of **Q05 (CPA)**:

   ```sql
   SELECT ROUND(SUM(spent) / NULLIF(SUM(approved_conversion), 0), 2) AS cpa_usd
   FROM v_ads
   WHERE {{campaign}} AND {{age_group}} AND {{gender}};
   ```

3. The **Variables and parameters** panel opens on the right with one block per variable. For each of the three:

   | Variable name | Variable type | Field to map to | Filter widget label |
   |---|---|---|---|
   | `campaign` | **Field Filter** | **V Ads → Campaign** | `Campaign` |
   | `age_group` | **Field Filter** | **V Ads → Age Group** | `Age group` |
   | `gender` | **Field Filter** | **V Ads → Gender** | `Gender` |

   Leave **Always require a value** off. An empty filter means "all ads".
4. Click **Run** (or Ctrl/Cmd + Enter). Expected result: **54.41**.
5. Test a filter: choose `Campaign 1178` in the **Campaign** dropdown above the editor and run again. Expected: **63.83**. Clear the filter.
6. Set up the KPI card (see section 2), then **Save** as `KPI - CPA` in the `Ad KPI Analysis` collection.

## 2. Create the other questions by duplicating

For each remaining question: open `KPI - CPA` → **⋯** (top right) → **Duplicate** → rename → **Open editor**,
replace the SQL with the next block from `metabase/dashboard_questions.sql`, click **Run**, set the visualization, then **Save**.
Duplicating keeps the three Field Filters, so you set them up only once.

If **Duplicate** is missing, create a new SQL query and repeat step 1.3.

### KPI cards: visualization **Number**

Click **Visualization** (bottom left) → **Number**. Click the **gear** icon → **Formatting** for the prefix/suffix.

| Question | Save as | Expected (no filter) | Formatting |
|---|---|---|---|
| Q01 | `KPI - Spend` | 58,705.23 | Prefix `$` |
| Q02 | `KPI - CTR` | 0.0179 | Suffix `%`, 4 decimals |
| Q03 | `KPI - CPC` | 1.54 | Prefix `$` |
| Q04 | `KPI - CPM` | 0.28 | Prefix `$` |
| Q05 | `KPI - CPA` | 54.41 | Prefix `$` |
| Q06 | `KPI - Conversion rate` | 2.83 | Suffix `%` |

### Bar charts: visualization **Bar**

Click **Visualization** → **Bar**. Metabase picks the label column for the X-axis and the KPI for the Y-axis.
Then click the **gear** icon:

- **Display** tab: turn on **Show values on data points**.
- **Display** tab (CPA charts only): turn on **Goal line**, value `54.41`, label `Account CPA $54.41`.
- **Axes** tab: X-axis title (`Campaign`, `Age group` or `Gender`), Y-axis title (`CPA (USD)` or `CTR (%)`).
- **Data** tab: click the colour dot of the series and pick **one blue for every bar chart**.
  Avoid red and green: viewers read them as "bad" and "good".

| Question | Save as | Expected bars (no filter) |
|---|---|---|
| Q07 | `CPA by campaign` | 916: 6.24 · 936: 15.81 · 1178: 63.83 |
| Q08 | `CTR by campaign` | 916: 0.0234 · 936: 0.0244 · 1178: 0.0176 |
| Q09 | `CPA by age group` | 30.88 · 53.68 · 68.17 · 99.76 |
| Q10 | `CTR by age group` | 0.0139 · 0.0168 · 0.0195 · 0.0217 |
| Q11 | `CPA by gender` | Female: 69.70 · Male: 41.44 |
| Q12 | `CTR by gender` | Female: 0.0208 · Male: 0.0145 |

CPA and CTR stay in **separate charts**. They use different scales, and putting them on two Y-axes in one chart is hard to read.

### Scatter plot: visualization **Scatter**

| Question | Save as |
|---|---|
| Q13 | `Spend vs approved conversions` |

Click **Visualization** → **Scatter**, then the **gear** icon → **Data** tab:

- **X-axis:** `spend_usd`
- **Y-axis:** `approved_conversions`
- **Add series breakout:** `campaign` (one colour per campaign)

**Axes** tab: X-axis title `Spend per ad (USD)`, Y-axis title `Approved conversions`.
Expected: 1,143 dots. The query draws campaign 1178 first so the smaller campaigns 916 and 936 stay visible near zero.

## Checklist

When you're done, the `Ad KPI Analysis` collection holds 13 questions:
6 KPI cards, 6 bar charts and 1 scatter plot. Each one shows **Campaign**, **Age group** and **Gender** filters.
