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
 
## A. Environment Provisioning

### 1. Clone the repo

Upload the repository to the Google Cloud Shell instance

<hr>

### 2. IAM Roles needed to execute the prereqs
Ensure that you have **Security Admin**, **Project IAM Admin**, **Service Usage Admin**, **Service Account Admin** and **Role Administrator** roles. This is needed for creating the GCP resources and granting access to attendees.

<hr>

### 3. Declare Variables

Modify the location variable to your preferred GCP region.

```
PROJECT_ID=`gcloud config list --format "value(core.project)" 2>/dev/null`
PROJECT_NBR=`gcloud projects describe $PROJECT_ID | grep projectNumber | cut -d':' -f2 |  tr -d "'" | xargs`
PROJECT_NAME=`gcloud projects describe ${PROJECT_ID} | grep name | cut -d':' -f2 | xargs`
GCP_ACCOUNT_NAME=`gcloud auth list --filter=status:ACTIVE --format="value(account)"`
GCP_MULTI_REGION="US"
LOCATION=<Enter your GCP region here>


echo "PROJECT_ID=$PROJECT_ID"
echo "PROJECT_NBR=$PROJECT_NBR"
echo "PROJECT_NAME=$PROJECT_NAME"
echo "GCP_ACCOUNT_NAME=$GCP_ACCOUNT_NAME"
echo "GCP_MULTI_REGION=$GCP_MULTI_REGION"
echo "LOCATION=$LOCATION"
```

<hr>

### 4. Terraform Provisioning

#### 4.1. Provision the lab resources

```
cd ~/table-format-lab-delta/00-scripts-and-config/terraform-admin
terraform init

```

```
terraform plan \
  -var="project_id=${PROJECT_ID}" \
  -var="project_nbr=${PROJECT_NBR}" \
  -var="location=${LOCATION}" \
  -var="gcp_account_name=${GCP_ACCOUNT_NAME}"
 ```
 
 ```
terraform apply \
  -var="project_id=${PROJECT_ID}" \
  -var="project_nbr=${PROJECT_NBR}" \
  -var="location=${LOCATION}" \
  -var="gcp_account_name=${GCP_ACCOUNT_NAME}" \
  --auto-approve
 ```

<hr>

### 5. Roles required for the Hackfest Attendees

Please grant the following GCP roles to all attendees to execute the hands-on labs:<br>

```
Artifact Registry Writer
BigQuery Admin
Dataproc Editor
Dataproc Worker
Notebooks Admin
Notebooks Runner
Service Account User
Storage Admin
Vertex AI administrator
```
