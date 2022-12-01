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

import datetime
import os
from airflow import models
from airflow.providers.google.cloud.operators import dataproc
import string
import random

# Read environment variables into local variables
project_id = models.Variable.get("project_id")
region = models.Variable.get("region")
output_file_bucket=models.Variable.get("output_file_bucket")

#Replace with your name within '' below in lowercase and no numbers or special characters
name = 'USER_ID'

dag_name= name+"-map-reduce-word-count"
dgce_cluster_name=name+"-dp-gce-cluster"

# Input file for Map Reduce word count job.
input_file = 'gs://pub/shakespeare/rose.txt'

# Output file for Cloud Dataproc job.
output_file = os.path.join('gs://', output_file_bucket, 'wordcount-'+name) + os.sep

# Path to Hadoop wordcount example available on every Dataproc cluster.
WORDCOUNT_JAR = ('file:///usr/lib/hadoop-mapreduce/hadoop-mapreduce-examples.jar')

# Arguments to pass to Cloud Dataproc job.
wordcount_args = ['wordcount', input_file, output_file]

HADOOP_JOB = {
    "reference": {"project_id": project_id},
    "placement": {"cluster_name": dgce_cluster_name},
    "hadoop_job": {
        "main_jar_file_uri": WORDCOUNT_JAR,
        "args": wordcount_args,
    },
}

yesterday = datetime.datetime.combine(datetime.datetime.today() - datetime.timedelta(1),datetime.datetime.min.time())

default_dag_args = {

    # Setting start date as yesterday starts the DAG immediately when it is detected in the Cloud Storage bucket.
    'start_date': yesterday,

    # To email on failure or retry set 'email' arg to your email and enable emailing here.
    'email_on_failure': False,
    'email_on_retry': False,

    # If a task fails, retry it once after waiting at least 5 minutes
    'retries': 1,
    'retry_delay': datetime.timedelta(minutes=5),
    'project_id': project_id,
    'region': region,

}

with models.DAG(
        dag_name,
        schedule_interval=None,
        default_args=default_dag_args) as dag:

    # Run the Hadoop wordcount example installed on the Cloud Dataproc cluster master node.
    run_dataproc_hadoop = dataproc.DataprocSubmitJobOperator(
        task_id='Word_Count_Using_Map_Reduce',
        job=HADOOP_JOB)

# Define DAG dependencies.
run_dataproc_hadoop
