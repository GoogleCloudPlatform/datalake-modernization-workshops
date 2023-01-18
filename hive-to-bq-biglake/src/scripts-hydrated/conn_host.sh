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
# Purpose: Connect to host
#........................................................................

ERROR_EXIT=1
if [ ! "${CLOUD_SHELL}" = true ] ; then
    echo "This script needs to run on Google Cloud Shell. Exiting ..."
     exit ${ERROR_EXIT}
fi


#Capture input variables
if [ "${#}" -ne 1 ]; then
    echo "Illegal number of parameters. Exiting ..."
    echo "Usage: ${0}  <gcp_zone>"
    echo "Exiting ..."
    exit ${ERROR_EXIT}
fi

export GCP_ZONE=${1}

NODE_NAME="gce-cdh-5-single-node"

LOG_DATE=`date`
echo "###########################################################################################"
echo "${LOG_DATE} Connecting to  ${NODE_NAME} ..."
gcloud compute ssh ${NODE_NAME} --zone=${GCP_ZONE}