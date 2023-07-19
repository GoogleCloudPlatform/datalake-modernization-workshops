#!/bin/sh
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#........................................................................
# Purpose: Prepares CDH node
#........................................................................


ERROR_EXIT=1
if [ ! "${CLOUD_SHELL}" = true ] ; then
    echo "This script needs to run on Google Cloud Shell. Exiting ..."
     exit ${ERROR_EXIT}
fi

# Capture input variables
if [ "${#}" -ne 1 ]; then
    echo "Illegal number of parameters. Exiting ..."
    echo "Usage: ${0}  <gcp_zone>"
    echo "Exiting ..."
    exit ${ERROR_EXIT}
fi

export GCP_ZONE=${1}

NODE_NAME="gce-cdh-5-single-node"

# Create compute engine ssh keys beforehand to allow first 'gcloud compute ssh' command to capture desired output
if [ ! -f ~/.ssh/google_compute_engine ]; then
    ssh-keygen -t rsa -f ~/.ssh/google_compute_engine -C google_compute_engine -b 2048 -q -N ""
fi

LOG_DATE=`date`
echo "###########################################################################################"
echo "${LOG_DATE} Restart container ${NODE_NAME} to fix hostname ..."

CDH_CONTAINER_ID=`gcloud compute ssh ${NODE_NAME} --zone=${GCP_ZONE} --command 'sudo docker ps -q | head -1'`
echo "Stopping container ${CDH_CONTAINER_ID}"
gcloud compute ssh ${NODE_NAME} --zone=${GCP_ZONE} --command="sudo docker stop ${CDH_CONTAINER_ID}"
CDH_IMAGE_ID=`gcloud compute ssh ${NODE_NAME} --zone=${GCP_ZONE} --command 'sudo docker images | grep cloudera | awk '\'' { print $3 } '\'' '`
echo "Starting image ${CDH_IMAGE_ID} ..."
gcloud compute ssh ${NODE_NAME} --zone=${GCP_ZONE} --command="sudo docker run --hostname=quickstart.cloudera --privileged=true \
  --env GOOGLE_CLOUD_PROJECT=${GOOGLE_CLOUD_PROJECT} -t -i -d ${CDH_IMAGE_ID} /usr/bin/docker-quickstart"
CDH_CONTAINER_ID=`gcloud compute ssh ${NODE_NAME} --zone=${GCP_ZONE} --command 'sudo docker ps -q | head -1'`
echo "Image ${CDH_IMAGE_ID} started as ${CDH_CONTAINER_ID}"

LOG_DATE=`date`
echo "###########################################################################################"
echo "${LOG_DATE} Downloading Hadoop GCS connector ..."
CONN_URI="gs://hadoop-lib/gcs/gcs-connector-1.7.0-hadoop2.jar"
gcloud storage cp ${CONN_URI} .

LOG_DATE=`date`
echo "###########################################################################################"
echo "${LOG_DATE} Uploading data to host node ${NODE_NAME} ..."
REMOTE_HOME=`gcloud compute ssh ${NODE_NAME} --zone=${GCP_ZONE} --command="pwd"`
gcloud compute scp gcs-connector-1.7.0-hadoop2.jar ${NODE_NAME}:${REMOTE_HOME} --zone ${GCP_ZONE}

gcloud compute scp * ${NODE_NAME}:${REMOTE_HOME}  --zone ${GCP_ZONE}

LOG_DATE=`date`
echo "###########################################################################################"
echo "${LOG_DATE} Uploading data to CDH  ..."

gcloud compute ssh ${NODE_NAME} --zone=${GCP_ZONE} --command="source upload_to_cdh.sh"

LOG_DATE=`date`
echo "###########################################################################################"
echo "${LOG_DATE} Connecting to CDH  ..."

gcloud compute ssh ${NODE_NAME} --zone=${GCP_ZONE} --container ${CDH_CONTAINER_ID}



