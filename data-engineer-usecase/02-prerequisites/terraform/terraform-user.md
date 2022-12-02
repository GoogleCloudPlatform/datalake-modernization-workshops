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

This module includes Dataproc Cluster Creation for running the Cell Tower Anomaly Detetction and Map Reduce Word Count usecases using Terraform modules <br>

1. Create a GCS bucket as Dataproc cluster staging bucket<br>
2. Create a Dataproc Cluster on GCE<br>

## 0. Prerequisites

#### 1. Create a new project or select an existing project.
Note the project number and project ID. <br>
We will need this for the rest fo the lab

#### 2. Attach cloud shell to your project.
Open Cloud shell or navigate to [shell.cloud.google.com](https://shell.cloud.google.com). <br>
Run the below command to set the project to cloud shell terminal:

```
gcloud config set project <enter your project id here>

```

## 1. Running the Terraform Script

#### 1. Uploading scripts and datasets to cloud shell

Run the following commands in Cloud Shell to clone the repository to your cloud shell instance:

```
cd ~
git clone https://github.com/GoogleCloudPlatform/datalake-modernization-workshops
cd datalake-modernization-workshops/
mv biglake-finegrained-lab/ ~/
cd ..
```

#### 2. Terraform Script Execution

Next, run the following commands in cloud shell to execute the terraform script: <br>

```
cd data-engineer-usecase/00-scripts-and-config/terraform-user

PROJECT_ID=$(gcloud config get-value project)                                                   
PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} | grep projectNumber | cut -d':' -f2 |  tr -d "'" | xargs)
GCP_ACCOUNT_NAME=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
COMPOSER_BUCKET_NAME=<Composer Bucket Name provided by Admin>
COMPOSER_ENV_NAME=<Composer Environment Name provided by Admin>

terraform init
terraform apply \
  -var="project_id=${PROJECT_ID}" \
  -var="project_number=${PROJECT_NUMBER}" \
  -var="gcp_account_name=${GCP_ACCOUNT_NAME}" \
  -var="composer_bucket_nm=${COMPOSER_BUCKET_NAME}" \
  -var="composer_nm=${COMPOSER_ENV_NAME}" \
  -auto-approve
```

Once the terraform script completes execution successfully, the Dataproc cluster and Airflow DAGs for the usecase will be available to use.
