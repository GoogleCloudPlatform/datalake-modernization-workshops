from pyspark import SparkContext
from pyspark.sql import SQLContext
from pyspark.sql.types import (
    StructType,
    StructField,
    TimestampType,
    DoubleType,
    IntegerType,
)
from pyspark.sql.functions import (
    col,
    avg,
    sum,
    hour,
    countDistinct,
    from_unixtime,
    unix_timestamp,
)


sc = SparkContext()
sqlContext = SQLContext(sc)


schema = StructType(
    [
        StructField("delivery_time", TimestampType(), True),
        StructField("timestamp", TimestampType(), True),
        StructField("distance", DoubleType(), True),
        StructField("distribution_center_id", IntegerType(), True),
        StructField("product_id", IntegerType(), True),
        StructField("quantity_to_delivery", IntegerType(), True),
        StructField("delivery_cost", IntegerType(), True),
    ]
)


hdfs_path = "hdfs://quickstart.cloudera:8020/user/hive/warehouse/google.db/product_deliveries_hive/"

df = sqlContext.read.parquet(hdfs_path)


df_hourly = (
    df.withColumn(
        "delivery_hour",
        from_unixtime(
            unix_timestamp("delivery_time", "yyyy-MM-dd HH"), "yyyy-MM-dd HH"
        ),
    )
    .groupBy("delivery_hour")
    .agg(
        countDistinct("delivery_time").alias("num_deliveries"),
        countDistinct("product_id").alias("unique_products"),
    )
)

df_hourly.show()
output_path = (
    "hdfs://quickstart.cloudera:8020/user/hive/warehouse/google.db/hourly_deliveries"
)
df_hourly.write.parquet(output_path, mode="overwrite")
