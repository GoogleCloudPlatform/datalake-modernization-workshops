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

This module includes all prerequisites for running the Data Engineering usecase using Google Cloud Shell 

[1. Declare variables](01-gcp-prerequisites-cloud-shell.md#1-declare-variables)<br>
[2. Update Organization Policies](01-gcp-prerequisites-cloud-shell.md#2-update-organization-policies)<br>
[3. Enable Google APIs](01-gcp-prerequisites-cloud-shell.md#3-enable-google-apis)<br>
[4. Network Configuration](01-gcp-prerequisites-cloud-shell.md#4-network-configuration)<br>
[5. Create a User Managed Service Account](01-gcp-prerequisites-cloud-shell.md#5-create-a-user-managed-service-account)<br>
[6. Grant IAM permissions for UMSA](01-gcp-prerequisites-cloud-shell.md#6-grant-iam-permissions-for-umsa)<br>
[7. Grant IAM permissions for Compute Engine Service Account](01-gcp-prerequisites-cloud-shell.md#7-grant-iam-permissions-for-compute-engine-service-account)<br>
[8. Roles required for the Hackfest Attendees](01-gcp-prerequisites-cloud-shell.md#8-roles-required-for-the-hackfest-attendees)

## 0. Prerequisites 

#### 1. Create a new project or select an existing project.
Note the project number and project ID. <br>
We will need this for the rest fo the lab

#### 2. IAM Roles needed to execute the prereqs
Ensure that you have **Security Admin**, **Project IAM Admin**, **Service Usage Admin**, **Service Account Admin** and **Role Administrator** roles and then grant yourself the following additional roles:<br>

```
Storage Admin
Metastore Admin
Dataproc Admin
BigQuery Admin
BigQuery User
BigQuery DataEditor
BigQuery JobUser
Environment and Storage Object Viewer
Service Account User
Service Account Token Creator
Composer Admin
Compute Network Admin
Compute Admin
```

This is needed for creating the GCP resources and granting access to attendees.

#### 3. Attach cloud shell to your project.
Open Cloud shell or navigate to [shell.cloud.google.com](https://shell.cloud.google.com). <br>
Run the below command to set the project to cloud shell terminal:

```
gcloud config set project <enter your project id here>

```

## 1. Declare variables 

We will use these throughout the lab. <br>
Run the below in cloud shell against the project you selected-

```
PROJECT_ID=$(gcloud config get-value project)
PROJECT_NBR=$(gcloud projects list --filter="$(gcloud config get-value project)" --format="value(PROJECT_NUMBER)")
VPC=<your_vpc_name>
REGION=<region_where_resources_will_be_created>
SUBNET=<your_subnet_name>
SUBNET_CIDR=<your_subnet_cidr> #Example: "10.0.0.0/16"
FIREWALL=<your_firewall_name>
UMSA=<your_umsa_name>
```

## 2. Update Organization Policies

Run the following commands in cloud shell to update the organization policies:<br>

```
gcloud resource-manager org-policies enable-enforce compute.disableSerialPortLogging --project=$PROJECT_ID
gcloud resource-manager org-policies enable-enforce compute.requireOsLogin --project=$PROJECT_ID
gcloud resource-manager org-policies enable-enforce compute.requireShieldedVm --project=$PROJECT_ID
gcloud resource-manager org-policies enable-enforce compute.vmCanIpForward --project=$PROJECT_ID
gcloud resource-manager org-policies enable-enforce compute.vmExternalIpAccess --project=$PROJECT_ID
gcloud resource-manager org-policies enable-enforce compute.restrictVpcPeering --project=$PROJECT_ID
```

## 3. Enable Google APIs

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

## 4. Network Configuration

Run the commands below to create the networking entities required for the hands on lab.

#### 4.1. Create a VPC

```
gcloud compute networks create $VPC \
    --subnet-mode=custom \
    --bgp-routing-mode=regional \
    --mtu=1500
```

List VPCs with:

```
gcloud compute networks list
```

Describe your network with:

```
gcloud compute networks describe $VPC
```

#### 4.2. Create a subnet in the newly created VPC with private google access

```
gcloud compute networks subnets create $SUBNET \
     --network=$VPC \
     --range=$SUBNET_CIDR \
     --region=$REGION \
     --enable-private-ip-google-access
```

#### 4.3. Create firewall rules
Intra-VPC, allow all communication

```
gcloud compute firewall-rules create $FIREWALL \
 --project=$PROJECT_ID  \
 --network=projects/$PROJECT_ID/global/networks/$VPC \
 --description="Allows connection from any source to any instance on the network using custom protocols." \
 --direction=INGRESS \
 --priority=65534 \
 --source-ranges=$SUBNET_CIDR \
 --action=ALLOW --rules=all
```

## 5. Create a User Managed Service Account

```
gcloud iam service-accounts create $UMSA \
 --description="User Managed Service Account" \
 --display-name "User Managed Service Account"

```

## 6. Grant IAM Permissions for UMSA

#### 6.1.a. Basic role for UMSA  

```
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:$UMSA@$PROJECT_ID.iam.gserviceaccount.com --role roles/viewer

```

#### 6.1.b. Storage Admin role for UMSA

```
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:$UMSA@$PROJECT_ID.iam.gserviceaccount.com --role roles/storage.admin

```

#### 6.1.c. Dataproc Editor role for UMSA

```
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:$UMSA@$PROJECT_ID.iam.gserviceaccount.com --role roles/dataproc.editor

```

#### 6.1.d. Dataproc Worker role for UMSA

```
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:$UMSA@$PROJECT_ID.iam.gserviceaccount.com --role roles/dataproc.worker

```

#### 6.1.e. BigQuery Data Editor role for UMSA

```
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:$UMSA@$PROJECT_ID.iam.gserviceaccount.com --role roles/bigquery.dataEditor

```

#### 6.1.f. BigQuery User role for UMSA

```
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:$UMSA@$PROJECT_ID.iam.gserviceaccount.com --role roles/bigquery.user

```

#### 6.1.g. BigQuery Admin role for UMSA

```
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:$UMSA@$PROJECT_ID.iam.gserviceaccount.com --role roles/notebooks.admin

```

## 7. Grant IAM Permissions for Compute Engine Service Account

#### 7.1.a. Basic role for Compute Engine Service Account

```
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:$PROJECT_NBR-compute@developer.gserviceaccount.com --role roles/editor
```

## 8. Roles required for the Hackfest Attendees

Please grant the following GCP roles to all attendees to execute the hands-on labs:<br>

```
Viewer
Dataproc Editor
BigQuery Data Editor
Service Account User
Storage Admin
Environment User and Storage Object Viewer
Notebooks Runner
``` 