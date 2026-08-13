-- ============================================================
-- 03_data_cleaning.sql
-- Cleaning pass: duplicates, nulls, obvious bad rows, review
-- score bounds, negative/zero prices, orphaned rows.
-- Each check first SELECTs the problem rows, then fixes/removes.
-- ============================================================

-- 1. Duplicate reviews (same review_id appearing for multiple orders,
--    or exact duplicate rows) -- keep the most recently answered one
WITH ranked AS (
    SELECT ctid,
           ROW_NUMBER() OVER (
               PARTITION BY review_id, order_id
               ORDER BY review_answer_timestamp DESC NULLS LAST
           ) AS rn
    FROM order_reviews
)
DELETE FROM order_reviews
WHERE ctid IN (SELECT ctid FROM ranked WHERE rn > 1);

-- 2. Review scores must be 1-5; drop anything outside that range
DELETE FROM order_reviews
WHERE review_score IS NULL OR review_score NOT BETWEEN 1 AND 5;

-- 3. Orders with no matching customer (orphaned FK) -- shouldn't exist
--    given the FK constraint, but check pre-load data quality
SELECT COUNT(*) AS orphaned_orders
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- 4. Order items with non-positive price or freight -- flag, don't
--    blindly delete (could be legitimate free-shipping promos)
SELECT *
FROM order_items
WHERE price <= 0 OR freight_value < 0;

-- 5. Delivered orders where delivered date is BEFORE purchase date
--    (impossible / data entry error) -- exclude from delivery-time analysis
SELECT order_id, order_purchase_timestamp, order_delivered_customer_date
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_delivered_customer_date < order_purchase_timestamp;

-- 6. Standardize state codes to uppercase (defensive; Olist data is
--    generally clean here but this guards against re-exports)
UPDATE customers SET customer_state = UPPER(customer_state);
UPDATE sellers SET seller_state = UPPER(seller_state);

-- 7. Create a clean view of orders limited to statuses that represent
--    a completed transaction -- most revenue/cohort queries should
--    use this view rather than the raw table, since 'canceled' and
--    'unavailable' orders shouldn't count as revenue
CREATE OR REPLACE VIEW valid_orders AS
SELECT *
FROM orders
WHERE order_status NOT IN ('canceled', 'unavailable')
  AND order_purchase_timestamp IS NOT NULL;

-- 8. Create an order-level revenue view (item price + freight,
--    aggregated up from the item grain to the order grain)
CREATE OR REPLACE VIEW order_revenue AS
SELECT
    oi.order_id,
    SUM(oi.price) AS items_revenue,
    SUM(oi.freight_value) AS freight_revenue,
    SUM(oi.price + oi.freight_value) AS total_revenue
FROM order_items oi
GROUP BY oi.order_id;
