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
from airflow.providers.google.cloud.operators.dataproc import (DataprocCreateBatchOperator,DataprocGetBatchOperator,DataprocSubmitJobOperator)
from datetime import datetime
from airflow.utils.dates import days_ago
import string
import random

# Read environment variables into local variables
project_id = models.Variable.get("project_id")
region = models.Variable.get("region")
code_bucket=Variable.get("code_bucket")
cluster_name=Variable.get("dgce_cluster")

name = "ADMIN_ID"

# Define DAG name
dag_name= name+"_wikipedia_page_views-cluster"

# PySpark script files in GCS, of the Spark application in the pipeline
page_views_count_script= "gs://"+code_bucket+"/wikipedia-page-view/01-scripts-and-config/pyspark/page_view_autoscaling.py"


# This is to add a random suffix to the serverless Spark batch ID that needs to be unique each run
# ...Define the random module
S = 10  # number of characters in the string.
# call random.choices() string module to find the string in Uppercase + numeric data.
ran = ''.join(random.choices(string.digits, k = S))

BATCH_ID = name+"-wikipedia-page-views-"+str(ran)

BATCH_CONFIG = {
    "reference": {"job_id": BATCH_ID,"project_id": project_id},
    "placement": {"cluster_name": cluster_name},
    "pyspark_job": {"main_python_file_uri": page_views_count_script,
                    "jar_file_uris": [
                        "gs://spark-lib/bigquery/spark-bigquery-with-dependencies_2.12-0.22.2.jar"
                    ],
                    },
}

with models.DAG(
    dag_name,
    schedule_interval=None,
    start_date = days_ago(2),
    catchup=False,
) as dag_serverless_batch:
    wikipedia_page_views = DataprocSubmitJobOperator(
        task_id="Wikipedia_Page_Views_Count",
        project_id=project_id,
        region=region,
        job=BATCH_CONFIG
        )

    wikipedia_page_views
