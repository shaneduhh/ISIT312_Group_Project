SET hive.cli.print.header=true;
SET hive.resultset.use.unique.column.names=false;
SET hive.auto.convert.join=false;
USE dataco_dl;

SELECT * FROM (
SELECT 'A1 item rows = 180519' AS test, COUNT(*) AS actual,
       IF(COUNT(*) = 180519, 'PASS', 'FAIL') AS result FROM order_items
UNION ALL
SELECT 'A2 order rows = 65752', COUNT(*), IF(COUNT(*) = 65752, 'PASS', 'FAIL') FROM orders
UNION ALL
SELECT 'A3 duplicate order_item_id = 0', COUNT(*) - COUNT(DISTINCT order_item_id),
       IF(COUNT(*) = COUNT(DISTINCT order_item_id), 'PASS', 'FAIL') FROM order_items
UNION ALL
SELECT 'A4 NULL keys/amounts/dates = 0',
       SUM(IF(order_id IS NULL OR order_item_id IS NULL OR sales IS NULL OR order_item_total IS NULL
              OR order_profit_per_order IS NULL OR order_date IS NULL OR shipping_date IS NULL, 1, 0)),
       IF(SUM(IF(order_id IS NULL OR order_item_id IS NULL OR sales IS NULL OR order_item_total IS NULL
              OR order_profit_per_order IS NULL OR order_date IS NULL OR shipping_date IS NULL, 1, 0)) = 0, 'PASS', 'FAIL')
FROM order_items
UNION ALL
SELECT 'A5 shipping before order = 0', SUM(IF(shipping_date < order_date, 1, 0)),
       IF(SUM(IF(shipping_date < order_date, 1, 0)) = 0, 'PASS', 'FAIL') FROM order_items
UNION ALL
SELECT 'A6 late_risk matches status (mismatches = 0)',
       SUM(IF((late_delivery_risk = 1) <> (delivery_status = 'Late delivery'), 1, 0)),
       IF(SUM(IF((late_delivery_risk = 1) <> (delivery_status = 'Late delivery'), 1, 0)) = 0, 'PASS', 'FAIL')
FROM order_items
) a ORDER BY test;

SELECT 'A7 items vs orders mismatches = 0' AS test, COUNT(*) AS actual,
       IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result
FROM order_items i LEFT JOIN orders o ON i.order_id = o.order_id
WHERE o.order_id IS NULL OR i.delivery_status <> o.delivery_status
   OR i.shipping_mode <> o.shipping_mode OR i.order_region <> o.order_region
   OR i.days_for_shipping_real <> o.days_for_shipping_real;

DROP TABLE IF EXISTS mr_sales;
CREATE EXTERNAL TABLE mr_sales (category_id INT, category_name STRING, gross_sales DOUBLE, net_sales DOUBLE)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' LOCATION '/datalake/curated/mapreduce/sales';

DROP TABLE IF EXISTS mr_profit;
CREATE EXTERNAL TABLE mr_profit (category_id INT, category_name STRING, profit DOUBLE)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' LOCATION '/datalake/curated/mapreduce/profit';

DROP TABLE IF EXISTS mr_late;
CREATE EXTERNAL TABLE mr_late (shipping_mode STRING, eligible_orders INT, late_orders INT, late_percent DOUBLE)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' LOCATION '/datalake/curated/mapreduce/late';

DROP TABLE IF EXISTS mr_shipping;
CREATE EXTERNAL TABLE mr_shipping (order_region STRING, order_count INT, avg_actual_days DOUBLE)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' LOCATION '/datalake/curated/mapreduce/shipping';

SELECT 'C1 Sales by category: MR vs Hive Q1' AS test,
       COUNT(m.category_id) AS mr_rows, COUNT(h.category_id) AS hive_rows,
       SUM(IF(ABS(m.gross_sales - h.gross_sales) <= 0.01 AND ABS(m.net_sales - h.net_sales) <= 0.01, 1, 0)) AS matching_rows,
       IF(COUNT(*) = SUM(IF(ABS(m.gross_sales - h.gross_sales) <= 0.01 AND ABS(m.net_sales - h.net_sales) <= 0.01, 1, 0)),
          'PASS', 'FAIL') AS result
FROM mr_sales m FULL OUTER JOIN q1_sales_by_category h
  ON m.category_id = h.category_id AND m.category_name = h.category_name;

SELECT 'C2 Late % by shipping mode: MR vs Hive Q2b' AS test,
       COUNT(m.shipping_mode) AS mr_rows, COUNT(h.shipping_mode) AS hive_rows,
       SUM(IF(m.eligible_orders = h.eligible_orders AND m.late_orders = h.late_orders
              AND ABS(m.late_percent - h.late_percent) <= 0.01, 1, 0)) AS matching_rows,
       IF(COUNT(*) = SUM(IF(m.eligible_orders = h.eligible_orders AND m.late_orders = h.late_orders
              AND ABS(m.late_percent - h.late_percent) <= 0.01, 1, 0)), 'PASS', 'FAIL') AS result
FROM mr_late m FULL OUTER JOIN q2b_late_delivery_by_mode h ON m.shipping_mode = h.shipping_mode;

SELECT 'C3 Avg shipping days by region: MR vs Hive Q3' AS test,
       COUNT(m.order_region) AS mr_rows, COUNT(h.order_region) AS hive_rows,
       SUM(IF(m.order_count = h.order_count AND ABS(m.avg_actual_days - h.avg_actual_days) <= 0.01, 1, 0)) AS matching_rows,
       IF(COUNT(*) = SUM(IF(m.order_count = h.order_count AND ABS(m.avg_actual_days - h.avg_actual_days) <= 0.01, 1, 0)),
          'PASS', 'FAIL') AS result
FROM mr_shipping m FULL OUTER JOIN q3_shipping_time_by_region h ON m.order_region = h.order_region;

SELECT 'C4 Profit by category: MR vs Hive Q5' AS test,
       COUNT(m.category_id) AS mr_rows, COUNT(h.category_id) AS hive_rows,
       SUM(IF(ABS(m.profit - h.profit) <= 0.01, 1, 0)) AS matching_rows,
       IF(COUNT(*) = SUM(IF(ABS(m.profit - h.profit) <= 0.01, 1, 0)), 'PASS', 'FAIL') AS result
FROM mr_profit m FULL OUTER JOIN q5_profit_by_category h
  ON m.category_id = h.category_id AND m.category_name = h.category_name;

SELECT 'C5 Electronics ids 13 and 37 kept separate' AS test,
       COUNT(*) AS rows_found, IF(COUNT(*) = 2, 'PASS', 'FAIL') AS result
FROM mr_sales WHERE category_name = 'Electronics';
