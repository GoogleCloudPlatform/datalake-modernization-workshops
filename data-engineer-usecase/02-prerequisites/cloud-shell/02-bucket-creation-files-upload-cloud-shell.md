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

This module includes all the steps for creating a GCS bucket to store the PySpark scripts and input data files for the Cell Tower Anomaly Detection usecase and store as output directory for word count usecase.

[1. Declare variables](02-bucket-creation-files-upload-cloud-shell.md#1-declare-variables)<br>
[2. GCS Bucket creation](02-bucket-creation-files-upload-cloud-shell.md#2-gcs-bucket-creation)<br>
[3. Uploading the repository to GCS Bucket](02-bucket-creation-files-upload-cloud-shell.md#3-uploading-the-repository-to-gcs-bucket)<br>

## 0. Prerequisites

#### 1. Create a new project or select an existing project.

Note the project number and project ID since we will need this for the rest for the lab

#### 2. Attach cloud shell to your project.
Open Cloud shell or navigate to [shell.cloud.google.com](https://shell.cloud.google.com)
Run the below
```
gcloud config set project $PROJECT_ID

```

## 1. Declare variables

We will use these throughout the lab. <br>
Run the below in cloud shells coped to the project you selected-

```
PROJECT_ID=$(gcloud config get-value project)
REGION=<region_where_resources_will_be_created>
CODE_AND_DATA_BUCKET=<your_code_and_data_gcp_bucket_name>
OUTPUT_BUCKET=<your_map_reduce_output_bucket_name>

```

## 2. GCS Bucket creation

Run the following gcloud command in Cloud Shell to create the GCS buckets.

```
gsutil mb -p $PROJECT_ID -c STANDARD -l $REGION -b on gs://$CODE_AND_DATA_BUCKET
gsutil mb -p $PROJECT_ID -c STANDARD -l $REGION -b on gs://$OUTPUT_BUCKET

```

## 3. Uploading the repository to GCS Bucket

To upload the code repository, please follow the below steps:
- Extract the compressed code repository folder to your local Machine
- Upload the extracted folder to cloud shell
- Next, execute the follow commands in cloud shell, to upload the code and data files to GCS buckets:

```
gsutil cp data-engineer-usecase/00-scripts-and-config/pyspark/* gs://$CODE_AND_DATA_BUCKET/cell-tower-anomaly-detection/00-scripts-and-config/pyspark/
gsutil cp data-engineer-usecase/01-datasets/* gs://$CODE_AND_DATA_BUCKET/cell-tower-anomaly-detection/01-datasets/
gsutil cp data-engineer-usecase/01-datasets/cust_raw_data/* gs://$CODE_AND_DATA_BUCKET/cell-tower-anomaly-detection/01-datasets/cust_raw_data/

```