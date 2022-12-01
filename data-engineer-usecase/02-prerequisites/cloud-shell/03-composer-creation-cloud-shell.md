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

# Creating Cloud Composer Environment

This module includes all prerequisites for setting up the Cloud Composer Environment for running the Data Engineer usecase<br>

[1. Declare Variables](03-composer-creation-cloud-shell.md#1-declare-variables)<br>
[2. Create a Service Account for the Composer Environment](03-composer-creation-cloud-shell.md#2-create-a-service-account-for-the-composer-environment)<br>
[3. Grant IAM Permissions for Composer Service Account](03-composer-creation-cloud-shell.md#3-grant-iam-permissions-for-composer-service-account)<br>
[4. Create a Composer Environment](03-composer-creation-cloud-shell.md#4-create-a-composer-environment)<br>
[5. Setup the Airflow Variables](03-composer-creation-cloud-shell.md#5-setup-the-airflow-variables)<br>

## 0. Prerequisites

#### 1. GCP Project Details

Note the project number and project ID as we will need this for the rest of the lab

#### 2. Attach cloud shell to your project

Open Cloud shell or navigate to [shell.cloud.google.com](https://shell.cloud.google.com) <br>
Run the below command to set the project in the cloud shell terminal:

```
gcloud config set project $PROJECT_ID

```

## 1. Declare variables

We will use these throughout the lab. <br>
Run the below in cloud shells against the project you selected-

```
PROJECT_ID=$(gcloud config get-value project)
COMPOSER_SA=<your_user_managed_composer_service_account_name>
COMPOSER_ENV=<your_composer_environment_name>
REGION=<region_where_resources_will_be_created>
VPC=<your_vpc_name>
SUBNET=<your_subnet_name>
OUTPUT_FILE_BUCKET=<your_output_file_bucket_name>
PHS_NAME=<your_phs_name>
BQ_DATASET=<your_bq_dataset_name>
UMSA_NAME=<your_umsa_name>
METASTORE_DB=<your_metastore_db_name>
METASTORE_NAME=<your_metastore_name>
CODE_AND_DATA_BUCKET=<your_code_and_data_bucket_name>
CLOUD_COMPOSER2_IMG_VERSION=composer-2.0.11-airflow-2.2.3 
```

## 2. Create a Service Account for the Composer Environment

```
gcloud iam service-accounts create $COMPOSER_SA \
 --description="Service Account for Cloud Composer Environment" \
 --display-name "Cloud Composer SA"

```

## 3. Grant IAM Permissions for Composer Service Account

#### 3.1.a. Composer Worker role for Composer Service Account

```
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:$COMPOSER_SA@$PROJECT_ID.iam.gserviceaccount.com --role roles/composer.worker

```

#### 3.1.b. Dataproc Editor role for Composer Service Account

```
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:$COMPOSER_SA@$PROJECT_ID.iam.gserviceaccount.com --role roles/dataproc.editor

```

#### 3.1.c. Service Account User role for Composer Service Account

```
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:$COMPOSER_SA@$PROJECT_ID.iam.gserviceaccount.com --role roles/iam.serviceAccountUser

```

#### 3.1.d. Composer Service Agent role for Composer Service Account

```
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:$COMPOSER_SA@$PROJECT_ID.iam.gserviceaccount.com --role roles/composer.ServiceAgentV2Ext
```

## 4. IAM role grants to Google Managed Service Account for Cloud Composer 2

```
gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:service-$PROJECT_NBR@cloudcomposer-accounts.iam.gserviceaccount.com --role roles/composer.ServiceAgentV2Ext
```

## 5. Create a Composer Environment

* To create a composer environment which will allow all IP addresses to access the Airflow web server execute the below command in cloud shell: <br>

```
gcloud composer environments create $COMPOSER_ENV \
--location $REGION \
--environment-size small \
--service-account $COMPOSER_SA@$PROJECT_ID.iam.gserviceaccount.com \
--image-version $CLOUD_COMPOSER2_IMG_VERSION \
--network $VPC \
--subnetwork $SUBNET \
--web-server-allow-all \
--env-variables AIRFLOW_VAR_PROJECT_ID=$PROJECT_ID,AIRFLOW_VAR_REGION=$REGION,AIRFLOW_VAR_OUTPUT_FILE_BUCKET=$OUTPUT_FILE_BUCKET,AIRFLOW_VAR_PHS=$PHS_NAME,AIRFLOW_VAR_SUBNET=$SUBNET,AIRFLOW_VAR_BQ_DATASET=$BQ_DATASET,AIRFLOW_VAR_UMSA=$UMSA_NAME,AIRFLOW_VAR_METASTORE_DB=$METASTORE_DB,AIRFLOW_VAR_METASTORE=$METASTORE_NAME,AIRFLOW_VAR_CODE_AND_DATA_BUCKET=$CODE_AND_DATA_BUCKET

```

* Alternatively, to create a composer environment which will allow a specific list of IPv4 or IPv6 ranges to access the Airflow web server, execute the following command in cloud shell: <br>

```
gcloud composer environments create $COMPOSER_ENV \
--location $REGION \
--environment-size small \
--service-account $COMPOSER_SA@$PROJECT_ID.iam.gserviceaccount.com \
--image-version $CLOUD_COMPOSER2_IMG_VERSION \
--network $VPC \
--subnetwork $SUBNET \
--env-variables AIRFLOW_VAR_PROJECT_ID=$PROJECT_ID,AIRFLOW_VAR_REGION=$REGION,AIRFLOW_VAR_OUTPUT_FILE_BUCKET=$OUTPUT_FILE_BUCKET,AIRFLOW_VAR_PHS=$PHS_NAME,AIRFLOW_VAR_SUBNET=$SUBNET,AIRFLOW_VAR_BQ_DATASET=$BQ_DATASET,AIRFLOW_VAR_UMSA=$UMSA_NAME,AIRFLOW_VAR_METASTORE_DB=$METASTORE_DB,AIRFLOW_VAR_METASTORE=$METASTORE_NAME,AIRFLOW_VAR_CODE_AND_DATA_BUCKET=$CODE_AND_DATA_BUCKET \
--web-server-allow-ip [description=<description>],[ip_range=<ip_address>]
```

**Note:** Here, `--web-server-allow-ip [description=<description>],[ip_range=<ip_address>]` is a repeatable flag and can be used to add multiple ip addresses.