'
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
 '

PROJECT_ID=`gcloud config list --format "value(core.project)" 2>/dev/null`
PROJECT_NBR=`gcloud projects describe $PROJECT_ID | grep projectNumber | cut -d':' -f2 |  tr -d "'" | xargs`
PROJECT_NAME=`gcloud projects describe ${PROJECT_ID} | grep name | cut -d':' -f2 | xargs`
GCP_ACCOUNT_NAME=`gcloud auth list --filter=status:ACTIVE --format="value(account)"`
LOCATION="us-central1"
GCP_MULTI_REGION="US"
RLS_USERNAME1=<user_with_access_to_us_data>          # Please insert the whole username for eg: username@example.com
RLS_USERNAME2=<user_with_access_to_australia_data>   # Please insert the whole username for eg: username@example.com
CLS_USERNAME=<user_with_no_access_to_finanical_data> # Please insert the whole username for eg: username@example.com

VPC_NM=vpc-biglake
SUBNET_NM=snet-biglake
SUBNET_CIDR=10.0.0.0/16
DATASET_NAME=biglake_dataset
BQ_CONNECTION=biglake-gcs

# # 1. Update Organization Policies

# gcloud resource-manager org-policies enable-enforce compute.disableSerialPortLogging --project=$PROJECT_ID
# gcloud resource-manager org-policies enable-enforce compute.requireOsLogin --project=$PROJECT_ID
# gcloud resource-manager org-policies enable-enforce compute.requireShieldedVm --project=$PROJECT_ID
# gcloud resource-manager org-policies enable-enforce compute.vmCanIpForward --project=$PROJECT_ID
# gcloud resource-manager org-policies enable-enforce compute.vmExternalIpAccess --project=$PROJECT_ID
# gcloud resource-manager org-policies enable-enforce compute.restrictVpcPeering --project=$PROJECT_ID

# 2. Enable Google APIs

gcloud services enable dataproc.googleapis.com
gcloud services enable bigqueryconnection.googleapis.com
gcloud services enable bigquerydatapolicy.googleapis.com
gcloud services enable storage-component.googleapis.com
gcloud services enable bigquerystorage.googleapis.com
gcloud services enable datacatalog.googleapis.com
gcloud services enable dataplex.googleapis.com
gcloud services enable bigquery.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable cloudidentity.googleapis.com

# 3. Create VPC network & subnet

# 3.a VPC Network
gcloud compute networks create $VPC_NM \
    --subnet-mode=custom \
    --description="Default network" \
    --bgp-routing-mode=regional \
    --mtu=1460

# 3.b Subnet
gcloud compute networks subnets create $SUBNET_NM\
    --network=$VPC_NM \
    --range=$SUBNET_CIDR \
    --region=$LOCATION \
    --enable-private-ip-google-access

# 4. Create firewall rules
gcloud compute firewall-rules create subnet-firewall \
 --project=$PROJECT_ID  \
 --network=projects/$PROJECT_ID/global/networks/$VPC_NM \
 --allow tcp \
 --allow icmp \
 --allow udp \
 --source-ranges=$SUBNET_CIDR

# 5. Creation of a router
gcloud compute routers create nat-router \
    --project=$PROJECT_ID \
    --network=projects/$PROJECT_ID/global/networks/$VPC_NM \
    --region=$LOCATION

# 6. Creation of a NAT
gcloud compute routers nats create nat-config \
   --router=nat-router \
   --region=$LOCATION \
   --auto-allocate-nat-external-ips \
   --nat-all-subnet-ip-ranges

# 7. Grant IAM role project veiwer to users

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=user:${RLS_USERNAME1} --role=roles/viewer

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=user:${RLS_USERNAME2} --role=roles/viewer

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=user:${CLS_USERNAME} --role=roles/viewer

# 6. Grant IAM role dataproc editor to users\

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=user:${RLS_USERNAME1} --role=roles/dataproc.editor

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=user:${RLS_USERNAME2} --role=roles/dataproc.editor

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=user:${CLS_USERNAME} --role=roles/dataproc.editor

# 6. Grant IAM role service Account User to users\

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=user:${RLS_USERNAME1} --role=roles/iam.serviceAccountUser

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=user:${RLS_USERNAME2} --role=roles/iam.serviceAccountUser

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=user:${CLS_USERNAME} --role=roles/iam.serviceAccountUser

# 6. Grant IAM role storage object Admin to users\

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=user:${RLS_USERNAME1} --role=roles/storage.objectAdmin

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=user:${RLS_USERNAME2} --role=roles/storage.objectAdmin

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=user:${CLS_USERNAME} --role=roles/storage.objectAdmin

# 8. Create a Dataproc cluster bucket\

gsutil mb -p $PROJECT_ID -c STANDARD -l $LOCATION -b on gs://dataproc-bucket-${PROJECT_NBR}

# 9. Storage admin permissions granting to the Dataproc (common) bucket

gsutil iam ch user:${RLS_USERNAME1}:admin gs://dataproc-bucket-${PROJECT_NBR}
gsutil iam ch user:${RLS_USERNAME2}:admin gs://dataproc-bucket-${PROJECT_NBR}
gsutil iam ch user:${CLS_USERNAME}:admin gs://dataproc-bucket-${PROJECT_NBR}

# 10. Adding icecreamsales dataset and notebook in to Dataproc (common) bucket

gsutil cp ../../01-datasets/IceCreamSales.csv gs://dataproc-bucket-${PROJECT_NBR}
gsutil cp ../notebook/IceCream.ipynb gs://dataproc-bucket-${PROJECT_NBR}/notebooks/jupyter/

# 11. Dataproc Worker role granting to the compute engine default service account

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=serviceAccount:${PROJECT_NBR}-compute@developer.gserviceaccount.com --role=roles/dataproc.worker

# 12. Creation of BigQuery dataset

bq --location=$LOCATION mk \
    --dataset \
    --description="Dataset for BigLake Demo" \
     $PROJECT_ID:"biglake_dataset"

# 13.Creation of BigQuery connection

bq mk --connection --display_name='big lake' --connection_type=CLOUD_RESOURCE \
  --project_id=$PROJECT_ID --location=$LOCATION \
  biglake-gcs