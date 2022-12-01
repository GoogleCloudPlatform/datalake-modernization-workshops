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

This module includes the steps to cleanup the resources created for the Data engineer usecase using cloud shell commands.

[1. Declare variables](cleanup-cloud-shell.md#1-declare-variables)<br>
[2. Delete the Dataproc Clusters](cleanup-cloud-shell.md#2-delete-the-dataproc-clusters)<br>
[3. Delete metastore service](cleanup-cloud-shell.md#3-delete-metastore-service)<br>
[4. Delete GCS Buckets](cleanup-cloud-shell.md#4-delete-gcs-buckets)<br>
[5. Delete Composer](cleanup-cloud-shell.md#5-delete-composer)<br>
[6. Delete BQ Dataset](cleanup-cloud-shell.md#6-delete-bq-dataset)
                                   
## 0. Prerequisites 

#### 1. GCP Project Details
Note the project number and project ID as we will need this for the the cleanup process

#### 3. Attach cloud shell to your project.
Open Cloud shell or navigate to [shell.cloud.google.com](https://shell.cloud.google.com) <br>
Run the below command to set the project in the cloud shell terminal:

```
gcloud config set project $PROJECT_ID
```

## 1. Declare variables 

Run the below in cloud shells coped to the project you selected-

```
PROJECT_ID=$(gcloud config get-value project)
REGION=<region_where_resources_will_be_created>
CODE_AND_DATA_BUCKET_NAME=<your_code_and_data_gcp_bucket_name>
OUTPUT_BUCKET_NAME=<your_output_gcp_bucket_name>
PHS_CLUSTER_STAGING_BUCKET_NAME=<your_phs_staging_gcp_bucket_name>
PHS_CLUSTER_NAME=<your_phs_cluster_name>
COMPOSER_ENV=<your_composer_environment_name>
PD_NAME=<name_of_the_persistent_disk_for_your_environment>
PD_LOCATION=<the_location_of_the_persistent_disk> #For example, the location can be us-central1-a
METASTORE_NAME=<your_dpms_name>
BQ_DATASET_NAME=<your_bq_dataset_name>
```

## 2. Delete the Dataproc Cluster

Run the below command to delete the Dataproc cluster

```
gcloud dataproc clusters delete $PHS_CLUSTER_NAME --region=${REGION} 
```

## 3. Delete metastore service

Run the below command to delete metastore service
```
gcloud metastore services delete projects/$PROJECT_ID/locations/$REGION/services/$METASTORE_NAME --location=${REGION}
```

## 4. Delete GCS Buckets

Follow the commands to delete the following buckets 
1. Bucket serving as code and data files storage location
2. Bucket attached to Dataproc cluster as staging bucket
3. Bucket attached to PHS cluster as staging bucket

```
gsutil rm -r gs://$CODE_AND_DATA_BUCKET_NAME
gsutil rm -r gs://$OUTPUT_BUCKET_NAME
gsutil rm -r gs://$PHS_CLUSTER_STAGING_BUCKET_NAME
```

## 5. Delete Composer

#### 5.1. Delete Composer Environment

Run the below command to delete composer environment

```
gcloud composer environments delete $COMPOSER_ENV --location $REGION
```

#### 5.2. Delete Persistent Disk of Composer Environment

Delete the persistent disk of your environment's Redis queue. Deleting the Cloud Composer environment does not delete its persistent disk.
To delete your environment's persistent disk:
```
gcloud compute disks delete $PD_NAME --zone=$PD_LOCATION
```

## 6. Delete BQ Dataset

Run the below command to delete BQ dataset and all the tables within the dataset

```
gcloud alpha bq datasets delete $BQ_DATASET_NAME --remove-tables
```