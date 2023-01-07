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

### 2. Cloud-shell Provisioning

#### 2.1. Provisioning the lab resources

```
cd ~/table-format-lab-delta/00-scripts-and-config/cloud-shell
```

Edit the value of the following variables from the 'cloud-shell-execution-user.md' file <br>

```
LOCATION="<YOUR_GCP_REGION_HERE>"
NAME="<YOUR_NAME_HERE>"
```

#### 2.2 Running the bash script to create the resources 

```
bash cloud-shell-script-user.sh
 ```
 
### 3. Create a Dataproc Interactive Spark Session

Edit location and name as appropriate-
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


### 4. Connect to Vertex AI Workbench in the Cloud Console

The cloud-shell scripts creates a Vertex AI Workbench managed notebook instance and loads the Delta Lake notebooks.
Navigate into the managed notebook instance, open the first Delta Lake notebook (DeltaLakeLab-1.ipynb), and pick a Spark kernel - the one created by #C above.

<hr>

### 5. Lab guide
Note: The notebooks have scope and narratives defined in them, so there is no explicit lab guide for this lab. The features of Delta Lake covered is listed [above](README.md#features-covered)<br>

Run through each notebook, sequentially.<br>
Review the Delta Lake documentation at - <br>
https://docs.delta.io/latest/index.html <br>
 
**Note:** Table clones are not yet availabe outside Databricks - https://github.com/delta-io/delta/issues/1387. Therefore, notebook 8, does not work, its been left as a placeholder.

## 6. Dont forget to 
Shut down/delete resources when done to avoid unnecessary billing.