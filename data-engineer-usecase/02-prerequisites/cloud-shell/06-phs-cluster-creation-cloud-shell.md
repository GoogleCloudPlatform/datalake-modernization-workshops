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

This module includes all prerequisites for setting up the Persistent History Server cluster for running the Data Engineer usecase<br>

[1. Declare variables](06-phs-cluster-creation-cloud-shell.md#1-declare-variables)<br>
[2. Create a Bucket](06-phs-cluster-creation-cloud-shell.md#2-create-a-bucket)<br>
[3. Create a Dataproc PHS cluster](06-phs-cluster-creation-cloud-shell.md#3-create-a-dataproc-phs-cluster)<br>

                                   
## 0. Prerequisites 

#### 1. GCP Project Details
Note the project number and project ID. <br>
We will need this for the rest fo the lab

#### 2. Attach cloud shell to your project.
Open Cloud shell or navigate to [shell.cloud.google.com](https://shell.cloud.google.com) <br>
Run the below command to set the project in the cloud shell terminal:

```
gcloud config set project $PROJECT ID

```

## 1. Declare variables 

We will use these throughout the lab. <br>
Run the below in cloud shell against the project you selected-

```
PROJECT_ID=$(gcloud config get-value project)
REGION=<region_where_resources_will_be_created>
BUCKET_PHS=<your_phs_gcp_bucket_name>
PHS_CLUSTER_NAME=<your_dataproc_phs_cluster_name>
SUBNET=<your_subnet_name>
```

## 2. Create a bucket

To create a bucket which will be used as a staging bucket for the Persistent History Server, run the following command in cloud shell:<br>

```
gcloud storage buckets create gs://$BUCKET_PHS --project=$PROJECT_ID --default-storage-class=STANDARD --location=$REGION --uniform-bucket-level-access
```

## 3. Create a Dataproc PHS cluster

A single node dataproc cluster will be created with component gateways enabled.

```
gcloud dataproc clusters create ${PHS_CLUSTER_NAME} \
  --project=${PROJECT_ID} \
  --region=${REGION} \
  --single-node \
  --subnet=${SUBNET} \
  --image-version=2.0 \
  --enable-component-gateway \
  --properties=spark:spark.history.fs.logDirectory=gs://${BUCKET_PHS}/phs/*/spark-job-history
```