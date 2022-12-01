'''
 Copyright 2022 Google LLC
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
'''

# ======================================================================================
# ABOUT
# In this PySpark script, we augment the Telecom data with curated customer data (prior
# job), curate it and persist to GCS
# ======================================================================================

import configparser
from datetime import datetime
import os
import json
from pyspark.sql import SparkSession
from pyspark.sql.functions import udf, col, substring, lit, when, avg
from pyspark.sql import functions as F
from pyspark.sql.functions import input_file_name
import random
from pyspark.sql.types import *
from pyspark.sql.functions import year, month, dayofmonth, hour, weekofyear, dayofweek, date_format
from pyspark import SparkContext, SparkConf, SQLContext
from google.cloud import storage
import sys


# Parse arguments
sourceBucketNm=sys.argv[1]
databaseNm=sys.argv[2]
user_name=sys.argv[3]

# Source data definition
telcoCustomerChurnDataDir="gs://"+sourceBucketNm+"/cell-tower-anomaly-detection/01-datasets/telecom_customer_churn_data.csv"

# Output directory declaration
outputGCSURI="gs://"+sourceBucketNm+"/cell-tower-anomaly-detection/01-datasets/"+user_name+"/output_data"

# Get or create a Spark session
spark =SparkSession.builder.appName("Curate-Cell_Tower-Performance-Data").getOrCreate()

spark.sql(""" USE {}""".format(databaseNm))

# Read the curated customer data (blended with services threshold data) from GCS
curatedCustomerDataDF = spark.sql(""" select * from customer_augmented """)

# Read the telecom customer churn data from GCS
telecomCustomerChurnRawDataDF = spark.read.format("csv").option("header", True).option("inferschema",True).load(telcoCustomerChurnDataDir)
telecomCustomerChurnRawDataDF.printSchema()

# Subset the telecom customer churn/performance data for relevant attributes
# ... Create subset
telecomCustomerChurnSubsetDF = telecomCustomerChurnRawDataDF.selectExpr("roam_Mean","change_mou","drop_vce_Mean","drop_dat_Mean","blck_vce_Mean","blck_dat_Mean","plcd_vce_Mean","plcd_dat_Mean","comp_vce_Mean","comp_dat_Mean","peak_vce_Mean","peak_dat_Mean","mou_peav_Mean","mou_pead_Mean","opk_vce_Mean","opk_dat_Mean","mou_opkv_Mean","mou_opkd_Mean","drop_blk_Mean","callfwdv_Mean","callwait_Mean","churn","months","uniqsubs","actvsubs","area","dualband","forgntvl","Customer_ID")
# ... Create a column called customer_ID_Short that is a substring of the original Customer_ID
telecomCustomerChurnFinalDF=telecomCustomerChurnSubsetDF.withColumn('customer_ID_Short', substring('Customer_ID', 4,7))
# ... Rename the Customer_ID column, customer_ID_original
telecomCustomerChurnFinalDF=telecomCustomerChurnFinalDF.withColumnRenamed('Customer_ID', 'customer_ID_original')
# ... Rename the newly added customer_ID_Short column, customer_ID
telecomCustomerChurnFinalDF=telecomCustomerChurnFinalDF.withColumnRenamed('customer_ID_Short', 'customer_ID')
# ... Quick visual
telecomCustomerChurnFinalDF.show(10,truncate=False)

# Join the curated customer data with the telecom network performance data based on customer ID
consolidatedDataDF = curatedCustomerDataDF.join(telecomCustomerChurnFinalDF, curatedCustomerDataDF.customerID ==  telecomCustomerChurnFinalDF.customer_ID, "inner").drop(telecomCustomerChurnFinalDF.customer_ID).drop(telecomCustomerChurnFinalDF.churn)
consolidatedDataDF.show(truncate=False)

# Persist the augmented telecom tower performance data to metastore by creating a table in metastore
spark.sql("""DROP TABLE IF EXISTS telco_performance_augmented """);

consolidatedDataDF.write.mode("overwrite").option("path", os.path.join(outputGCSURI, "telco_performance_augmented")).saveAsTable("{}.telco_performance_augmented".format(databaseNm))
