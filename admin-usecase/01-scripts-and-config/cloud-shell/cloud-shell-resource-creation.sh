# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

PROJECT_ID=$(gcloud config get-value project)
PROJECT_NBR=$(gcloud projects list --filter="$(gcloud config get-value project)" --format="value(PROJECT_NUMBER)")
REGION=<region_where_resources_will_be_created>
SUBNET_NM=<your_subnet_name>
GCS_BUCKET_NM=<your_gcs_bucket_name>
PHS_BUCKET_NM=<your_phs_staging_bucket_name>
HISTORY_SERVER_NAME=<your_phs_cluster_name>
BQ_DATASET_NAME=<your_bigquery_dataset_name>
UMSA_NAME=<your_umsa_name>
SERVICE_ACCOUNT=$UMSA_NAME@$PROJECT_ID.iam.gserviceaccount.com
COMPOSER_SA=<your_composer_umsa_name>
COMPOSER_ENV=<your_composer_environment_name>
VPC_NM=<your_vpc_name>
SUBNET_CIDR=<your_subnet_cidr> #Example: "10.0.0.0/16"
FIREWALL_NM=<your_firewall_name>
BIGTABLE_INSTANCE_ID=<your_bigtable_instance_id>
BIGTABLE_DISPLAY_NAME=<your_bigtable_instance_display_name_in_the_console>
DP_GCE_BUCKET_NM=<your_dataproc_cluster_staging_bucket_name>
DP_GCE_CLUSTER_NAME=<your_dataproc_cluster_name>
DP_GCE_CLUSTER_ZONE=<your_dataproc_cluster_zone>
AUTOSCALING_MIN_NODES=<your_bigtable_instance_minimum_number_of_cluster_nodes>
AUTOSCALING_MAX_NODES=<your_bigtable_instance_maximum_number_of_cluster_nodes>
AUTOSCALING_CPU_TARGET=<your_bigtable_instance_target_cpu_utilization> #This value must be from 10 to 80.
AUTOSCALING_STORAGE_TARGET=<your_bigtable_instance_storage_utilization_target_in_GiB_that_Bigtable_maintains_by_adding_or_removing_nodes>
CLUSTER_STORAGE_TYPE=<your_bigtable_instance_storage_type>
ADMIN_ACCOUNT_ID=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
CLUSTER_ID_1=<id_for_bigtable_cluster_1>
CLUSTER_ID_2=<id_for_bigtable_cluster_2>
CLUSTER_ZONE_1=<your_bigtable_cluster_1_zone>
CLUSTER_ZONE_2=<your_bigtable_cluster_2_zone>
METASTORE_NAME=<your_dataproc-metastore_name>
BIGTABLE_CLUSTER_NUM_NODES=<no_of_nodes_for_your_bigtable_instance_cluster>
ASP_NAME=<your_autoscaling_policy_name>
PORT=9083
TIER=Developer
METASTORE_VERSION=3.1.2

# 1a. User Managed Service Account Creation

gcloud iam service-accounts create $UMSA_NAME \
 --description="User Managed Service Account for Serverless Spark" \
 --display-name "Serverless Spark SA"

# 1b. Composer User Managed Service Account Creation

gcloud iam service-accounts create $COMPOSER_SA \
  --description="Service Account for Cloud Composer Environment" \
  --display-name "Cloud Composer SA"

# 2a. IAM role grants to User Managed Service Account

#### 2.1. Basic role for UMSA

gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:$UMSA_NAME@$PROJECT_ID.iam.gserviceaccount.com --role roles/viewer

#### 2.2. Storage Admin role for UMSA

gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:$UMSA_NAME@$PROJECT_ID.iam.gserviceaccount.com --role roles/storage.admin

#### 2.3. Dataproc Editor role for UMSA

gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:$UMSA_NAME@$PROJECT_ID.iam.gserviceaccount.com --role roles/dataproc.editor

#### 2.4. Dataproc Worker role for UMSA

gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:$UMSA_NAME@$PROJECT_ID.iam.gserviceaccount.com --role roles/dataproc.worker

#### 2.5. BigQuery Data Editor role for UMSA

gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:$UMSA_NAME@$PROJECT_ID.iam.gserviceaccount.com --role roles/bigquery.dataEditor

#### 2.6. BigQuery User role for UMSA

gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:$UMSA_NAME@$PROJECT_ID.iam.gserviceaccount.com --role roles/bigquery.user

#### 2.7. Notebooks Admin role for UMSA

gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:$UMSA_NAME@$PROJECT_ID.iam.gserviceaccount.com --role roles/notebooks.admin

# 2b. IAM role grants to User Managed Service Account for Cloud Composer 2

gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:$COMPOSER_SA@$PROJECT_ID.iam.gserviceaccount.com --role roles/composer.worker

gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:$COMPOSER_SA@$PROJECT_ID.iam.gserviceaccount.com --role roles/dataproc.editor

gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:$COMPOSER_SA@$PROJECT_ID.iam.gserviceaccount.com --role roles/iam.serviceAccountUser

gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:$COMPOSER_SA@$PROJECT_ID.iam.gserviceaccount.com --role roles/composer.ServiceAgentV2Ext


# 2c. IAM role grants to Admin User

gcloud projects add-iam-policy-binding $PROJECT_ID --member user:$ADMIN_ACCOUNT_ID --role roles/storage.admin

gcloud projects add-iam-policy-binding $PROJECT_ID --member user:$ADMIN_ACCOUNT_ID --role roles/metastore.admin

gcloud projects add-iam-policy-binding $PROJECT_ID --member user:$ADMIN_ACCOUNT_ID --role roles/dataproc.admin

gcloud projects add-iam-policy-binding $PROJECT_ID --member user:$ADMIN_ACCOUNT_ID --role roles/bigquery.admin

gcloud projects add-iam-policy-binding $PROJECT_ID --member user:$ADMIN_ACCOUNT_ID --role roles/bigquery.user

gcloud projects add-iam-policy-binding $PROJECT_ID --member user:$ADMIN_ACCOUNT_ID --role roles/bigquery.dataEditor

gcloud projects add-iam-policy-binding $PROJECT_ID --member user:$ADMIN_ACCOUNT_ID --role roles/bigquery.jobUser

gcloud projects add-iam-policy-binding $PROJECT_ID --member user:$ADMIN_ACCOUNT_ID --role roles/composer.environmentAndStorageObjectViewer

gcloud projects add-iam-policy-binding $PROJECT_ID --member user:$ADMIN_ACCOUNT_ID --role roles/iam.serviceAccountUser

gcloud projects add-iam-policy-binding $PROJECT_ID --member user:$ADMIN_ACCOUNT_ID --role roles/iam.serviceAccountTokenCreator

gcloud projects add-iam-policy-binding $PROJECT_ID --member user:$ADMIN_ACCOUNT_ID --role roles/composer.admin

gcloud projects add-iam-policy-binding $PROJECT_ID --member user:$ADMIN_ACCOUNT_ID --role roles/iam.serviceAccountAdmin

gcloud projects add-iam-policy-binding $PROJECT_ID --member user:$ADMIN_ACCOUNT_ID --role roles/compute.networkAdmin

gcloud projects add-iam-policy-binding $PROJECT_ID --member user:$ADMIN_ACCOUNT_ID --role roles/compute.admin

gcloud projects add-iam-policy-binding $PROJECT_ID --member user:$ADMIN_ACCOUNT_ID --role roles/bigtable.admin

gcloud projects add-iam-policy-binding $PROJECT_ID --member user:$ADMIN_ACCOUNT_ID --role roles/notebooks.admin


# 2d. IAM role grants to Compute Engine Default Service User

gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:$PROJECT_NBR-compute@developer.gserviceaccount.com --role roles/editor

#2e. IAM role grants to Google Managed Service Account for Cloud Composer 2

gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:service-$PROJECT_NBR@cloudcomposer-accounts.iam.gserviceaccount.com --role roles/composer.ServiceAgentV2Ext


# 3. VPC Network & Subnet Creation

gcloud compute networks create $VPC_NM \
    --subnet-mode=custom \
    --bgp-routing-mode=regional \
    --mtu=1500

gcloud compute networks subnets create $SUBNET_NM\
     --network=$VPC_NM \
     --range=$SUBNET_CIDR \
     --region=$REGION \
     --enable-private-ip-google-access

# 4. Firewall rules creation

gcloud compute firewall-rules create $FIREWALL_NM \
	 --project=$PROJECT_ID  \
	 --network=projects/$PROJECT_ID/global/networks/$VPC_NM \
	 --description="Allows connection from any source to any instance on the network using custom protocols." \
	 --direction=INGRESS \
	 --priority=65534 \
	 --source-ranges=$SUBNET_CIDR \
	 --action=ALLOW --rules=all

# 5. Storage bucket creation

gsutil mb -p $PROJECT_ID -c STANDARD -l $REGION -b on gs://$GCS_BUCKET_NM
gsutil mb -p $PROJECT_ID -c STANDARD -l $REGION -b on gs://$PHS_BUCKET_NM
gsutil mb -p $PROJECT_ID -c STANDARD -l $REGION -b on gs://$DP_GCE_BUCKET_NM

#6. Copy code file into GCS bucket

gsutil cp ../pyspark/page_view_autoscaling.py gs://$GCS_BUCKET_NM/wikipedia-page-view/01-scripts-and-config/pyspark/

# 7. PHS creation

gcloud dataproc clusters create $HISTORY_SERVER_NAME \
  --project=${PROJECT_ID} \
  --region=${REGION} \
  --single-node \
  --image-version=2.0 \
  --subnet=${SUBNET_NM} \
  --enable-component-gateway \
  --properties=spark:spark.history.fs.logDirectory=gs://${PHS_BUCKET_NM}/phs/*/spark-job-history

# 8. BigQuery dataset creation

bq mk $BQ_DATASET_NAME

# 9. Dataproc Autoscaling Policy creation

gcloud dataproc autoscaling-policies import $ASP_NAME \
--source=autoscaling_policy.yaml \
--region=$REGION


# 10. Cloud Composer 2 creation

gcloud composer environments create $COMPOSER_ENV \
--location $REGION \
--environment-size small \
--service-account $COMPOSER_SA@$PROJECT_ID.iam.gserviceaccount.com \
--image-version composer-2.0.9-airflow-2.2.3 \
--network $VPC_NM \
--subnetwork $SUBNET_NM \
--web-server-allow-all \
--env-variables AIRFLOW_VAR_PROJECT_ID=$PROJECT_ID,AIRFLOW_VAR_REGION=$REGION,AIRFLOW_VAR_CODE_BUCKET=$GCS_BUCKET_NM,AIRFLOW_VAR_DGCE_CLUSTER=$DP_GCE_CLUSTER_NAME,AIRFLOW_VAR_PHS=$HISTORY_SERVER_NAME,AIRFLOW_VAR_SUBNET=$SUBNET_NM,AIRFLOW_VAR_UMSA=$UMSA_NAME

# 11. Dataproc Metastore Creation

gcloud metastore services create $METASTORE_NAME \
    --location=$REGION \
    --network=$VPC_NM \
    --port=$PORT \
    --tier=$TIER \
    --hive-metastore-version=$METASTORE_VERSION

# 12. Dataproc on GCE cluster creation

gcloud dataproc clusters create $DP_GCE_CLUSTER_NAME \
    --enable-component-gateway \
    --bucket $DP_GCE_BUCKET_NM \
    --region $REGION \
    --subnet $SUBNET_NM \
    --zone $DP_GCE_CLUSTER_ZONE \
    --master-machine-type n1-standard-4 \
    --master-boot-disk-size 500 \
    --num-workers 2 \
    --worker-machine-type n1-standard-4 \
    --worker-boot-disk-size 500 \
    --image-version 2.0-debian10 \
    --optional-components JUPYTER \
    --project $PROJECT_ID \
    --dataproc-metastore=projects/$PROJECT_ID/locations/$REGION/services/$METASTORE_NAME \
    --autoscaling-policy=$ASP_NAME

# 13. Big Table Instance Creation

gcloud bigtable instances create $BIGTABLE_INSTANCE_ID \
    --display-name=$BIGTABLE_DISPLAY_NAME \
    --cluster-storage-type=$CLUSTER_STORAGE_TYPE \
    --cluster-config=id=$CLUSTER_ID_1,zone=$CLUSTER_ZONE_1,nodes=$BIGTABLE_CLUSTER_NUM_NODES \
    --cluster-config=id=$CLUSTER_ID_2,zone=$CLUSTER_ZONE_2,autoscaling-min-nodes=$AUTOSCALING_MIN_NODES,autoscaling-max-nodes=$AUTOSCALING_MAX_NODES,autoscaling-cpu-target=$AUTOSCALING_CPU_TARGET,autoscaling-storage-target=$AUTOSCALING_STORAGE_TARGET
