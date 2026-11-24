-- =====================================================================
-- Member 8 - Script 04: save each result to the Data Lake curated zone
-- Output: /datalake/curated/hive/<query>/000000_0  (comma-separated)
-- Run after Script 03 with:  hive -f 04_export_results.hql
-- Then check with:  hadoop fs -ls -R /datalake/curated/hive
-- =====================================================================
USE dataco_dl;

INSERT OVERWRITE DIRECTORY '/datalake/curated/hive/q1_sales_by_category'
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
SELECT * FROM q1_sales_by_category;

INSERT OVERWRITE DIRECTORY '/datalake/curated/hive/q2a_late_delivery_overall'
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
SELECT * FROM q2a_late_delivery_overall;

INSERT OVERWRITE DIRECTORY '/datalake/curated/hive/q2b_late_delivery_by_mode'
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
SELECT * FROM q2b_late_delivery_by_mode;

INSERT OVERWRITE DIRECTORY '/datalake/curated/hive/q3_shipping_time_by_region'
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
SELECT * FROM q3_shipping_time_by_region;

INSERT OVERWRITE DIRECTORY '/datalake/curated/hive/q4_top10_products'
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
SELECT * FROM q4_top10_products;

INSERT OVERWRITE DIRECTORY '/datalake/curated/hive/q5_profit_by_category'
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
SELECT * FROM q5_profit_by_category;
