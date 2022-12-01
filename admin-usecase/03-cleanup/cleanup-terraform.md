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

# Terraform Cleanup

This module includes the steps for deleting the GCP resources created using Terraform for the GCP portfolio walkthrough and Autoscaling usecase using Terraform modules<br>

1. Delete VPC Network, Subnet and Firewall Rule<br>
2. Delete the User Managed Service Account<br>
3. Delete the User Managed Composer Service Account<br>
4. Delete Composer environment<br>
5. Delete GCS buckets<br>
6. Delete Dataproc Metastore<br>
7. Delete Dataproc Cluster on GCE<br>
8. Delete Persistent Spark History Server cluster<br>
9. Delete BigQuery dataset<br>
10. Delete BigTable instance<br>
11. Delete Vertex AI Managed notebook instance

## 0. Prerequisites

#### 1. Attach cloud shell to your project.
Open Cloud shell or navigate to [shell.cloud.google.com](https://shell.cloud.google.com). <br>
Run the below command to set the project to cloud shell terminal:

```
gcloud config set project <enter your project id here>
```

#### 2. Navigate to Terraform Directory.

Navigate to the Terraform directory in Cloud Shell by running the following command:<br>

```
cd admin-usecase/01-scripts-and-config/terraform
```

#### 3. Terraform State Files.

Once in the Terraform directory, run the following command in cloud shell after ensuring you have the 'terraform.tfstate', 'main.tf', 'variables.tf' and 'versions.tf' files.

## 1. Running the Terraform Script to destroy all resources created by Terraform script

Run the following commands in cloud shell to execute the terraform script in destroy mode: <br>

```
PROJECT_ID=$(gcloud config get-value project)                                                   
PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} | grep projectNumber | cut -d':' -f2 |  tr -d "'" | xargs)
GCP_ACCOUNT_NAME=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")

terraform destroy \
  -var="project_id=${PROJECT_ID}" \
  -var="project_number=${PROJECT_NUMBER}" \
  -var="gcp_account_name=${GCP_ACCOUNT_NAME}" \
  -auto-approve
```

Once the terraform script completes execution successfully, all resources created for the usecase by the Terraform script will be deleted.
