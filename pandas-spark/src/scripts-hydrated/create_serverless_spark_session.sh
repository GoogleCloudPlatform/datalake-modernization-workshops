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
# Purpose: Create serverless spark session
#........................................................................


GCLOUD_BIN=`which gcloud`

ERROR_EXIT=1
if [ ! "${CLOUD_SHELL}" = true ] ; then
    echo "This script needs to run on Google Cloud Shell. Exiting ..."
     exit ${ERROR_EXIT}
fi

#Capture input variables
if [ "${#}" -ne 1 ]; then
    echo "Illegal number of parameters. Exiting ..."
    echo "Usage: ${0}  <gcp_region>"
    echo "Exiting ..."
    exit ${ERROR_EXIT}
fi

export GCP_REGION=${1}

"${GCLOUD_BIN}"  beta dataproc sessions create spark spark-interactive-${RANDOM} --location ${GCP_REGION} --service-account=spark-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com --subnet=spark-snet --property=spark.jars.packages=com.google.cloud.spark:spark-bigquery-with-dependencies_2.12:0.25.2 --history-server-cluster=projects/${GOOGLE_CLOUD_PROJECT}/regions/${GCP_REGION}/clusters/spark-phs-${GOOGLE_CLOUD_PROJECT} --metastore-service=projects/${GOOGLE_CLOUD_PROJECT}/locations/${GCP_REGION}/services/spark-metastore-${GOOGLE_CLOUD_PROJECT}





