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

# GCP Data Portfolio Walkthough and Autoscaling on Dataproc though Cloud Shell

This module includes all all steps to setup GCP data analytics resources and run an autoscaling workload on Dataproc through cloud shell <br>

1. Network Configuration<br>
3. Create a User Managed Service Account<br>
4. Grant IAM permissions for UMSA<br>
5. Create a User Managed Composer Service Account<br>
6. Grant IAM permissions for Composer UMSA<br>
7. Create and Setup a Composer environment<br>
8. Create GCS buckets<br>
9. Create a Dataproc Metastore<br>
10. Create a Dataproc Cluster on GCE<br>
11. Create a Persistent Spark History Server cluster<br>
12. Create a BigQuery dataset<br>
13. Create a Bigtable instance<br>
14. Run a Wikipedia Page View Autoscaling Dataproc job on a Dataproc Cluster on GCE<br>
15. Run a Wikipedia Page View Autoscaling job through Serverless Spark<br>


## 0. Prerequisites

#### 1. Create a project new project or select an existing project.
Note the project number and project ID. <br>
We will need this for the rest of the lab

#### 2. IAM Roles needed to execute the GCP resource creation
Ensure that you have **Security Admin**, **Project IAM Admin**,**Service Usage Admin**, **Service Account Admin** and **Role Administrator** roles. This is needed for creating the GCP resources and granting access to attendees.

#### 3. Attach cloud shell to your project.
Open Cloud shell or navigate to [shell.cloud.google.com](https://shell.cloud.google.com). <br>
Run the below command to set the project to cloud shell terminal:

```
gcloud config set project <enter your project id here>
```

#### 4. Uploading PySpark scripts and datasets to cloud shell

Run the following commands in Cloud Shell to clone the repository to your cloud shell instance:

```
cd ~
git clone https://github.com/GoogleCloudPlatform/datalake-modernization-workshops
cd datalake-modernization-workshops/
mv admin-usecase/ ~/
cd ..
```

#### 4. Declaring Variables

- Set the PROJECT_ID in Cloud Shell

Open Cloud shell or navigate to [shell.cloud.google.com](https://shell.cloud.google.com)<br>
Run the below

```
gcloud config set project <enter your project id here>
```

- Verify the PROJECT_ID in Cloud Shell

Next, run the following command in cloud shell to ensure that the current project is set correctly:

```
gcloud config get-value project
```

- Declare the variables

Based on the prereqs and checklist, declare the following variables in cloud shell by replacing with your values:

```
PROJECT_ID=$(gcloud config get-value project)
REGION=                                             #GCP region where all our resources will be created
SUBNET=                                             #subnet which has private google access enabled
BUCKET_CODE=                                        #GCP bucket where our code, data and model files will be stored
CLUSTER_NAME=                                       #name of the dataproc cluster.
NAME=                                               #your name
BUCKET_PHS=                                         #bucket where our application logs created in the history server will be stored
HISTORY_SERVER_NAME=                                #name of the history server which will store our application logs
UMSA=                                               #name of the user managed service account required for the PySpark job executions
SERVICE_ACCOUNT=$UMSA@$PROJECT_ID.iam.gserviceaccount.com
```

- Update Cloud Shell SDK version

Run the below on cloud shell-
```
gcloud components update

```

# Section-1
# Setting up GCP Data Portfolio Resources through Cloud Shell

## 1. Update Organization Policies

Run the following commands in cloud shell to update the organization policies:<br>

```
gcloud resource-manager org-policies enable-enforce compute.disableSerialPortLogging --project=$PROJECT_ID
gcloud resource-manager org-policies enable-enforce compute.requireOsLogin --project=$PROJECT_ID
gcloud resource-manager org-policies enable-enforce compute.requireShieldedVm --project=$PROJECT_ID
gcloud resource-manager org-policies enable-enforce compute.vmCanIpForward --project=$PROJECT_ID
gcloud resource-manager org-policies enable-enforce compute.vmExternalIpAccess --project=$PROJECT_ID
gcloud resource-manager org-policies enable-enforce compute.restrictVpcPeering --project=$PROJECT_ID
```

## 2. Enable Google Dataproc, Cloud Composer, Compute Engine, Dataproc Metastore and Cloud Storage APIs

Run the following commands in cloud shell to enable the APIs:<br>

```
gcloud services enable orgpolicy.googleapis.com
gcloud services enable dataproc.googleapis.com
gcloud services enable composer.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable metastore.googleapis.com
gcloud services enable bigquery.googleapis.com
gcloud services enable notebooks.googleapis.com
gcloud services enable aiplatform.googleapis.com
gcloud services enable logging.googleapis.com
gcloud services enable monitoring.googleapis.com
gcloud services enable servicenetworking.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
```

## 3. Running the Shell Script

#### 1. Customizing the shell script

From the '01-scripts-and-config>cloud-shell' folder, edit the 'cloud-shell-resource-creation.sh' script by updating the values for the following variables:<br>

```
REGION                      =<region_where_resources_will_be_created>
SUBNET_NM                   =<your_subnet_name>
GCS_BUCKET_NM               =<your_gcs_bucket_name>
PHS_BUCKET_NM               =<your_phs_staging_bucket_name>
HISTORY_SERVER_NAME         =<your_phs_cluster_name>
BQ_DATASET_NAME             =<your_bigquery_dataset_name>
UMSA_NAME                   =<your_umsa_name>
COMPOSER_SA                 =<your_composer_umsa_name>
COMPOSER_ENV                =<your_composer_environment_name>
VPC_NM                      =<your_vpc_name>
SUBNET_CIDR                 =<your_subnet_cidr> #Example: "10.0.0.0/16"
FIREWALL_NM                 =<your_firewall_name>
BIGTABLE_INSTANCE_ID        =<your_bigtable_instance_id>
BIGTABLE_DISPLAY_NAME       =<your_bigtable_instance_display_name_in_the_console>
DP_GCE_BUCKET_NM            =<your_dataproc_cluster_staging_bucket_name>
DP_GCE_CLUSTER_NAME         =<your_dataproc_cluster_name>
DP_GCE_CLUSTER_ZONE         =<your_dataproc_cluster_zone>
AUTOSCALING_MIN_NODES       =<your_bigtable_instance_minimum_number_of_cluster_nodes>
AUTOSCALING_MAX_NODES       =<your_bigtable_instance_maximum_number_of_cluster_nodes>
AUTOSCALING_CPU_TARGET      =<your_bigtable_instance_target_cpu_utilization> #This value must be from 10 to 80.
AUTOSCALING_STORAGE_TARGET  =<your_bigtable_instance_storage_utilization_target_in_GiB_that_Bigtable_maintains_by_adding_or_removing_nodes>
CLUSTER_STORAGE_TYPE        =<your_bigtable_instance_storage_type>
CLUSTER_ID_1                =<id_for_bigtable_cluster_1>
CLUSTER_ID_2                =<id_for_bigtable_cluster_2>
CLUSTER_ZONE_1              =<your_bigtable_cluster_1_zone>
CLUSTER_ZONE_2              =<your_bigtable_cluster_2_zone>
METASTORE_NAME              =<your_dataproc-metastore_name>
BIGTABLE_CLUSTER_NUM_NODES  =<no_of_nodes_for_your_bigtable_instance_cluster>
ASP_NAME                    =<your_autoscaling_policy_name>

```

Once these values have been entered, please save the file.

#### 2. Uploading shell scripts to cloud shell

Upload the repository to the Google Cloud Shell instance

#### 3. Shell Script Execution

Next, run the following commands in cloud shell to execute the shell script: <br>

```
cd admin-usecase/01-scripts-and-config/cloud-shell
bash cloud-shell-resource-creation.sh
```

Once the shell script completes execution successfully, all resources mentioned in the script will be successfully created.

# Section-2
# Wikipedia Page Views Usecase with PySpark on a Dataproc GCE cluster and through Dataproc Serverless Batches through Cloud Shell

**Goal** - Calculating Wikipedia page views for 2019 using PySpark scripts on a Dataproc GCE cluster.

Following are the lab modules:

[1. Understanding Data](cloud-shell-execution.md#1-understanding-the-data)<br>
[2. Solution Architecture](cloud-shell-execution.md#2-solution-diagram)<br>
[3. Running the job on Dataproc Cluster on GCE](cloud-shell-execution.md#3-running-the-job-on-dataproc-cluster-on-gce)<br>
[4. Viewing the output](cloud-shell-execution.md#4-viewing-the-output)<br>
[5. Logging](cloud-shell-execution.md#5-logging)<br>
[6. Running the job as a serverless batch on Dataproc](cloud-shell-execution.md#6-running-the-job-as-a-serverless-batch-on-dataproc)<br>
[7. Viewing the output](cloud-shell-execution.md#7-viewing-the-output)<br>
[8. Logging](cloud-shell-execution.md#8-logging)<br>

## 1. Understanding the data

The dataset used for this project is Shakespeare dataset from Bigquery public data

#### 1. **Shakespeare data**<br>
   Contains a word index of the works of Shakespeare, giving the number of times each word appears in each corpus.<br>

## 2. Solution Architecture

<kbd>
<img src= images/Flow_of_Resources.jpeg>
</kbd>

<br>

**Data Pipeline**

The data pipeline involves the following steps: <br>
	- Create buckets in GCS <br>
	- Create Dataproc and Persistent History Server Cluster <br>
	- Create a Composer Environment<br>
	- Executing the code through Cloud Shell <br>
	- Viewing the output in the Dataproc UI

## 3.  Running the job on Dataproc Cluster on GCE

Execute the following gcloud command in cloud shell to execute the PySpark script to calculate top 20 most visited Wikipedia pages for 2019

```
gcloud dataproc jobs submit pyspark \
--cluster $CLUSTER_NAME \
--id $NAME-page-view-count-$RANDOM \
gs://$BUCKET_CODE/wikipedia-page-view/01-scripts-and-config/pyspark/page_view_autoscaling.py \
--region $REGION \
--project $PROJECT_ID \
--jars gs://spark-lib/bigquery/spark-bigquery-with-dependencies_2.12-0.22.2.jar
```

## 4. Viewing the output

Once the job completes executing successfully, the output can be viewed in the Dataproc jobs UI as shown below:<br>

![this is a screenshot](/images/op_1c.png)

![this is a screenshot](/images/op_2c.png)

## 5. Logging

#### 5.1 Persistent History Server logs

To view the Persistent History server logs, Navigate to the cluster and open web interfaces and navigate to spark history server.

![this is a screenshot](/images/image30.png)

![this is a screenshot](/images/image31.png)


## 6. Running the job as a serverless batch on Dataproc

Execute the following gcloud command in cloud shell to execute the PySpark script to calculate top 20 most visited Wikipedia pages for 2019

```
gcloud dataproc batches submit \
--project $PROJECT_ID \
--region $REGION pyspark \
--batch $NAME-page-view-count-$RANDOM \
gs://$BUCKET_CODE/wikipedia-page-view/01-scripts-and-config/pyspark/page_view_autoscaling.py \
--history-server-cluster projects/$PROJECT_ID/regions/$REGION/clusters/$HISTORY_SERVER_NAME \
--jars gs://spark-lib/bigquery/spark-bigquery-with-dependencies_2.12-0.22.2.jar \
--subnet $SUBNET
```

## 7. Viewing the output

Once the batch completes executing successfully, the output can be viewed in the Dataproc batches UI as shown below:<br>

![this is a screenshot](/images/op_1.png)

![this is a screenshot](/images/op_2.png)

## 8. Logging

#### 8.1 Serverless Batch logs

Logs associated with the application can be found in the logging console under
**Dataproc > Serverless > Batches > <batch_name>**.
<br> You can also click on “View Logs” button on the Dataproc batches monitoring page to get to the logging page for the specific Spark job.

![this is a screenshot](/images/image10.png)

![this is a screenshot](/images/image11.png)

#### 8.2 Persistent History Server logs

To view the Persistent History server logs, click the 'View History Server' button on the Dataproc batches monitoring page and the logs will be shown as below:

![this is a screenshot](/images/image12.png)

![this is a screenshot](/images/image13.png)
