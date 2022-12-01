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

This module includes all the steps for creating a BigQuery dataset to store the output for the Data Engineer usecase

[1. Declare variables](07-bigquery-dataset-creation-cloud-shell.md#1-declare-variables)<br>
[2. BigQuery Dataset Creation](07-bigquery-dataset-creation-cloud-shell.md#2-bigquery-dataset-creation)<br>


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
BQ_DATASET_NAME=<your_bq_dataset_name>

```

## 2. BigQuery Dataset Creation

We need to create a dataset for the tables to be created after the batch successful execution
In Cloud Shell, use the bq mk command to create a dataset under the current project using the following command:


```
bq mk $BQ_DATASET_NAME
```