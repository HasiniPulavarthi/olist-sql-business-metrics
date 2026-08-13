# Olist E-Commerce: SQL Business Metrics Project

A portfolio project answering real business questions — revenue trend, cohort
retention, churn, RFM segmentation, seller/delivery performance — using pure
SQL against the [Olist Brazilian E-Commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce),
with results built for a Power BI / Tableau dashboard.

## Why this dataset
Olist is a real, messy, relational e-commerce dataset (9 linked tables:
orders, customers, order items, payments, products, sellers, reviews,
geolocation). Unlike a single flat CSV, it forces you to actually design
joins and think about grain (order vs order-item vs customer), which is
closer to real BA/DA work than a toy dataset.

## Project structure
```
olist-sql-project/
├── README.md
├── sql/
│   ├── 01_schema.sql              -- table definitions (Postgres)
│   ├── 02_load_data.sql           -- COPY commands to load CSVs
│   ├── 03_data_cleaning.sql       -- dedupe, null handling, type fixes
│   ├── 04_revenue_trend.sql       -- monthly revenue, MoM growth, by region
│   ├── 05_cohort_retention.sql    -- cohort table + retention matrix
│   ├── 06_churn.sql               -- churn definition + churned customer list
│   ├── 07_rfm_segmentation.sql    -- Recency/Frequency/Monetary + segments
│   ├── 08_seller_performance.sql  -- top sellers, delivery time, cancellations
│   └── 09_delivery_delay.sql      -- delay vs review score correlation
└── docs/
    └── dashboard_notes.md         -- how to map each query to a dashboard page
```

## Setup (Postgres, but works in DuckDB/BigQuery with minor tweaks)

1. Download the 9 CSVs from Kaggle and place them in a `data/` folder:
   - olist_customers_dataset.csv
   - olist_orders_dataset.csv
   - olist_order_items_dataset.csv
   - olist_order_payments_dataset.csv
   - olist_order_reviews_dataset.csv
   - olist_products_dataset.csv
   - olist_sellers_dataset.csv
   - olist_geolocation_dataset.csv
   - product_category_name_translation.csv

2. Create the database and run scripts in order:
```bash
createdb olist
psql olist -f sql/01_schema.sql
psql olist -f sql/02_load_data.sql
psql olist -f sql/03_data_cleaning.sql
```

3. Run each analysis script and export results to CSV for the dashboard:
```bash
psql olist -f sql/04_revenue_trend.sql -c "\copy (select * from monthly_revenue) to 'out/monthly_revenue.csv' csv header"
```
   (Or just connect Power BI / Tableau directly to Postgres and point each
   visual at the relevant query/view.)

## How to present this in a portfolio
- Turn each `.sql` file into a section of a write-up: **question → query →
  one sentence of business insight** (e.g. "São Paulo generates 38% of
  revenue but has the second-highest delivery delay — logistics bottleneck
  worth flagging").
- Push to GitHub with the CSV outputs (or a sample) and dashboard screenshots.
- In interviews, be ready to explain *why* you defined churn the way you did
  — Olist has no subscription, so churn has to be inferred from purchase
  gaps, and defending that assumption is itself a good BA signal.
