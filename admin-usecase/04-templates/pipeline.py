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
# This script orchestrates the execution of the wikipedia page views job
# ======================================================================================

import os
from airflow.models import Variable
from datetime import datetime
from airflow import models
from airflow.providers.google.cloud.operators.dataproc import (DataprocCreateBatchOperator,DataprocGetBatchOperator)
from datetime import datetime
from airflow.utils.dates import days_ago
import string
import random

# Read environment variables into local variables
project_id = models.Variable.get("project_id")
region = models.Variable.get("region")
subnet=models.Variable.get("subnet")
phs_server=Variable.get("phs")
code_bucket=Variable.get("code_bucket")
umsa=Variable.get("umsa")

name = "ADMIN_ID"

# Define DAG name
dag_name= name+"_wikipedia_page_views-serverless"

# User Managed Service Account FQN
service_account_id= umsa+"@"+project_id+".iam.gserviceaccount.com"

# PySpark script files in GCS, of the Spark application in the pipeline
page_views_count_script= "gs://"+code_bucket+"/wikipedia-page-view/01-scripts-and-config/pyspark/page_view_autoscaling.py"


# This is to add a random suffix to the serverless Spark batch ID that needs to be unique each run
# ...Define the random module
S = 10  # number of characters in the string.
# call random.choices() string module to find the string in Uppercase + numeric data.
ran = ''.join(random.choices(string.digits, k = S))

BATCH_ID = name+"-wikipedia-page-views-"+str(ran)

BATCH_CONFIG = {
    "pyspark_batch": {
        "main_python_file_uri": page_views_count_script,
        "jar_file_uris": [
      "gs://spark-lib/bigquery/spark-bigquery-with-dependencies_2.12-0.22.2.jar"
    ]
    },
    "environment_config":{
        "execution_config":{
              "service_account": service_account_id,
            "subnetwork_uri": subnet
            },
        "peripherals_config": {
            "spark_history_server_config": {
                "dataproc_cluster": f"projects/{project_id}/regions/{region}/clusters/{phs_server}"
                }
            },
        },
}

with models.DAG(
    dag_name,
    schedule_interval=None,
    start_date = days_ago(2),
    catchup=False,
) as dag_serverless_batch:
    wikipedia_page_views = DataprocCreateBatchOperator(
        task_id="Wikipedia_Page_Views_Count",
        project_id=project_id,
        region=region,
        batch=BATCH_CONFIG,
        batch_id=BATCH_ID,
    )

    wikipedia_page_views
