# pySPARK batch process
# 
# This script performs data preprocessing from BigQuery
# and persists back to BigQuery


import sys,logging,argparse
import pyspark
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from datetime import datetime


def batch_data_process(logger,args):
    
    project_id = args.project_id
    target_dataset_id = args.target_dataset_id
    scratch_gcs_bucket = args.scratch_gcs_bucket
    
    
    logger.info("Starting execution")
    logger.info("The datetime now is - {}".format(datetime.now().strftime("%Y%m%d%H%M%S")))
    logger.info(" ")
    logger.info("INPUT PARAMETERS-")
    logger.info("project_id={}".format(project_id))
    logger.info("target_dataset_id={}".format(target_dataset_id))
    
    try:
        logger.info('Initializing spark & spark configs')
        spark = SparkSession.builder.getOrCreate()
        spark.conf.set("parentProject", project_id)
        spark.conf.set("temporaryGcsBucket", scratch_gcs_bucket)

        logger.info('Read source data')
        spark_df = spark.read.format('bigquery').option('table','bigquery-public-data:chicago_crime.crime').load()

        logger.info('Transform source data')
        spark_count_arrest = spark_df.groupby("primary_type","arrest").count().orderBy(col("count").desc())
        spark_heavy_operation = spark_df.join(spark_df,on="unique_key").join(spark_df,on="unique_key").join(spark_df,on="unique_key").join(spark_df,on="unique_key").join(spark_df,on="unique_key")
        logger.info('Persist to BQ')
        spark_count_arrest.write.format('bigquery') \
        .mode("overwrite")\
        .option('table', "{}.spark_count_arrest".format(target_dataset_id)) \
        .save()
      

    except RuntimeError as coreError:
            logger.error(coreError)
    else:
        logger.info('Successfully completed data procesing!')


def parse_arguments():

    argsParser = argparse.ArgumentParser()
    argsParser.add_argument(
        '--project_id',
        help='The project id',
        type=str,
        required=True)
    argsParser.add_argument(
        '--target_dataset_id',
        help='The dataset  id',
        type=str,
        required=True)
    argsParser.add_argument(
        '--scratch_gcs_bucket',
        help='The GCS bucket',
        type=str,
        required=True)         
    return argsParser.parse_args()



def get_logger():

    logFormatter = logging.Formatter('%(asctime)s - %(filename)s - %(levelname)s - %(message)s')
    logger = logging.getLogger("data_lake_labs")
    logger.setLevel(logging.INFO)
    logger.propagate = False
    logStreamHandler = logging.StreamHandler(sys.stdout)
    logStreamHandler.setFormatter(logFormatter)
    logger.addHandler(logStreamHandler)
    return logger


if __name__ == "__main__":
    logger = get_logger()
    args = parse_arguments()
    batch_data_process(logger,args)