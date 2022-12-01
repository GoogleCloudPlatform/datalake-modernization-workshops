<!---->
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
 <!---->

# Cell Tower Anomaly Detection and Map Reduce Word Count on GCP

The repository contains instructions and configuration for hands on experience with running workloads on Google Dataproc

## 1. Overview

As part of this job, we are:
- Running PySpark workloads on Dataproc GCE cluster with Metastore integration through Google Cloud console, Cloud shell and Composer/Airflow
- Running PySpark workloads on Serverless Spark with Metastore integration through Google Cloud console, Cloud shell and Composer/Airflow
- Running wordcount on a data file of our choosing using Hadoop Map Reduce through Google Cloud console, Cloud shell and Composer/Airflow

## 2. Services Used

* Google Cloud Storage
* Google Cloud Dataproc
* Google Cloud Composer
* Google BigQuery

## 3. Permissions / IAM Roles required to run the lab

Following permissions / roles are required to execute the lab:

- Viewer
- Dataproc Editor
- Service Account User
- Storage Admin
- BigQuery Data Editor
- Environment User and Storage Object Viewer
- Notebooks Runner


## 4. Checklist

Note down the following values before getting started with the lab:

- GCP Project Id
- GCP region where all resources are created
- VPC name
- Subnet name
- UMSA fully qualified name
- GCS bucket name to store code and data files
- Dataproc cluster name
- Cloud Composer environment name
- Dataproc Metastore name
- Persistent History server name
- BigQuery dataset name
- NAME <your_username_without_any_numbers_or_special_characters>

**Note:** For all the variables except 'NAME', please ensure to use the values provided by the admin team.


   
## 5. Lab Modules
The lab consists of the following modules.

1. Setting up the GCP Environment (Admin Step)
    - There are 2 ways of setting up the prerequisites:
        - Using [Terraform Scripts](02-prerequisites/terraform/gcp-prerequisites-terraform.md)
        - Using 'Gcloud commands'
            - [Setting up a VPC network, service accounts and permissions](02-prerequisites/cloud-shell/01-gcp-prerequisites-cloud-shell.md)
            - [Creating GCS buckets](02-prerequisites/cloud-shell/02-bucket-creation-files-upload-cloud-shell.md)
            - [Creating a Cloud Composer environment](02-prerequisites/cloud-shell/03-composer-creation-cloud-shell.md)
            - [Creating a Dataproc Metastore](02-prerequisites/cloud-shell/04-metastore-creation-cloud-shell.md)
            - [Creating a Persistent History Server cluster](02-prerequisites/cloud-shell/06-phs-cluster-creation-cloud-shell.md)
            - [Creating a BigQuery dataset](02-prerequisites/cloud-shell/07-bigquery-dataset-creation-cloud-shell.md)
             
    Please chose one of the methods to execute the lab.

2. Running the Data Engineering usecase (Lab Execution Step)
    - Creating a [Dataproc Cluster through Terraform](02-prerequisites/terraform/terraform-user.md)
    - Creating a [Dataproc Cluster through Cloud Shell](02-prerequisites/cloud-shell/05-dataproc-cluster-creation-cloud-shell.md)

    Please chose one of the methods
    
    - There are 3 ways of perforing the lab:
        - Using [Cloud shell](03-execution-instructions/gcloud-execution.md)
        - Using [GCP console](03-execution-instructions/console-execution.md)
        - Using [Cloud Composer](03-execution-instructions/airflow-execution.md)
3. Cleaning up the GCP Environment (Admin Step)
    - Depending on whether the environment was setup using Terraform or gcloud commands, the GCP resources can be cleaned up in 2 ways:
        - Using [Terraform Scripts](04-cleanup/cleanup-terraform.md)
        - Using [Gcloud commands](04-cleanup/cleanup-cloud-shell.md)
        - Request all users to delete their individually created Dataproc clusters
