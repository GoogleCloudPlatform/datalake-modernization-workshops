# Copyright (c) 2020–2021, NVIDIA Corporation.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Source the environment file for global settings
. gen.env.sh

CMD_PARAMS="--driver-memory ${DRIVER_MEMORY}G \
    --executor-cores $NUM_EXECUTOR_CORES \
    --executor-memory ${EXECUTOR_MEMORY}G \
    --conf spark.cores.max=$TOTAL_CORES \
    --conf spark.task.cpus=1 \
    --conf spark.sql.files.maxPartitionBytes=2G"

${SPARK_HOME}/bin/spark-submit \
$CMD_PARAMS \
--py-files=archive.zip \
generate.py \
--input-file=${INPUT_FILE} \
--output-prefix=${OUTPUT_PREFIX} \
--dup-times=${SCALE}  2>&1 | tee -a $LOGFILE
