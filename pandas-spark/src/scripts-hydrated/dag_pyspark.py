# pySPARK Airflow DAG
# This script calls dataproc spark serverless


import os
from airflow.models import Variable
from datetime import datetime
from airflow import models
from airflow.providers.google.cloud.operators.dataproc import (DataprocCreateBatchOperator,DataprocGetBatchOperator)
from datetime import datetime
from airflow.utils.dates import days_ago
import string
import random 

# .......................................................
# Variables
# .......................................................

random_value = ''.join(random.choices(string.digits, k = 10))
batch_id = "batch-process-{}".format(random_value)


# .......................................................
# DAG
# .......................................................

with models.DAG(
    "batch-process-dag",
    schedule_interval=None,
    start_date = days_ago(2),
    catchup=False,
) as scoringDAG:
        
    pyspark_batch_process_step = DataprocCreateBatchOperator(
        task_id="batch-process-pyspark",
        project_id= "{{ dag_run.conf['project_id'] }}",
        region= "{{ dag_run.conf['region'] }}",
        batch={
            "pyspark_batch": {
            "main_python_file_uri": "gs://spark-stage-{}/pyspark-batch-process.py".format("{{ dag_run.conf['project_id'] }}"),
        "args": ["--project_id={}".format("{{ dag_run.conf['project_id'] }}"), \
            "--scratch_gcs_bucket={}".format("{{ dag_run.conf['scratch_gcs_bucket'] }}"), \
            "--target_dataset_id={}".format("{{ dag_run.conf['target_dataset_id'] }}") ],
        "jar_file_uris": [ "{{ dag_run.conf['bq_connector_jar'] }}" ]
    },
    "environment_config":{
        "execution_config":{
            "service_account": "{{ dag_run.conf['spark_sa'] }}",
            "subnetwork_uri": "{{ dag_run.conf['subnet'] }}"
            },
        "peripherals_config": {
            "metastore_service": "projects/{}/locations/{}/services/{}".format("{{ dag_run.conf['project_id'] }}","{{ dag_run.conf['region'] }}","{{ dag_run.conf['metastore'] }}"),
            "spark_history_server_config": {
                "dataproc_cluster": "projects/{}/regions/{}/clusters/{}".format("{{ dag_run.conf['project_id'] }}","{{ dag_run.conf['region'] }}","{{ dag_run.conf['phs'] }}")
                }
            }
        }
},  
        batch_id=batch_id 
    )
    pyspark_batch_process_step
