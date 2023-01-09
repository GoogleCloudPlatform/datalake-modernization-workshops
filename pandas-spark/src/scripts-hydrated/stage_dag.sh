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
# Purpose: Upload DAG files to the Composer bucket
#........................................................................

GCLOUD_BIN=`which gcloud`

LOG_DATE=`date`
echo "##############################################################"
echo "${LOG_DATE} Upload DAG  .."

if [ ! "${CLOUD_SHELL}" = true ] ; then
    echo "This script needs to run on Google Cloud Shell. Exiting ..."
    exit 1
fi

DAG_FOLDER=`${GCLOUD_BIN} storage ls gs://* | grep dags`
"${GCLOUD_BIN}" storage cp dag_pyspark.py ${DAG_FOLDER}dag_pyspark.py

LOG_DATE=`date`
echo "##############################################################"
echo "${LOG_DATE} Execution finished! ..."
