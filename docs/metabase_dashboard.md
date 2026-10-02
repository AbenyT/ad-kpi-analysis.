# Arrange the dashboard and add filters

Tested with Metabase v0.63.19. Build the 13 questions first ([metabase_charts.md](metabase_charts.md)).

## Target layout

Metabase dashboards use a 24-column grid. Drag cards by their header and resize them from the bottom-right corner.

| Row | Content | Width each |
|---|---|---|
| 1 | Spend · CTR · CPC | 1/3 |
| 2 | CPM · CPA · Conversion rate | 1/3 |
| 3 | Heading: *Cost per approved conversion (CPA): lower is better. Dashed line = account average $54.41* | full |
| 4 | CPA by campaign · CPA by age group · CPA by gender | 1/3 |
| 5 | Heading: *Click-through rate (CTR): higher CTR does not mean cheaper conversions* | full |
| 6 | CTR by campaign · CTR by age group · CTR by gender | 1/3 |
| 7 | Heading: *Spend vs approved conversions: one dot per ad* | full |
| 8 | Spend vs approved conversions | full |

The KPI cards are 3 per row on purpose. At 6 per row they're too narrow, and Metabase shortens the numbers (CTR shows `0.02%` instead of `0.0179%`, and spend shows `$58.7k`).

Reading order follows the business question: **what did we get** (KPIs) → **where is it expensive** (CPA) → **does engagement explain it** (CTR, no) → **every ad at once** (scatter).

## 1. Short card titles

Rename the six KPI questions so the titles fit: open each one, click its title at the top, then type the new name and press Enter.
`KPI - Spend` → `Spend`, `KPI - CTR` → `CTR`, `KPI - CPC` → `CPC`, `KPI - CPM` → `CPM`, `KPI - CPA` → `CPA`, `KPI - Conversion rate` → `Conversion rate`.

## 2. Create the dashboard

1. **+ New → Dashboard**.
2. **Name:** `Facebook Ads KPI Dashboard`.
   **Description:** `CPA = cost per approved conversion (lower is better). Dashed line = account average.`
   **Which collection should this go in?** `Ad KPI Analysis`. Click **Create**.
3. The dashboard opens in edit mode. Click **Add questions** (the + icon in the top bar) and add all 13 questions from the `Ad KPI Analysis` collection.
4. Add the three headings: **Add a heading or text box** → **Heading**, then type the text from the layout table.
5. Arrange and resize the cards as in the layout table.
6. **Toggle width** in the top bar switches between fixed and full width. Fixed width is easier to read and to screenshot.

## 3. Add the filters

Do this three times, once per filter:

| Filter | Label | Column to filter on (first card) |
|---|---|---|
| 1 | `Campaign` | `Campaign` |
| 2 | `Age group` | `Age group` |
| 3 | `Gender` | `Gender` |

1. In edit mode, click **Add a filter or parameter** → **Text or Category**.
2. In the **Filter settings** panel on the right, set **Label**. Leave **Filter operator** as **Is**, keep **Dropdown list** and **Multiple values**, and leave **Always require a value** off.
3. Each card now shows **Column to filter on: Select…**. On the **Spend** card, click **Select…** and choose the variable from the table above.
4. Metabase asks **"Auto-connect this filter to all questions containing …?"** Click **Auto-connect**. All 13 cards are now connected; no card should still show **Select…**.
5. Click **Done**.

When all three filters are added, click **Save** (top right).

## 4. Check the filters

| Filters | Expected |
|---|---|
| None | Spend `$58,705.23`, CPA `$54.41`, CTR `0.0179%` |
| Campaign = `Campaign 1178` | CPA `$63.83` |
| Campaign = `Campaign 1178`, Gender = `Female` | CPA `$81.98`; CPA by age group 48.09 · 79.69 · 87.75 · 137.76 |
| Gender = `Male` | CPA `$41.44`; CPA by age group 25.55 · 45.10 · 54.46 · 76.22 |

Metabase remembers each user's last filter choice. Clear all three filters (the **×** in each filter) before taking the screenshot in step 16.
