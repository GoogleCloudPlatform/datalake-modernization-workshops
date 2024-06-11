USE google;
CREATE EXTERNAL TABLE IF NOT EXISTS hourly_deliveries (
    delivery_hour STRING,
    num_deliveries BIGINT,
    unique_products BIGINT
)
STORED AS PARQUET
LOCATION 'hdfs://quickstart.cloudera:8020/user/hive/warehouse/google.db/hourly_deliveries';