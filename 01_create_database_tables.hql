-- =====================================================================
-- ISIT312 Big Data Project - Member 8: Hive and HQL
-- Script 01: create the Hive database and the two external tables
-- Input (from Member 6): /datalake/cleaned/items/   and   /datalake/cleaned/orders/
-- Columns follow Member 4's cleaned files (snake_case, UTF-8, no quoted fields)
-- Run with:  hive -f 01_create_database_tables.hql
-- =====================================================================

CREATE DATABASE IF NOT EXISTS dataco_dl
COMMENT 'Caspian Distribution FZE supply-chain Data Lake (DataCo public dataset)';

USE dataco_dl;

-- EXTERNAL: Hive only stores the table definition in the Metastore.
-- The data stays in Member 6's HDFS folder and DROP TABLE never deletes it.

-- ---------------------------------------------------------------------
-- Item-level table: one row per order item (180,519 rows, 40 columns)
-- Used for sales, product and profit queries
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS order_items;
CREATE EXTERNAL TABLE order_items (
    `type`                       STRING    COMMENT 'Payment type',
    days_for_shipping_real       INT       COMMENT 'Actual shipping days',
    days_for_shipment_scheduled  INT       COMMENT 'Scheduled shipping days',
    delivery_status              STRING,
    late_delivery_risk           INT       COMMENT '1 = late, 0 = not late',
    category_id                  INT,
    category_name                STRING,
    customer_city                STRING,
    customer_country             STRING,
    customer_id                  INT,
    customer_segment             STRING,
    customer_state               STRING,
    customer_zipcode             STRING    COMMENT 'Kept as text',
    department_id                INT,
    department_name              STRING,
    latitude                     DOUBLE,
    longitude                    DOUBLE,
    market                       STRING,
    order_city                   STRING,
    order_country                STRING,
    order_date                   TIMESTAMP,
    order_id                     INT,
    order_item_discount          DOUBLE,
    order_item_discount_rate     DOUBLE,
    order_item_id                INT,
    order_item_product_price     DOUBLE,
    order_item_profit_ratio      DOUBLE,
    order_item_quantity          INT,
    sales                        DOUBLE    COMMENT 'Gross sales before discount',
    order_item_total             DOUBLE    COMMENT 'Net sales after discount',
    order_profit_per_order       DOUBLE    COMMENT 'Profit recorded on this item row',
    order_region                 STRING,
    order_state                  STRING,
    order_status                 STRING,
    order_zipcode                STRING    COMMENT 'Mostly empty, kept as text',
    product_card_id              INT,
    product_name                 STRING,
    product_price                DOUBLE,
    shipping_date                TIMESTAMP,
    shipping_mode                STRING
)
COMMENT 'Cleaned DataCo order items (Member 4)'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
STORED AS TEXTFILE
LOCATION '/datalake/cleaned/items/'
TBLPROPERTIES ('skip.header.line.count'='1');

-- ---------------------------------------------------------------------
-- Order-level table: one row per order (65,752 rows, 17 columns)
-- Used for delivery and shipping-time queries, so each order counts once
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS orders;
CREATE EXTERNAL TABLE orders (
    order_id                     INT,
    order_date                   TIMESTAMP,
    shipping_date                TIMESTAMP,
    shipping_mode                STRING,
    delivery_status              STRING,
    late_delivery_risk           INT,
    days_for_shipping_real       INT,
    days_for_shipment_scheduled  INT,
    order_status                 STRING,
    customer_id                  INT,
    customer_segment             STRING,
    market                       STRING,
    order_region                 STRING,
    order_country                STRING,
    order_state                  STRING,
    order_city                   STRING,
    order_zipcode                STRING
)
COMMENT 'Cleaned DataCo orders, one row per order (Member 4)'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
STORED AS TEXTFILE
LOCATION '/datalake/cleaned/orders/'
TBLPROPERTIES ('skip.header.line.count'='1');

SHOW TABLES;
DESCRIBE FORMATTED order_items;
