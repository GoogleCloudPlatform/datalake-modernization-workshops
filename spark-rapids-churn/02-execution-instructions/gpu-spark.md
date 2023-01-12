<!--
 Copyright 2022-2023 NVIDIA Corporation.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
     http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
-->

# spark-rapids-dataproc-lab

## Run GPU Churn Spark Job

Modify `gpu.env.sh` to allocate the resources in the cluster, default resources is based 2 n1-standard-8 worker nodes each with 1 NVIDIA T4 GPU. Run `gpu_etl.sh` to kick off the GPU churn spark job.

Below show part of the GPU SQL plan, which validates the job runs on GPU only.

![GPU SQL Plan](../images/gpu_sql_plan.png) 