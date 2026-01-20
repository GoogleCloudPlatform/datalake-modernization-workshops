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

# Cloud Shell Cleanup

This module includes the steps for deleting the GCP resources created using Terraform for the GCP portfolio walkthrough and Autoscaling usecase using cloud shell commands<br>

[1. Declare variables](cleanup-cloud-shell.md#1-declare-variables)<br>
[2. Delete the Dataproc Clusters](cleanup-cloud-shell.md#2-delete-the-dataproc-clusters)<br>
[3. Delete metastore service](cleanup-cloud-shell.md#3-delete-metastore-service)<br>
[4. Delete the Persistent History Server](cleanup-cloud-shell.md#2-delete-the-dataproc-clusters)<br>
[5. Delete GCS Buckets](cleanup-cloud-shell.md#5-delete-gcs-buckets)<br>
[6. Delete Composer](cleanup-cloud-shell.md#6-delete-composer)<br>
[7. Delete BQ Dataset](cleanup-cloud-shell.md#7-delete-bq-dataset)<br>
[8. Delete Bigtable Instance](cleanup-cloud-shell.md#8-delete-bigtable-instance)
                                   
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
PROJECT_ID                  =$(gcloud config get-value project)
REGION                      =<region_where_resources_will_be_created>
CODE_BUCKET_NAME            =<your_code_gcp_bucket_name>
PHS_BUCKET_NM               =<your_phs_staging_bucket_name>
PHS_CLUSTER_NAME            =<your_phs_cluster_name>
DP_GCE_BUCKET_NM            =<your_dataproc_cluster_staging_bucket_name>
BQ_DATASET_NAME             =<your_bigquery_dataset_name>
COMPOSER_ENV                =<your_composer_environment_name>
BIGTABLE_INSTANCE_ID        =<your_bigtable_instance_id>
DP_GCE_CLUSTER_NAME         =<your_dataproc_cluster_name>
METASTORE_NAME              =<your_dataproc-metastore_name>
PD_NAME                     =<name_of_the_persistent_disk_for_your_environment>
PD_LOCATION                 =<the_location_of_the_persistent_disk> #For example, the location can be us-central1-a
```

## 2. Delete the Dataproc Clusters

Run the below command to delete the Dataproc clusters

```
gcloud dataproc clusters delete $DP_GCE_CLUSTER_NAME --region=${REGION} 
gcloud dataproc clusters delete $PHS_CLUSTER_NAME --region=${REGION} 
```

## 3. Delete metastore service

Run the below command to delete metastore service
```
gcloud metastore services delete projects/$PROJECT_ID/locations/$REGION/services/$METASTORE_NAME --location=${REGION}
```

## 4. Delete GCS Buckets

Follow the commands to delete the following buckets 
1. Bucket serving as gcs storage location
2. Bucket attached to Dataproc cluster as staging bucket
3. Bucket attached to PHS cluster as staging bucket

```
gcloud storage rm --recursive gs://$DP_GCE_BUCKET_NM
gcloud storage rm --recursive gs://$PHS_BUCKET_NM
gcloud storage rm --recursive gs://$CODE_BUCKET_NAME
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

## 7. Delete Bigtable Instance

Run the below command to delete the Bigtable instance

```
gcloud bigtable instances delete $BIGTABLE_INSTANCE_ID
```