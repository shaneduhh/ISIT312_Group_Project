-- =====================================================================
-- Member 8 - Script 03: the five analysis queries
-- Each query is saved as a view (so Script 04 can export it) and then run.
-- Definitions follow Member 3's analysis:
--   * Sales queries exclude CANCELED and SUSPECTED_FRAUD orders.
--   * Late-delivery and shipping-time queries use the orders table (one
--     row per order) and exclude 'Shipping canceled' orders.
--   * Profit uses COMPLETE orders only, grouped by category id and name
--     (Electronics has two ids, 13 and 37).
-- Run with:  hive -f 03_analysis_queries.hql
-- =====================================================================
SET hive.cli.print.header=true;
USE dataco_dl;

-- ---------------------------------------------------------------------
-- Q1. Total sales by category
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS q1_sales_by_category;
CREATE VIEW q1_sales_by_category AS
SELECT
    category_id,
    category_name,
    COUNT(*)                          AS items_sold,
    SUM(order_item_quantity)          AS units_sold,
    ROUND(SUM(sales), 2)              AS gross_sales,
    ROUND(SUM(order_item_total), 2)   AS net_sales
FROM order_items
WHERE order_status NOT IN ('CANCELED', 'SUSPECTED_FRAUD')
GROUP BY category_id, category_name
ORDER BY net_sales DESC;

SELECT * FROM q1_sales_by_category;

-- ---------------------------------------------------------------------
-- Q2. Late-delivery percentage (overall, then by shipping mode)
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS q2a_late_delivery_overall;
CREATE VIEW q2a_late_delivery_overall AS
SELECT
    COUNT(*)                                             AS eligible_orders,
    SUM(late_delivery_risk)                              AS late_orders,
    ROUND(100.0 * SUM(late_delivery_risk) / COUNT(*), 2) AS late_percent
FROM orders
WHERE delivery_status IN ('Advance shipping', 'Shipping on time', 'Late delivery');

DROP VIEW IF EXISTS q2b_late_delivery_by_mode;
CREATE VIEW q2b_late_delivery_by_mode AS
SELECT
    shipping_mode,
    COUNT(*)                                             AS eligible_orders,
    SUM(late_delivery_risk)                              AS late_orders,
    ROUND(100.0 * SUM(late_delivery_risk) / COUNT(*), 2) AS late_percent
FROM orders
WHERE delivery_status IN ('Advance shipping', 'Shipping on time', 'Late delivery')
GROUP BY shipping_mode
ORDER BY late_percent DESC;

SELECT * FROM q2a_late_delivery_overall;
SELECT * FROM q2b_late_delivery_by_mode;

-- ---------------------------------------------------------------------
-- Q3. Average shipping time by region
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS q3_shipping_time_by_region;
CREATE VIEW q3_shipping_time_by_region AS
SELECT
    order_region,
    COUNT(*)                                                        AS order_count,
    ROUND(AVG(days_for_shipping_real), 2)                           AS avg_actual_days,
    ROUND(AVG(days_for_shipment_scheduled), 2)                      AS avg_scheduled_days,
    ROUND(AVG(days_for_shipping_real - days_for_shipment_scheduled), 2) AS avg_delay_days,
    ROUND(100.0 * SUM(late_delivery_risk) / COUNT(*), 2)            AS late_percent
FROM orders
WHERE delivery_status <> 'Shipping canceled'
GROUP BY order_region
ORDER BY avg_actual_days DESC;

SELECT * FROM q3_shipping_time_by_region;

-- ---------------------------------------------------------------------
-- Q4. Top 10 products by sales
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS q4_top10_products;
CREATE VIEW q4_top10_products AS
SELECT
    product_card_id,
    product_name,
    category_name,
    SUM(order_item_quantity)          AS units_sold,
    ROUND(SUM(order_item_total), 2)   AS net_sales,
    ROUND(SUM(order_profit_per_order), 2) AS profit
FROM order_items
WHERE order_status NOT IN ('CANCELED', 'SUSPECTED_FRAUD')
GROUP BY product_card_id, product_name, category_name
ORDER BY net_sales DESC
LIMIT 10;

SELECT * FROM q4_top10_products;

-- ---------------------------------------------------------------------
-- Q5. Profitability by product category (COMPLETE orders)
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS q5_profit_by_category;
CREATE VIEW q5_profit_by_category AS
SELECT
    category_id,
    category_name,
    COUNT(*)                                                         AS items,
    ROUND(SUM(order_profit_per_order), 2)                            AS profit,
    ROUND(SUM(order_item_total), 2)                                  AS net_sales,
    ROUND(100.0 * SUM(order_profit_per_order) / SUM(order_item_total), 2) AS margin_percent
FROM order_items
WHERE order_status = 'COMPLETE'
GROUP BY category_id, category_name
ORDER BY profit DESC;

SELECT * FROM q5_profit_by_category;
