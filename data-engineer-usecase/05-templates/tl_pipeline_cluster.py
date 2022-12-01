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
# This script orchestrates the execution of the cell tower anomany detection jobs in dataproc cluster
# as a pipeline/workflow with dependencies managed
# ======================================================================================

import os
from airflow.models import Variable
from datetime import datetime
from airflow import models
from airflow.providers.google.cloud.operators.dataproc import (DataprocCreateBatchOperator,DataprocGetBatchOperator,DataprocSubmitJobOperator)
from datetime import datetime
from airflow.utils.dates import days_ago
import string
import random

# Read environment variables into local variables
project_id = models.Variable.get("project_id")
region = models.Variable.get("region")
code_bucket=Variable.get("code_and_data_bucket")
bq_dataset=Variable.get("bq_dataset")
database_name=Variable.get("metastore_db")

name = 'USER_ID'

# Define DAG name
dag_name= name+"-cell-tower-anomaly-detection-cluster"
dgce_cluster_name=name+"-dp-gce-cluster"

# PySpark script files in GCS, of the individual Spark applications in the pipeline
curate_customer_script= "gs://"+code_bucket+"/cell-tower-anomaly-detection/00-scripts-and-config/pyspark/curate_customer_data.py"
curate_telco_performance_metrics_script= "gs://"+code_bucket+"/cell-tower-anomaly-detection/00-scripts-and-config/pyspark/curate_telco_performance_data.py"
kpis_by_customer_script= "gs://"+code_bucket+"/cell-tower-anomaly-detection/00-scripts-and-config/pyspark/kpis_by_customer.py"
kpis_by_cell_tower_script= "gs://"+code_bucket+"/cell-tower-anomaly-detection/00-scripts-and-config/pyspark/kpis_by_cell_tower.py"

# This is to add a random suffix to the serverless Spark batch ID that needs to be unique each run
# ...Define the random module
S = 10  # number of characters in the string.
# call random.choices() string module to find the string in Uppercase + numeric data.
ran = ''.join(random.choices(string.digits, k = S))

BATCH_ID = name+"-cell-tower-anomaly-detection-"+str(ran)

BATCH_CONFIG1 = {
    "reference": {"job_id": BATCH_ID,"project_id": project_id},
    "placement": {"cluster_name": dgce_cluster_name},
    "pyspark_job": {"main_python_file_uri": curate_customer_script,
                    "jar_file_uris": [
                        "gs://spark-lib/bigquery/spark-bigquery-with-dependencies_2.12-0.22.2.jar"
                    ],
                    "args": [
                    code_bucket,
                    database_name+"_"+name,
                    name
                    ]
                    },
}

BATCH_CONFIG2 = {
    "reference": {"job_id": BATCH_ID,"project_id": project_id},
    "placement": {"cluster_name": dgce_cluster_name},
    "pyspark_job": {"main_python_file_uri": curate_telco_performance_metrics_script,
                    "jar_file_uris": [
                        "gs://spark-lib/bigquery/spark-bigquery-with-dependencies_2.12-0.22.2.jar"
                    ],
                    "args": [
                    code_bucket,
                    database_name+"_"+name,
                    name]
                    },
}

BATCH_CONFIG3 = {
    "reference": {"job_id": BATCH_ID,"project_id": project_id},
    "placement": {"cluster_name": dgce_cluster_name},
    "pyspark_job": {"main_python_file_uri": kpis_by_customer_script,
                    "jar_file_uris": [
                        "gs://spark-lib/bigquery/spark-bigquery-with-dependencies_2.12-0.22.2.jar"
                    ],
                    "args": [
                    project_id,
                    bq_dataset,
                    code_bucket,
                    database_name+"_"+name,
                    name]
                    },
}

BATCH_CONFIG4 = {
    "reference": {"job_id": BATCH_ID,"project_id": project_id},
    "placement": {"cluster_name": dgce_cluster_name},
    "pyspark_job": {"main_python_file_uri": kpis_by_cell_tower_script,
                    "jar_file_uris": [
                        "gs://spark-lib/bigquery/spark-bigquery-with-dependencies_2.12-0.22.2.jar"
                    ],
                    "args": [
                    project_id,
                    bq_dataset,
                    code_bucket,
                    database_name+"_"+name,
                    name]
                    },
}



with models.DAG(
    dag_name,
    schedule_interval=None,
    start_date = days_ago(2),
    catchup=False,
) as dag_dataproc_cluster_job:
    curate_customer_master = DataprocSubmitJobOperator(
        task_id="Curate_Customer_Master_Data",
        project_id=project_id,
        region=region,
        job=BATCH_CONFIG1,
    )
    curate_telco_performance_metrics = DataprocSubmitJobOperator(
        task_id="Curate_Telco_Performance_Metrics",
        project_id=project_id,
        region=region,
        job=BATCH_CONFIG2,
    )
    calc_kpis_by_customer = DataprocSubmitJobOperator(
        task_id="Calc_KPIs_By_Customer",
        project_id=project_id,
        region=region,
        job=BATCH_CONFIG3,
    )
    calc_kpis_by_cell_tower = DataprocSubmitJobOperator(
        task_id="Calc_KPIs_By_Cell_Tower",
        project_id=project_id,
        region=region,
        job=BATCH_CONFIG4,
    )

    curate_customer_master >> curate_telco_performance_metrics
    curate_telco_performance_metrics >> calc_kpis_by_customer
    curate_telco_performance_metrics >> calc_kpis_by_cell_tower
