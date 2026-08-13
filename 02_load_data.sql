-- ============================================================
-- 02_load_data.sql
-- Load the Kaggle CSVs into the tables created in 01_schema.sql
-- Run from a machine that has the CSVs in ./data/
-- Adjust the path if your CSVs live elsewhere.
-- ============================================================

\copy customers FROM 'data/olist_customers_dataset.csv' WITH (FORMAT csv, HEADER true);
\copy sellers FROM 'data/olist_sellers_dataset.csv' WITH (FORMAT csv, HEADER true);
\copy product_category_translation FROM 'data/product_category_name_translation.csv' WITH (FORMAT csv, HEADER true);
\copy products FROM 'data/olist_products_dataset.csv' WITH (FORMAT csv, HEADER true);
\copy orders FROM 'data/olist_orders_dataset.csv' WITH (FORMAT csv, HEADER true);
\copy order_items FROM 'data/olist_order_items_dataset.csv' WITH (FORMAT csv, HEADER true);
\copy order_payments FROM 'data/olist_order_payments_dataset.csv' WITH (FORMAT csv, HEADER true);
\copy order_reviews FROM 'data/olist_order_reviews_dataset.csv' WITH (FORMAT csv, HEADER true);
\copy geolocation FROM 'data/olist_geolocation_dataset.csv' WITH (FORMAT csv, HEADER true);

-- Sanity check row counts
SELECT 'customers' AS tbl, COUNT(*) FROM customers
UNION ALL SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL SELECT 'geolocation', COUNT(*) FROM geolocation;
