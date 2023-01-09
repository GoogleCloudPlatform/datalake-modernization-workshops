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
# Purpose: Launch the terraform deployment
#........................................................................

export TERRAFORM_BIN=`which terraform`
ERROR_EXIT=1

#Capture input variables
if [ "${#}" -ne 3 ]; then
    echo "Illegal number of parameters. Exiting ..."
    echo "Usage: ${0} <gcp_project_id> <gcp_region> <gcp_zone>"
    echo "Exiting ..."
     exit ${ERROR_EXIT}
fi
export GCP_PROJECT_ID=${1}
export GCP_REGION=${2}
export GCP_ZONE=${3}


LOG_DATE=`date`
echo "###########################################################################################"
echo "${LOG_DATE} Launching Terraform ..."


"${TERRAFORM_BIN}" init -reconfigure 
if [ ! "${?}" -eq 0 ]; then
        LOG_DATE=`date`
        echo "${LOG_DATE} Unable to run ${TERRAFORM_BIN} init -reconfigure Exiting ..."
        
fi


"${TERRAFORM_BIN}" validate 
if [ ! "${?}" -eq 0 ]; then
        LOG_DATE=`date`
        echo "${LOG_DATE} Unable to run ${TERRAFORM_BIN} validate. Exiting ..."
        
fi


"${TERRAFORM_BIN}" destroy \
    -var="gcp_project_id=${GCP_PROJECT_ID}" \
    -var="gcp_region=${GCP_REGION}" \
    -var="gcp_zone=${GCP_ZONE}" \
    --auto-approve
if [ ! "${?}" -eq 0 ]; then
    LOG_DATE=`date`
    echo "${LOG_DATE} Unable to run ${TERRAFORM_BIN} apply. Exiting ..."
fi 

LOG_DATE=`date`
echo "###########################################################################################"
echo "${LOG_DATE} Execution finished! ..."