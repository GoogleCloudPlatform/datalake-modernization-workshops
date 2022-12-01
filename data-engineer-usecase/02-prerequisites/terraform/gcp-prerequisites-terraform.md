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

# About

This module includes all prerequisites for running the Cell Tower Anomaly Detetction and Map Reduce Word Count usecases using Terraform modules <br>

1. Update organization policies and enable Google APIs<br>
2. Network Configuration<br>
3. Create a User Managed Service Account<br>
4. Grant IAM permissions for UMSA<br>
5. Create a User Managed Composer Service Account<br>
6. Grant IAM permissions for Composer UMSA<br>
7. Create and Setup a Composer environment<br>
8. Create a GCS bucket to store code and data files,output and Dataproc cluster staging bucket<br>
9. Create a Dataproc Metastore<br>
10. Create a Persistent Spark History Server cluster<br>
11. Create a BigQuery dataset<br>
12. [Roles required for the Hackfest Attendees](gcp-prerequisites-terraform.md#2-roles-required-for-the-hackfest-attendees)<br>


## 0. Prerequisites

#### 1. Create a new project or select an existing project.
Note the project number and project ID. <br>
We will need this for the rest of the lab

#### 2. IAM Roles needed to execute the prereqs
Ensure that you have **Security Admin**, **Project IAM Admin**, **Service Usage Admin**, **Service Account Admin** and **Role Administrator** roles. This is needed for creating the GCP resources and granting access to attendees.

#### 3. Attach cloud shell to your project.
Open Cloud shell or navigate to [shell.cloud.google.com](https://shell.cloud.google.com). <br>
Run the below command to set the project to cloud shell terminal:

```
gcloud config set project <enter your project id here>

```

## 1. Running the Terraform Script

#### 1. Uploading Terraform scripts, PySpark scripts and datasets to cloud shell

- Upload the repository to the Google Cloud Shell instance<br>

#### 2. Terraform Script Execution

Next, run the following commands in cloud shell to execute the terraform script: <br>

```
cd data-engineer-usecase/00-scripts-and-config/terraform

PROJECT_ID=$(gcloud config get-value project)                                                   
PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} | grep projectNumber | cut -d':' -f2 |  tr -d "'" | xargs)
GCP_ACCOUNT_NAME=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")

terraform init
terraform apply \
  -var="project_id=${PROJECT_ID}" \
  -var="project_number=${PROJECT_NUMBER}" \
  -var="gcp_account_name=${GCP_ACCOUNT_NAME}" \
  -auto-approve
```

Once the terraform script completes execution successfully, the necessary resources for the usecase will be available to use.

## 2. Roles required for the Hackfest Attendees

Please grant the following GCP roles to all attendees to execute the hands-on labs:<br>

```
Viewer
Dataproc Editor
BigQuery Data Editor
Service Account User
Storage Admin
Environment User and Storage Object Viewer
Notebooks Runner
```
