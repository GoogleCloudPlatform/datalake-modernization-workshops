

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
# Purpose: Run a Composer DAG
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

export GKE_LOCATION="us-west2"
export DAG_NAME="batch-process-dag"
export COMPOSER_ENV_NAME="data-analytics-demo-composer-2"

target_dataset_id="spark_lab"
ds_exists=$(bq ls -d | grep -w ${target_dataset_id})
    if [ -n "${ds_exists}" ]; then
       echo "Dataset : ${target_dataset_id} already exists"
    else
       echo "Creating $dataset"
       bq mk --dataset ${target_dataset_id}
    fi

echo "Generating DAG conf file ..."
project_id=${GOOGLE_CLOUD_PROJECT}
bq_connector_jar="gs://spark-lib/bigquery/spark-bigquery-with-dependencies_2.12-0.25.2.jar"
spark_sa="spark-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com"
subnet="spark-snet"
region=${GCP_REGION}
scratch_gcs_bucket="spark-stage-${GOOGLE_CLOUD_PROJECT}"
phs="spark-phs-${GOOGLE_CLOUD_PROJECT}"
metastore="spark-metastore-${GOOGLE_CLOUD_PROJECT}"
CONF_STRING="{\"project_id\" : \"${project_id}\",  \"target_dataset_id\" : \"${target_dataset_id}\",  \"scratch_gcs_bucket\" : \"${scratch_gcs_bucket}\",   \"bq_connector_jar\" : \"${bq_connector_jar}\", \"spark_sa\" : \"${spark_sa}\",\"subnet\": \"${subnet}\",  \"region\" : \"${region}\", \"phs\" : \"${phs}\", \"metastore\" : \"${metastore}\" }"
echo "${CONF_STRING}" > dag_conf.json
echo "Conf file generated: dag_conf.json"
