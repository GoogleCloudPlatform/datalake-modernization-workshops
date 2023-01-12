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

## 1. Overview Customer Churn
This demo is derived from [data-science-blueprints](https://github.com/NVIDIA/data-science-blueprints) repository.
The repository shows a realistic ETL workflow based on synthetic normalized data. 

## 2. Services Used
* Google Cloud Storage
* Google Cloud Dataproc

## 3. Permissions / IAM Roles required to run the lab

Following permissions / roles are required to execute the serverless batch

- Viewer
- Dataproc Editor
- Service Account User
- Storage Admin

<br>

## 4. Helpful Resources
If you have any questions or if you found any problems with this repository, please report through GitHub issues.

For instructions and best practices, please refer to NVIDIA [getting started guide](https://nvidia.github.io/spark-rapids/)


## 5. Lab Modules

The lab consists of the following modules.

[Create Dataproc cluster and set up runtime environment](02-execution-instructions/setup.md)

[Use CPU Spark to process the data and fetch Spark history Log](02-execution-instructions/cpu-spark.md)

[Use Spark RAPIDS Qualification Tool to exam the history log](02-execution-instructions/rapids-qualificationn-tool.md)

[Use Spark RAPIDS to process the data on GPU](02-execution-instructions/gpu-spark.md)

<br>


## 6. CleanUp

Delete the resources after finishing the lab. <br>
