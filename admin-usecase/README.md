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

# GCP Data Analytics Portfolio walkthrough and Wikipedia Page View Count to demonstrate autoscaling using Terraform and Cloud Shell

The repository contains instructions and configuration for hands on experience with setting up resources and running workloads on Google Cloud Platform

## 1. Overview

As part of this lab, we are:
-   Running terraform and gcloud commands to create resources which are part of GCP's data analytics services
-   Running PySpark workloads on Dataproc GCE Cluster through Google Cloud console, Cloud shell and Composer/Airflow
-   Running PySpark workloads on Dataproc Serverless batches through Google Cloud console, Cloud shell and Composer/Airflow

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
- GCS bucket name to store code file
- Dataproc cluster name
- Cloud Composer environment name
- Persistent History server name

## 3. Lab Modules
The lab consists of the following modules.

1. Setting up the GCP Environment
    - There are 2 ways of setting up the GCP portfolio resources:
        - Using [Terraform Scripts](02-execution-instructions/terraform-execution.md)
        - Using [Gcloud commands](02-execution-instructions/cloud-shell-execution.md)

    Please chose one of the methods to setup the resources.

2. Running the Wikipedia Page View count workflow and exploring the output
    - There are 3 ways of running the Page View Word Count Job:
        - Using [Cloud shell](02-execution-instructions/cloud-shell-execution.md)
        - Using [GCP console](02-execution-instructions/console-execution.md)
        - Using [Cloud Composer](02-execution-instructions/airflow-execution.md)

3. Cleaning up the GCP Environment
    - Depending on whether the environment was setup using Terraform or gcloud commands, the GCP resources can be cleaned up in 2 ways:
        - Using [Terraform Scripts](03-cleanup/cleanup-terraform.md)
        - Using [Gcloud commands](03-cleanup/cleanup-cloud-shell.md)
