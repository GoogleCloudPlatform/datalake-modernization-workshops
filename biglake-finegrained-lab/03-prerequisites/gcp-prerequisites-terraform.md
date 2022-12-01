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

## 1. Provision the GCP environment 

This section covers creating the environment via Terraform from Cloud Shell. 
1. Launch cloud shell
2. Clone this git repo
3. Provision foundational resources such as Google APIs and Organization Policies
4. Provision the GCP data Analytics services and their dependencies for the lab

### 1.1. Products/services used in the lab
The following services and resources will be created via Terraform scripts:

1. VPC, Subnetwork and NAT rules
2. IAM groups for USA and Australia
3. IAM permissions for user principals and Google Managed default service accounts
4. GCS buckets, for each user principal and for Dataproc temp bucket
5. Dataplex Policy for Column level Access
6. BigQuery Dataset, Table and Row Level Policies

### 1.2. Uploading Terraform scripts, PySpark scripts and datasets to cloud shell

Run the following commands in Cloud Shell to clone the repository to your cloud shell instance:

```
cd ~
git clone https://github.com/GoogleCloudPlatform/datalake-modernization-workshops
cd datalake-modernization-workshops/
mv biglake-finegrained-lab/ ~/
cd ..
```

### 1.3. About the Terraform scripts

#### 1.1.1. Review the Terraform directory structure (& optionally, the content)

Browse and familiarize yourself with the layout and optionally, review the scripts for an understanding of the constructs as well as how dependencies are managed.

#### 1.1.2. What's involved with provisioning with Terraform

1. Define variables for use with Terraform
2. Initialize Terraform
3. Run a Terraform plan & study it
4. Apply the Terraform to create the environment
5. Validate the environment created

#### 1.1.3. Admin Roles

To setup the infrastructure, please ensure you have the following GCP roles: Project IAM Admin, Policy Tag Admin, Compute Network Admin, Compute Admin, Storage Admin, BigQuery Admin, Service Usage Admin


### 1.4 Enabling the APIs

- Please ensure the following APIs are enabled before you proceed: 

```
dataproc.googleapis.com
bigqueryconnection.googleapis.com
bigquerydatapolicy.googleapis.com
storage-component.googleapis.com
bigquerystorage.googleapis.com
datacatalog.googleapis.com
dataplex.googleapis.com
bigquery.googleapis.com
cloudresourcemanager.googleapis.com
cloudidentity.googleapis.com
```

### 1.5. Provision the environment

#### 1.5.1. Define variables for use

Modify the below as appropriate for your deployment..e.g. region, zone etc. Be sure to use the right case for GCP region & zone.<br>
Make the corrections as needed below and then cut and paste the text into the Cloud Shell Session. <br>

```
PROJECT_ID=`gcloud config list --format "value(core.project)" 2>/dev/null`
PROJECT_NBR=`gcloud projects describe $PROJECT_ID | grep projectNumber | cut -d':' -f2 |  tr -d "'" | xargs`
PROJECT_NAME=`gcloud projects describe ${PROJECT_ID} | grep name | cut -d':' -f2 | xargs`
LOCATION="us-central1"
RLS_USERNAME1=<user_with_access_to_us_data>          # Please insert the whole username for eg: username@example.com
RLS_USERNAME2=<user_with_access_to_australia_data>   # Please insert the whole username for eg: username@example.com
CLS_USERNAME=<user_with_no_access_to_finanical_data> # Please insert the whole username for eg: username@example.com

echo "PROJECT_ID=$PROJECT_ID"
echo "PROJECT_NBR=$PROJECT_NBR"
echo "LOCATION=$LOCATION"
echo "RLS_USERNAME1=$RLS_USERNAME1"
echo "RLS_USERNAME2=$RLS_USERNAME2"
echo "CLS_USERNAME=$CLS_USERNAME"
```


#### 1.5.2. Provision data analytics services & dependencies

##### 1.5.2.1. Initialize Terraform

Needs to run in cloud shell from ~/biglake-finegrained-lab/demo
```
cd ~/biglake-finegrained-lab/00-scripts-and-config/terraform
terraform init
```

##### 1.5.2.2. Review the Terraform deployment plan

Needs to run in cloud shell from ~/biglake/00-scripts-and-config/terraform
```
terraform plan \
  -var="project_id=${PROJECT_ID}" \
  -var="project_nbr=${PROJECT_NBR}" \
  -var="location=${LOCATION}" \
  -var="rls_username1=${RLS_USERNAME1}" \
  -var="rls_username2=${RLS_USERNAME2}" \
  -var="cls_username=${CLS_USERNAME}"   
```

##### 1.5.2.3. Terraform provision the data analytics services & dependencies

Needs to run in cloud shell from ~/biglake/00-scripts-and-config/terraform 
 <br>

**Time taken to complete:** <10 minutes

```
terraform apply \
  -var="project_id=${PROJECT_ID}" \
  -var="project_nbr=${PROJECT_NBR}" \
  -var="location=${LOCATION}" \
  -var="rls_username1=${RLS_USERNAME1}" \
  -var="rls_username2=${RLS_USERNAME2}" \
  -var="cls_username=${CLS_USERNAME}" \
  --auto-approve
```
<hr>

## 2. Validate the Terraform deployment

From your default GCP account (NOT to be confused with the three users we created), go to the Cloud Console, and validate the creation of the following resources-

### 2.1. IAM users
Validate IAM users in the project, by navigating on Cloud Console to -
1. Youself
2. rls_user1
3. rls_user2
4. cls_user


### 2.2. IAM roles

a) User Principles:<br>
1. rls_user1: Viewer, Service Account User, Storage Object Admin, and Dataproc Editor
2. rls_user2: Viewer, Service Account User, Storage Object Admin, and Dataproc Editor
3. cls_user: Viewer, Service Account User, Storage Object Admin, and Dataproc Editor
<br>

b) Google Managed Compute Engine Default Service Account:<br>
4. YOUR_PROJECT_NUMBER-compute@developer.gserviceaccount.com: Dataproc Worker
<br>

c) BigQuery Connection Default Service Account:<br>
Covered below

### 2.3. GCS buckets
1. dataproc-bucket-YOUR_PROJECT_NUMBER

### 2.4. GCS bucket permissions
1. dataproc-bucket-YOUR_PROJECT_NUMBER: Storage Admin to all three users created

### 2.5. Network resources
Validate the creation of-
1. VPC called vpc-biglake
2. Subnet called snet-biglake
3. Firewall called subnet-firewall
4. Cloud Router called nat-router
5. Cloud NAT gateway called nat-config


### 2.6. Policy Tag Taxonomies
Navigate to Dataplex->Policy Tag Taxonomies and you should see a policy tag called -
1. Business-Critical-YOUR_PROJECT_NUMBER

### 2.7. Policy Tag
Click on the Policy Tag Taxonomy in Dataplex and you should see a Policy Tag called -
1. Financial Data

### 2.8. User association with Policy Tag
Each of the two users rls_user1 & rls_user2 are granted datacatalog.categoryFineGrainedReader tied to the Policy Tag created

### 2.9. BigLake Connection
Navigate to BigQuery in the Cloud Console and you should see, under "External Connections" -
1. An external connection called 'us-central1.biglake.gcs'

### 2.10. BigQuery Dataset
In the BigQuery console, you should see a dataset called-
1. biglake_dataset

### 2.11. IAM role to BigQuery External Connection Default Service Account
bqcx-YOUR_PROJECT_NUMBER@gcp-sa-bigquery-condel.iam.gserviceaccount.com: Storage Object Viewer	

### 2.12. BigLake Table
A BigLake table called IceCreamSales -
1. That uses the Biglake connection 'us-central1.biglake.gcs'
2. With CSV configuration 
3. On CSV file at - gs://dataproc-bucket-YOUR_PROJECT_NUMBER/IceCreamSales.csv
4. With a set schema
5. With column 'Discount' tied to the Policy Tag created -'Financial Data'
6. With column 'Net_Revenue' tied to the Policy Tag created -'Financial Data'

![PICT3](./images/bigquery.png) 

### 2.13. Row Access Policies
Create Row Access Policies, one for each user - rls_user1 and rls_user2 -
1. Row Access Policy for the BigLake table IceCreamSales called 'Australia_filter' associated with the user rls_user1 on filter Country="Australia"
2. Row Access Policy for the BigLake table IceCreamSales called 'US_filter' associated with the IAM group rls_user2 on filter Country="United States"

<hr>

## 3. Fine-grained Access Control Lab powered by BigLake

So far, you completed the environment setup and validation. In this sub-module, you will learn the fine grained access control made possible by BigLake.

### 3.1. Principle of Least Privilege: Administrators should not have access to data
In your current default user login, navigate to BigQuery on the Cloud Console. You should see a dataset biglake_dataset and a table called "biglake_dataset.IceCreamSales".
<br>
Run the query below in the BQ query UI-

```
SELECT * FROM `biglake_dataset.IceCreamSales` LIMIT 1000
```

You should not see any results, infact your should see the following error-
```
Access Denied: BigQuery BigQuery: User has neither fine-grained reader nor masked get permission to get data protected by policy tag "Business-Critical-225879788342 : Financial Data" on columns biglake_dataset.IceCreamSales.Discount, biglake_dataset.IceCreamSales.Net_Revenue.
```

This is a demonstration of applying **principle of least privilege** - administrators should not have access to data with in the IceCreamSales table.

### 4. To destroy the deployment

Congratulations on completing the lab!<br>

You can (a) shutdown the project altogether in GCP Cloud Console or (b) use Terraform to destroy. Use (b) at your own risk as its a little glitchy while (a) is guaranteed to stop the billing meter pronto.
<br>
Needs to run in cloud shell from ~/biglake/00-scripts-and-config/terraform 
```
cd ~/biglake-finegrained-lab/demo
terraform destroy \
  -var="project_id=${PROJECT_ID}" \
  -var="project_nbr=${PROJECT_NBR}" \
  -var="location=${LOCATION}" \
  -var="rls_username1=${RLS_USERNAME1}" \
  -var="rls_username2=${RLS_USERNAME2}" \
  -var="cls_username=${CLS_USERNAME}" \
  --auto-approve
 ```

<hr>

This concludes the lab. 

<hr>

