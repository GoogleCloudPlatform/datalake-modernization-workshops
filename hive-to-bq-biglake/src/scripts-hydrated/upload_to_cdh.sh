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
# Purpose: Upload data to Cloudera from host node
#........................................................................

CDH_CONTAINER_ID=`sudo docker container ps -q`

LOG_DATE=`date`
echo "###########################################################################################"
echo "${LOG_DATE} Uploading data to CDH  node: ${CDH_CONTAINER_ID} ..."
echo "Uploading local_key.json ..."
sudo docker cp local_key.json ${CDH_CONTAINER_ID}:/home/cloudera/local_key.json
echo "Uploading gcs-connector-1.7.0-hadoop2.jar ..."
sudo docker cp gcs-connector-1.7.0-hadoop2.jar ${CDH_CONTAINER_ID}:/usr/lib/hadoop/lib/gcs-connector-1.7.0-hadoop2.jar
echo "Uploading core-site-add.xml ..."
sudo docker cp core-site-add.xml ${CDH_CONTAINER_ID}:/home/cloudera/core-site-add.xml
echo "Uploading prepare_node.sh ..."
sudo docker cp prepare_node.sh ${CDH_CONTAINER_ID}:/home/cloudera/prepare_node.sh
echo "Uploading SQL/pySPark files ..."
sudo docker cp populate_hive.sql ${CDH_CONTAINER_ID}:/home/cloudera/populate_hive.sql
sudo docker cp sample_query_01.sql ${CDH_CONTAINER_ID}:/home/cloudera/sample_query_01.sql
sudo docker cp sample_query_02.sql ${CDH_CONTAINER_ID}:/home/cloudera/sample_query_02.sql
sudo docker cp delivery_data_analysis.py ${CDH_CONTAINER_ID}:/home/cloudera/delivery_data_analysis.py
sudo docker cp output_table.sql ${CDH_CONTAINER_ID}:/home/cloudera/output_table.sql
echo "[OK]"

