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

LAB_PREFIX="dll"
PROJECT_ID=`gcloud config list --format "value(core.project)" 2>/dev/null`
PROJECT_NBR=`gcloud projects describe $PROJECT_ID | grep projectNumber | cut -d':' -f2 |  tr -d "'" | xargs`
GCP_ACCOUNT_NAME=`gcloud auth list --filter=status:ACTIVE --format="value(account)"`
GCP_MULTI_REGION="US"
LOCATION="<YOUR_GCP_REGION_HERE>"
VPC_NM=${LAB_PREFIX}-vpc
SUBNET_NM="dll-snet"
NAT_NM=${LAB_PREFIX}-nat
NAT_ROUTER_NM=${LAB_PREFIX}-nat-router
SUBNET_CIDR=10.0.0.0/16
PSA_IP_LENGTH=16
DATASET_NAME=${LAB_PREFIX}loan_bqds
UMSA=${LAB_PREFIX}-lab-sa
UMSA_FQN=${UMSA}@${PROJECT_ID}.iam.gserviceaccount.com
ADMIN_UPN_FQN=${GCP_ACCOUNT_NAME}
DPMS_NM=${LAB_PREFIX}-hms-${PROJECT_NBR}
SPHS_NM=${LAB_PREFIX}-sphs-${PROJECT_NBR}
SPHS_BUCKET_NM=${LAB_PREFIX}-sphs-bucket-${PROJECT_NBR}

# 1a Creating Service account

gcloud iam service-accounts create dll-lab-sa \
    --description="User Managed Service Account" \
    --display-name="dll-lab-sa"

# 1b Granting roles to the service account
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:dll-lab-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:dll-lab-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountTokenCreator"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:dll-lab-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/storage.objectAdmin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:dll-lab-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:dll-lab-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/metastore.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:dll-lab-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/metastore.editor"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:dll-lab-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/dataproc.editor"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:dll-lab-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/dataproc.worker"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:dll-lab-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/bigquery.dataEditor"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:dll-lab-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/bigquery.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:dll-lab-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:dll-lab-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/logging.logWriter"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:dll-lab-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/cloudbuild.builds.editor"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:dll-lab-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/aiplatform.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:dll-lab-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/aiplatform.viewer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:dll-lab-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/aiplatform.user"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:dll-lab-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/viewer"

# 1c granting impersonating roles to user:

gcloud iam service-accounts add-iam-policy-binding \
    dll-lab-sa@$PROJECT_ID.iam.gserviceaccount.com \
    --member="user:$GCP_ACCOUNT_NAME" \
    --role="roles/iam.serviceAccountUser"

gcloud iam service-accounts add-iam-policy-binding \
    dll-lab-sa@$PROJECT_ID.iam.gserviceaccount.com \
    --member="user:$GCP_ACCOUNT_NAME" \
    --role="roles/iam.serviceAccountTokenCreator"

gcloud projects add-iam-policy-binding $PROJECT_ID --member user:$GCP_ACCOUNT_NAME --role roles/compute.networkAdmin

gcloud projects add-iam-policy-binding $PROJECT_ID --member user:$GCP_ACCOUNT_NAME --role roles/compute.securityAdmin

gcloud projects add-iam-policy-binding $PROJECT_ID --member user:$GCP_ACCOUNT_NAME --role roles/storage.admin

gcloud projects add-iam-policy-binding $PROJECT_ID --member user:$GCP_ACCOUNT_NAME --role roles/dataproc.admin

gcloud projects add-iam-policy-binding $PROJECT_ID --member user:$GCP_ACCOUNT_NAME --role roles/metastore.admin


# 2a VPC Network
gcloud compute networks create $VPC_NM \
    --subnet-mode=custom \
    --description="Default network" \
    --bgp-routing-mode=regional \
    --mtu=1460

# 2b Subnet
gcloud compute networks subnets create $SUBNET_NM\
    --network=$VPC_NM \
    --range=$SUBNET_CIDR \
    --region=$LOCATION \
    --enable-private-ip-google-access

# 2c. Create firewall rules
gcloud compute firewall-rules create subnet-firewall \
--project=$PROJECT_ID  \
--network=projects/$PROJECT_ID/global/networks/$VPC_NM \
--description="Creates firewall rule to allow ingress from within Spark subnet on all ports, all protocols" \
--direction=INGRESS \
--priority=65534 \
--source-ranges=$SUBNET_CIDR \
--action=ALLOW --rules=all

# 2d. Creation of a router
gcloud compute routers create nat-router \
    --project=$PROJECT_ID \
    --network=projects/$PROJECT_ID/global/networks/$VPC_NM \
    --region=$LOCATION

# 2e. Creation of a NAT
gcloud compute routers nats create nat-config \
   --router=nat-router \
   --region=$LOCATION \
   --auto-allocate-nat-external-ips \
   --nat-all-subnet-ip-ranges

# 2f. PSA creation
gcloud compute addresses create dll-private-service-access-ip \
    --global \
    --purpose=VPC_PEERING \
    --prefix-length=16 \
    --description="DESCRIPTION" \
    --network=$VPC_NM

gcloud services vpc-peerings connect \
    --service=servicenetworking.googleapis.com \
    --ranges="dll-private-service-access-ip" \
    --network=$VPC_NM \
    --project=$PROJECT_ID

# 3a Creating of staging bucket for phs cluster:
gcloud storage buckets create gs://${SPHS_BUCKET_NM} --project=$PROJECT_ID --default-storage-class=STANDARD --location=$LOCATION --uniform-bucket-level-access

# 3b Creating of phs cluster:
gcloud dataproc clusters create dll-sphs-${PROJECT_NBR} \
  --project=${PROJECT_ID} \
  --region=${LOCATION} \
  --single-node \
  --bucket=dll-sphs-bucket-${PROJECT_NBR} \
  --subnet=${SUBNET_NM} \
  --image-version=2.0 \
  --enable-component-gateway \
  --properties=spark:spark.history.fs.logDirectory=gs://${SPHS_BUCKET_NM}/phs/*/spark-job-history \
  --properties=dataproc:job.history.to-gcs.enabled=true \
  --properties=mapred:mapreduce.jobhistory.read-only.dir-pattern=gs://${SPHS_BUCKET_NM}/*/mapreduce-job-history/done \
  --service-account=dll-lab-sa@${PROJECT_ID}.iam.gserviceaccount.com \
  --scopes=cloud-platform

# 4a Creating of Metastore
gcloud metastore services create $DPMS_NM \
    --location=$LOCATION \
    --network=$VPC_NM \
    --port=9080 \
    --tier="DEVELOPER" \
    --hive-metastore-version=3.1.2
