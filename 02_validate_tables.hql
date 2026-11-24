-- =====================================================================
-- Member 8 - Script 02: check the tables read the HDFS files correctly
-- Run with:  hive -f 02_validate_tables.hql
-- Expected values are in expected_results/00_validation.csv
-- =====================================================================
SET hive.cli.print.header=true;
USE dataco_dl;

-- Row counts: expect 180519 items and 65752 orders (header row skipped)
SELECT 'order_items' AS table_name, COUNT(*) AS row_count FROM order_items
UNION ALL
SELECT 'orders' AS table_name, COUNT(*) AS row_count FROM orders;

-- Parsing check: every key, number and date must parse (all expect 0)
SELECT
    SUM(CASE WHEN order_item_id IS NULL THEN 1 ELSE 0 END)           AS null_item_id,
    SUM(CASE WHEN sales IS NULL THEN 1 ELSE 0 END)                   AS null_sales,
    SUM(CASE WHEN order_profit_per_order IS NULL THEN 1 ELSE 0 END)  AS null_profit,
    SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END)              AS null_order_date,
    COUNT(DISTINCT order_id)                                         AS distinct_orders,
    COUNT(DISTINCT product_card_id)                                  AS distinct_products,
    COUNT(DISTINCT order_region)                                     AS distinct_regions
FROM order_items;

-- Sample rows to show the columns line up
SELECT order_id, order_date, category_name, product_name, sales, order_item_total,
       order_profit_per_order, order_region, shipping_mode
FROM order_items LIMIT 5;

SELECT * FROM orders LIMIT 5;
