# Mapping SQL Outputs to a Power BI / Tableau Dashboard

Connect directly to Postgres (Power BI: Get Data → PostgreSQL; Tableau:
Connect → PostgreSQL), or export each view to CSV with `\copy` and load
those instead — either works for a portfolio piece.

## Page 1 — Executive Summary
KPI cards + trend line.
- **Total revenue, total orders, avg order value** — from `order_revenue` / `monthly_revenue`
- **Repeat purchase rate** — from query 5e in `05_cohort_retention.sql`
- **Churn rate** — from query 6c in `06_churn.sql`
- **Monthly revenue trend line with MoM % growth** — `monthly_revenue` view

## Page 2 — Cohort Retention
- Heatmap: rows = `cohort_month`, columns = `months_since_first_purchase`,
  value = `retention_pct`, from the `retention_matrix` view.
- Add a note on the chart explaining Olist's low repeat-purchase base rate
  so the heatmap doesn't read as "broken" — it's a genuine dataset trait.

## Page 3 — Customer Segmentation (RFM)
- Bar chart: segment vs customer count, from the segment-summary query in
  `07_rfm_segmentation.sql`.
- Scatter plot: recency (x) vs monetary (y), colored by segment, from
  `customer_rfm_segment` — this is the single most "BA-native" visual in
  the whole project, use it prominently.

## Page 4 — Geography
- Map (state-level choropleth): `revenue_by_state` for revenue, and
  `order_delivery_delay` state aggregation for delay — put them as two
  toggleable layers if your tool supports it (Tableau: two sheets on a
  dashboard with a filter action; Power BI: a slicer that switches the
  map's color measure).

## Page 5 — Sellers & Delivery
- Table: top 20 sellers from `seller_scorecard`, sortable by revenue,
  cancellation rate, delivery days, review score.
- Bar chart: `order_delivery_delay` bucket vs `avg_review_score` — this is
  the "ops drives satisfaction" story, worth a callout box on the page.

## Presentation tips
- Every page should answer one plain-English business question in its
  title, not a metric name — e.g. "Where are we losing customers?" not
  "Churn Analysis."
- Keep 3–5 KPI cards max on the summary page; put everything else on
  drill-down pages.
- Screenshot each page for the GitHub README so it renders without anyone
  needing to open the actual dashboard file.
