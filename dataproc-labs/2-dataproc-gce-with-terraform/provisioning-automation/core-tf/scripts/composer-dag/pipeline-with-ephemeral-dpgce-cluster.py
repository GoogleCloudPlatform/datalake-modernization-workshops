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
# This script orchestrates the execution of the cell tower anomaly detection jobs 
# in dataproc GCE cluster created at DAG execution time
# ======================================================================================

import os
from datetime import datetime
from google.protobuf.duration_pb2 import Duration
import string
import random

from airflow.models import Variable
from airflow import models
from airflow.providers.google.cloud.operators.dataproc import (
    DataprocCreateClusterOperator,
    DataprocDeleteClusterOperator,
    DataprocSubmitJobOperator,
)
from airflow.utils.dates import days_ago
from airflow.utils import trigger_rule


# Read environment variables into local variables
project_id = models.Variable.get("project_id")
project_nbr = models.Variable.get("project_nbr")
region = models.Variable.get("region")
code_bucket=Variable.get("code_bucket")
bq_dataset=Variable.get("bq_dataset")
database_name=Variable.get("metastore_db")
subnet_uri=Variable.get("subnet_uri")
umsa=Variable.get("umsa")

# Other variables
dag_name="cell-tower-anomaly-detection-with-ephemeral-dpgce-cluster"
dpgce_cluster_name="dpgce-cluster-ephemeral-"+project_nbr
dpgce_cluster_bucket_name="dpgce-spark-bucket-"+project_nbr
dpgce_cluster_region=region
dpgce_cluster_master_type='n1-standard-4'
dpgce_cluster_worker_type='n2-standard-4'
dpgce_cluster_image_version='2.0-debian10'
dpms_nm="dpgce-metastore-"+project_nbr
dpms_resource_uri="projects/"+project_id+"/locations/"+region+"/services/"+dpms_nm
phs_bucket_name="dpgce-sphs-"+project_nbr
phs_conf = {"spark:spark.history.fs.logDirectory": "gs://"+phs_bucket_name+"/*/spark-job-history",
"spark:spark.eventLog.dir":"gs://"+phs_bucket_name+"/events/spark-job-history",
"yarn:yarn.nodemanager.remote-app-log-dir":"gs://"+phs_bucket_name+"/yarn-logs",
"mapred:mapreduce.jobhistory.done-dir":"gs://"+phs_bucket_name+"/events/mapreduce-job-history/done",
"mapred:mapreduce.jobhistory.intermediate-done-dir":"gs://"+phs_bucket_name+"/events/mapreduce-job-history/intermediate-done"
}

#Set cluster timeout duration
duration = Duration()
duration.seconds = 3600

# PySpark script files in GCS, of the individual Spark applications in the pipeline
curate_customer_script= "gs://"+code_bucket+"/scripts/pyspark/curate_customer_data.py"
curate_telco_performance_metrics_script= "gs://"+code_bucket+"/scripts/pyspark/curate_telco_performance_data.py"
kpis_by_customer_script= "gs://"+code_bucket+"/scripts/pyspark/kpis_by_customer.py"
kpis_by_cell_tower_script= "gs://"+code_bucket+"/scripts/pyspark/kpis_by_cell_tower.py"

# This is to add a random suffix to the serverless Spark batch ID that needs to be unique each run
# ...Define the random module
S = 10  # number of characters in the string.
# call random.choices() string module to find the string in Uppercase + numeric data.
ran = ''.join(random.choices(string.digits, k = S))

job_id_prefix = "cell-tower-anomaly-detection-ephemeral-dpgce-cluster-"+str(ran)

Curate_Customer_Master_Data_Job_Config = {
    "reference": {"job_id": job_id_prefix + "-curate-customer","project_id": project_id},
    "placement": {"cluster_name": dpgce_cluster_name},
    "pyspark_job": {"main_python_file_uri": curate_customer_script,
                    "jar_file_uris": [
                        "gs://spark-lib/bigquery/spark-bigquery-with-dependencies_2.12-0.22.2.jar"
                    ],
                    "args": [
                    code_bucket,
                    database_name
                    ]
                    },
}

Curate_Telco_Performance_Metrics_Job_Config = {
    "reference": {"job_id": job_id_prefix + "-curate-tower-metrics","project_id": project_id},
    "placement": {"cluster_name": dpgce_cluster_name},
    "pyspark_job": {"main_python_file_uri": curate_telco_performance_metrics_script,
                    "jar_file_uris": [
                        "gs://spark-lib/bigquery/spark-bigquery-with-dependencies_2.12-0.22.2.jar"
                    ],
                    "args": [
                    code_bucket,
                    database_name]
                    },
}

Calc_KPIs_By_Customer_Job_Config = {
    "reference": {"job_id": job_id_prefix + "-kpis-customer","project_id": project_id},
    "placement": {"cluster_name": dpgce_cluster_name},
    "pyspark_job": {"main_python_file_uri": kpis_by_customer_script,
                    "jar_file_uris": [
                        "gs://spark-lib/bigquery/spark-bigquery-with-dependencies_2.12-0.22.2.jar"
                    ],
                    "args": [
                    project_id,
                    bq_dataset,
                    code_bucket,
                    database_name]
                    },
}

Calc_KPIs_By_Cell_Tower_Job_Config = {
    "reference": {"job_id": job_id_prefix  + "-kpis-tower","project_id": project_id},
    "placement": {"cluster_name": dpgce_cluster_name},
    "pyspark_job": {"main_python_file_uri": kpis_by_cell_tower_script,
                    "jar_file_uris": [
                        "gs://spark-lib/bigquery/spark-bigquery-with-dependencies_2.12-0.22.2.jar"
                    ],
                    "args": [
                    project_id,
                    bq_dataset,
                    code_bucket,
                    database_name]
                    },
}


with models.DAG(
    dag_name,
    schedule_interval=None,
    start_date = days_ago(2),
    catchup=False,
) as dag_dataproc_cluster_job:
    create_dpgce_cluster = DataprocCreateClusterOperator(
        task_id="Create_Dataproc_GCE_Cluster",
        project_id=project_id,
        cluster_name=dpgce_cluster_name,
        region=dpgce_cluster_region,
        cluster_config={
            "gce_cluster_config" : {
                "service_account": umsa + "@" + project_id + ".iam.gserviceaccount.com",
                "subnetwork_uri": subnet_uri,
                "service_account_scopes": ["https://www.googleapis.com/auth/cloud-platform"],
                "internal_ip_only": True
            },
            "master_config": {
                "num_instances": 1,
                "machine_type_uri": dpgce_cluster_master_type,
                "disk_config": {"boot_disk_type": "pd-standard", "boot_disk_size_gb": 1024},
            },
            "worker_config": {
                "num_instances": 2,
                "machine_type_uri": dpgce_cluster_worker_type,
                "disk_config": {"boot_disk_type": "pd-standard", "boot_disk_size_gb": 1024},
            },
            "software_config": {
                "image_version": dpgce_cluster_image_version,
                "properties": phs_conf
            },
            "lifecycle_config": {
                "idle_delete_ttl": duration,
            },
            "metastore_config": {
                "dataproc_metastore_service": dpms_resource_uri
            },
            "endpoint_config": {
                "enable_http_port_access": True
            }
        }
    )
    curate_customer_master = DataprocSubmitJobOperator(
        task_id="Curate_Customer_Master_Data",
        project_id=project_id,
        region=region,
        job=Curate_Customer_Master_Data_Job_Config,
    )
    curate_telco_performance_metrics = DataprocSubmitJobOperator(
        task_id="Curate_Telco_Performance_Metrics",
        project_id=project_id,
        region=region,
        job=Curate_Telco_Performance_Metrics_Job_Config,
    )
    calc_kpis_by_customer = DataprocSubmitJobOperator(
        task_id="Calc_KPIs_By_Customer",
        project_id=project_id,
        region=region,
        job=Calc_KPIs_By_Customer_Job_Config,
    )
    calc_kpis_by_cell_tower = DataprocSubmitJobOperator(
        task_id="Calc_KPIs_By_Cell_Tower",
        project_id=project_id,
        region=region,
        job=Calc_KPIs_By_Cell_Tower_Job_Config,
    )
    delete_cluster=DataprocDeleteClusterOperator(
        task_id="Delete_DPGCE_Cluster",
        project_id=project_id,
        region=dpgce_cluster_region,
        cluster_name=dpgce_cluster_name,
        trigger_rule=trigger_rule.TriggerRule.ALL_DONE
    )

    create_dpgce_cluster >> curate_customer_master
    curate_customer_master >> curate_telco_performance_metrics
    curate_telco_performance_metrics >> calc_kpis_by_customer
    curate_telco_performance_metrics >> calc_kpis_by_cell_tower
    calc_kpis_by_customer >> delete_cluster
    calc_kpis_by_cell_tower >> delete_cluster