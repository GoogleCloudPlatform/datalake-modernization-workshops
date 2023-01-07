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

### 2. Declare Variables

Modify the location variable to your preferred GCP region.

```
PROJECT_ID=`gcloud config list --format "value(core.project)" 2>/dev/null`
PROJECT_NBR=`gcloud projects describe $PROJECT_ID | grep projectNumber | cut -d':' -f2 |  tr -d "'" | xargs`
PROJECT_NAME=`gcloud projects describe ${PROJECT_ID} | grep name | cut -d':' -f2 | xargs`
GCP_ACCOUNT_NAME=`gcloud auth list --filter=status:ACTIVE --format="value(account)"`
GCP_MULTI_REGION="US"
LOCATION=<Your GCP region here>


echo "PROJECT_ID=$PROJECT_ID"
echo "PROJECT_NBR=$PROJECT_NBR"
echo "PROJECT_NAME=$PROJECT_NAME"
echo "GCP_ACCOUNT_NAME=$GCP_ACCOUNT_NAME"
echo "GCP_MULTI_REGION=$GCP_MULTI_REGION"
echo "LOCATION=$LOCATION"
```

<hr>

### 3. Terraform Provisioning

#### 3.1. Provision the lab resources

```
cd ~/table-format-lab-delta/00-scripts-and-config/terraform-user
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

## C. Create a Dataproc Interactive Spark Session

Edit location and name variables as appropriate-
```
PROJECT_ID=`gcloud config list --format "value(core.project)" 2>/dev/null`
PROJECT_NBR=`gcloud projects describe $PROJECT_ID | grep projectNumber | cut -d':' -f2 |  tr -d "'" | xargs`
GCP_ACCOUNT_NAME=`gcloud config list account --format "value(core.account)" | cut -d'@' -f1 | xargs`
SESSION_NAME="delta-lake-lab"
LOCATION=<Your GCP region here>
NAME=<Your name here>
HISTORY_SERVER_NAME="dll-sphs-${PROJECT_NBR}"
METASTORE_NAME="dll-hms-${PROJECT_NBR}"
SUBNET="dll-snet"
NOTEBOOK_BUCKET="gs://dll-code-bucket-${PROJECT_NBR}-${NAME}"


gcloud beta dataproc sessions create spark $NAME-$SESSION_NAME-$RANDOM  \
--project=${PROJECT_ID} \
--location=${LOCATION} \
--property=spark.jars.packages="io.delta:delta-core_2.13:2.1.0" \
--history-server-cluster="projects/$PROJECT_ID/regions/$LOCATION/clusters/${HISTORY_SERVER_NAME}" \
--metastore-service="projects/$PROJECT_ID/locations/$LOCATION/services/${METASTORE_NAME}" \
--property="spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension" \
--property="spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog" \
--service-account="s8s-lab-sa@tgs-internal-gcpgtminit-dev-01.iam.gserviceaccount.com" \
--version 2.0.3 \
--subnet=$SUBNET 


```
The author typcially has two sessions handly to expedite switching across notebooks.

<hr>


## D. Connect to Vertex AI Workbench in the Cloud Console

The Terraform creates a Vertex AI Workbench managed notebook instance and loads the Delta Lake notebooks.
Navigate into the managed notebook instance, open the first Delta Lake notebook (DeltaLakeLab-1.ipynb), and pick a Spark kernel - the one created by #C above.

<hr>

## E. Lab guide
Note: The notebooks have scope and narratives defined in them, so there is no explicit lab guide for this lab. The features of Delta Lake covered is listed [here](README.md#features-covered)<br>

Run through each notebook, sequentially.<br>
Review the Delta Lake documentation at - <br>
https://docs.delta.io/latest/index.html <br>

**Note:** Table clones are not yet availabe outside Databricks - https://github.com/delta-io/delta/issues/1387. Therefore, notebook 8, does not work, its been left as a placeholder.

## F. Dont forget to 
Shut down/delete resources when done to avoid unnecessary billing.

<hr>

## G. Release History

| Date | Details | 
| -- | :--- | 
| 20221022 |  Notebooks 1-9, + Terraform |

