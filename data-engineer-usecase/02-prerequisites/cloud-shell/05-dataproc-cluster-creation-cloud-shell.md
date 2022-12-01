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

This module includes all prerequisites for setting up the Dataproc Cluster on GCE for running the Data Engineer usecase<br>

[1. Declare variables](05-dataproc-cluster-creation-cloud-shell.md#1-declare-variables)<br>
[2. Create a Bucket](05-dataproc-cluster-creation-cloud-shell.md#2-create-a-bucket)<br>
[3. Create a Dataproc Cluster on GCE](05-dataproc-cluster-creation-cloud-shell.md#3-create-a-dataproc-cluster-on-gce)<br>

                                   
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
ZONE=<zone_where_resources_will_be_created>
SUBNET=<your_subnet_name>
DP_CLUSTER_STAGING_BUCKET=<your_dataproc_cluster_staging_gcp_bucket_name>
DP_GCE_CLUSTER_NAME=<your_dataproc_cluster_name> #<your_name>-dp-gce-cluster
METASTORE_NAME=<your_dataproc_metastore_name>
```

## 2. Create a bucket

To create a bucket which will be used as a staging bucket to store cluster job dependencies, job driver output, and cluster config files, run the following command in cloud shell:<br>

```
gsutil mb -p $PROJECT_ID -c STANDARD -l $REGION -b on gs://$DP_CLUSTER_STAGING_BUCKET
```

## 3. Create a Dataproc Cluster on GCE

A 3 node dataproc cluster with 1 master and 2 worker nodes will be created with component gateways enabled.

```
gcloud dataproc clusters create $DP_GCE_CLUSTER_NAME \
    --enable-component-gateway \
    --bucket $DP_CLUSTER_STAGING_BUCKET \
    --region $REGION \
    --subnet $SUBNET \
    --zone $ZONE \
    --master-machine-type n1-standard-4 \
    --master-boot-disk-size 500 \
    --num-workers 2 \
    --worker-machine-type n1-standard-4 \
    --worker-boot-disk-size 500 \
    --image-version 2.0-debian10 \
    --optional-components JUPYTER \
    --project $PROJECT_ID \
    --dataproc-metastore projects/$PROJECT_ID/locations/$REGION/services/$METASTORE_NAME
```