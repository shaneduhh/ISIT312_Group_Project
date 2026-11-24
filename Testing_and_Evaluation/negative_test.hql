SET hive.cli.print.header=true;
SET hive.resultset.use.unique.column.names=false;
SET hive.auto.convert.join=false;
USE dataco_dl;

DROP TABLE IF EXISTS neg_orders_missing_row;
CREATE EXTERNAL TABLE neg_orders_missing_row LIKE orders LOCATION '/tmp/m9_negative/missing_row';
SELECT 'N1 order rows = 65752 (one row deleted)' AS test, COUNT(order_id) AS actual,
       IF(COUNT(order_id) = 65752, 'PASS', 'FAIL') AS result FROM neg_orders_missing_row;

DROP TABLE IF EXISTS neg_mr_late;
CREATE EXTERNAL TABLE neg_mr_late (shipping_mode STRING, eligible_orders INT, late_orders INT, late_percent DOUBLE)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' LOCATION '/tmp/m9_negative/mr_late_bad';
SELECT 'N3 Late by mode: damaged MR vs Hive Q2b' AS test,
       COUNT(m.shipping_mode) AS mr_rows, COUNT(h.shipping_mode) AS hive_rows,
       SUM(IF(m.eligible_orders = h.eligible_orders AND m.late_orders = h.late_orders, 1, 0)) AS matching_rows,
       IF(COUNT(*) = SUM(IF(m.eligible_orders = h.eligible_orders AND m.late_orders = h.late_orders, 1, 0)),
          'PASS', 'FAIL') AS result
FROM neg_mr_late m FULL OUTER JOIN q2b_late_delivery_by_mode h ON m.shipping_mode = h.shipping_mode;

DROP TABLE neg_orders_missing_row;
DROP TABLE neg_mr_late;
