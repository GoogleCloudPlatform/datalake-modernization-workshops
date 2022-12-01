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

This module includes all all steps to setup GCP data analytics resources using Terraform modules <br>

1. Update organization policies and enable Google APIs<br>
2. Network Configuration<br>
2. Create a User Managed Service Account<br>
3. Grant IAM permissions for UMSA<br>
4. Create a User Managed Composer Service Account<br>
5. Grant IAM permissions for Composer UMSA<br>
6. Create and Setup a Composer environment<br>
7. Create GCS buckets<br>
8. Create a Dataproc Metastore<br>
9. Create a Dataproc Cluster on GCE<br>
10. Create a Persistent Spark History Server cluster<br>
11. Create a BigQuery dataset<br>
12. Create a BigTable instance<br>
13. Create a Vertex AI Managed Notebook Instance

## 0. Prerequisites

#### 1. Create a project new project or select an existing project.
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

Run the following commands in Cloud Shell to clone the repository to your cloud shell instance:

```
cd ~
git clone https://github.com/GoogleCloudPlatform/datalake-modernization-workshops
cd datalake-modernization-workshops/
mv admin-usecase/ ~/
cd ..
```

#### 2. Terraform Script Execution

Next, run the following commands in cloud shell to execute the terraform script: <br>

```
cd admin-usecase/01-scripts-and-config/terraform

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
