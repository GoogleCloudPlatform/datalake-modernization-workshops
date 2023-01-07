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
GCP_ACCOUNT_NAME=`gcloud config list account --format "value(core.account)" | cut -d'@' -f1 | xargs`
GCP_MULTI_REGION="US"
LOCATION="<YOUR_GCP_REGION_HERE>"
NAME="<YOUR_NAME_HERE>"
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
SPARK_BUCKET_NM=${LAB_PREFIX}-spark-bucket-${PROJECT_NBR}-${NAME}
DATA_BUCKET_NM=${LAB_PREFIX}-data-bucket-${PROJECT_NBR}-${NAME}
CODE_BUCKET_NM=${LAB_PREFIX}-code-bucket-${PROJECT_NBR}-${NAME}
MNB_SERVER_MACHINE_TYPE=n1-standard-4
MNB_SERVER_NM=${LAB_PREFIX}-spark-ml-interactive-nb-server-${NAME}



# Create code bucket
gsutil mb -p $PROJECT_ID -c STANDARD -l $LOCATION -b on gs://${CODE_BUCKET_NM}

# Create data bucket
gsutil mb -p $PROJECT_ID -c STANDARD -l $LOCATION -b on gs://${DATA_BUCKET_NM}

# Create spark bucket
gsutil mb -p $PROJECT_ID -c STANDARD -l $LOCATION -b on gs://${SPARK_BUCKET_NM}

# copying datasets into data bucket
gsutil cp -r ../../01-datasets/* gs://${DATA_BUCKET_NM}

# copying template into notebook folder and carrying out sed -i operations

gsutil cp ../../04-templates/mnbs-exec-post-startup-template.sh ../../03-notebooks/mnbs-exec-post-startup.sh && sed -i s/YOUR_PROJECT_NBR/${PROJECT_NBR}/g ../../03-notebooks/mnbs-exec-post-startup.sh && sed -i s/YOUR_ACCOUNT_NAME/${NAME}/g ../../03-notebooks/mnbs-exec-post-startup.sh

gsutil cp ../../04-templates/DeltaLakeLab-1.ipynb ../../03-notebooks/DeltaLakeLab-1.ipynb && sed -i s/YOUR_ACCOUNT_NAME/${NAME}/g ../../03-notebooks/DeltaLakeLab-1.ipynb

gsutil cp ../../04-templates/DeltaLakeLab-2.ipynb ../../03-notebooks/DeltaLakeLab-2.ipynb && sed -i s/YOUR_ACCOUNT_NAME/${NAME}/g ../../03-notebooks/DeltaLakeLab-2.ipynb

gsutil cp ../../04-templates/DeltaLakeLab-3.ipynb ../../03-notebooks/DeltaLakeLab-3.ipynb && sed -i s/YOUR_ACCOUNT_NAME/${NAME}/g ../../03-notebooks/DeltaLakeLab-3.ipynb

gsutil cp ../../04-templates/DeltaLakeLab-4.ipynb ../../03-notebooks/DeltaLakeLab-4.ipynb && sed -i s/YOUR_ACCOUNT_NAME/${NAME}/g ../../03-notebooks/DeltaLakeLab-4.ipynb

gsutil cp ../../04-templates/DeltaLakeLab-5.ipynb ../../03-notebooks/DeltaLakeLab-5.ipynb && sed -i s/YOUR_ACCOUNT_NAME/${NAME}/g ../../03-notebooks/DeltaLakeLab-5.ipynb

gsutil cp ../../04-templates/DeltaLakeLab-6.ipynb ../../03-notebooks/DeltaLakeLab-6.ipynb && sed -i s/YOUR_ACCOUNT_NAME/${NAME}/g ../../03-notebooks/DeltaLakeLab-6.ipynb

gsutil cp ../../04-templates/DeltaLakeLab-7.ipynb ../../03-notebooks/DeltaLakeLab-7.ipynb && sed -i s/YOUR_ACCOUNT_NAME/${NAME}/g ../../03-notebooks/DeltaLakeLab-7.ipynb

gsutil cp ../../04-templates/DeltaLakeLab-8.ipynb ../../03-notebooks/DeltaLakeLab-8.ipynb && sed -i s/YOUR_ACCOUNT_NAME/${NAME}/g ../../03-notebooks/DeltaLakeLab-8.ipynb

gsutil cp ../../04-templates/DeltaLakeLab-9.ipynb ../../03-notebooks/DeltaLakeLab-9.ipynb && sed -i s/YOUR_ACCOUNT_NAME/${NAME}/g ../../03-notebooks/DeltaLakeLab-9.ipynb

# copying notebooks into code bucket
gsutil cp -r ../../03-notebooks/* gs://${CODE_BUCKET_NM}


# Vertex AI Workbench - Managed Notebook Server Creation
gcloud notebooks runtimes create $MNB_SERVER_NM \
--location=$LOCATION \
--runtime-access-type=SERVICE_ACCOUNT \
--runtime-owner=$UMSA_FQN \
--post-startup-script=gs://${CODE_BUCKET_NM}/mnbs-exec-post-startup.sh \
--machine-type=${MNB_SERVER_MACHINE_TYPE}
