#  Copyright 2022 Google LLC
# 
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
# 
#       http://www.apache.org/licenses/LICENSE-2.0
# 
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.


PROJECT_ID=`gcloud config list --format "value(core.project)" 2>/dev/null`
PROJECT_NBR=`gcloud projects describe $PROJECT_ID | grep projectNumber | cut -d':' -f2 |  tr -d "'" | xargs`
PROJECT_NAME=`gcloud projects describe ${PROJECT_ID} | grep name | cut -d':' -f2 | xargs`
GCP_ACCOUNT_NAME=`gcloud auth list --filter=status:ACTIVE --format="value(account)"`
LOCATION="us-central1"
VPC_NM="vpc-biglake"
SUBNET_NM="snet-biglake"
SUBNET_CIDR="10.0.0.0/16"
DATASET_NAME="biglake_dataset"
BQ_CONNECTION="biglake-gcs"
user_id=<your_user_id>

#1. Dataproc cluster creation

gcloud dataproc clusters create  ${user_id}-dataproc-cluster --enable-component-gateway --bucket=dataproc-bucket-${PROJECT_NBR} --region us-central1 --subnet "projects/${PROJECT_ID}/regions/${LOCATION}/subnetworks/${SUBNET_NM}" --zone us-central1-b --single-node --master-machine-type n1-standard-8 --master-boot-disk-type pd-ssd --master-boot-disk-size 1000 --image-version 2.0-debian10 --properties dataproc:dataproc.personal-auth.user=${GCP_ACCOUNT_NAME} --optional-components JUPYTER,ZEPPELIN --initialization-action-timeout=300 --initialization-actions gs://goog-dataproc-initialization-actions-${LOCATION}/connectors/connectors.sh,gs://goog-dataproc-initialization-actions-${LOCATION}/python/pip-install.sh --metadata spark-bigquery-connector-version=0.26.0,PIP_PACKAGES='pandas prophet plotly' --project ${PROJECT_ID}




