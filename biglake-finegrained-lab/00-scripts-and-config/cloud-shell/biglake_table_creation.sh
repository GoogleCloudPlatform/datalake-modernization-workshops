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
DATASET_NAME="biglake_dataset"
BQ_CONNECTION="biglake-gcs"
LOCATION="us-central1"
BUCKET_NAME=dataproc-bucket-${PROJECT_NBR}
BQ_SA=<service_account_id>

#1 Granting BQ connection Service account the role of Storage object veiwer

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=serviceAccount:$BQ_SA --role=roles/storage.objectViewer

#2 Creation of BigLake table

bq mk \
    --table \
    --external_table_definition=CSV=gs://$BUCKET_NAME/IceCreamSales.csv@projects/$PROJECT_ID/locations/$LOCATION/connections/$BQ_CONNECTION \
    $PROJECT_ID:$DATASET_NAME.IceCreamSales

#3 Updating the table as required
bq update --external_table_definition=big_lake_table.json $PROJECT_ID:$DATASET_NAME.IceCreamSales


