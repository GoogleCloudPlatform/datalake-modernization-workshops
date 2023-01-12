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

## Create Spark RAPIDS Cluster

To use RAPIDS Accelerator For Apache Spark with Dataproc, GCP and NVIDIA maintain [init action scripts](https://github.com/GoogleCloudDataproc/initialization-actions/tree/master/spark-rapids) 

The following command will create a new Dataproc cluster named CLUSTER_NAME with installed GPU drivers, RAPIDS Accelerator For Apache Spark and Jupyter Notebook.

Replace `YOUR_GCS_BUCKET` with a GCS bucket which will be used to store the logs, it is recommended to create the bucket in the same region/zone as the cluster, the same rule applies for the cluster data resides. 

```
export CLUSTER_NAME=spark-lab
export GCS_BUCKET=[YOUR_GCS_BUCKET]
export REGION=europe-west4
export ZONE=europe-west4-b
export NUM_GPUS=1
export NUM_WORKERS=2
export CUDA_VER=11.5

gcloud dataproc clusters create $CLUSTER_NAME  \
    --region $REGION \
    --zone $ZONE \
    --image-version=2.0-ubuntu18 \
    --master-machine-type n1-standard-4 \
    --master-boot-disk-size 200 \
    --num-workers $NUM_WORKERS \
    --worker-accelerator type=nvidia-tesla-t4,count=$NUM_GPUS \
    --worker-machine-type n1-standard-8 \
    --num-worker-local-ssds 1 \
    --initialization-actions gs://goog-dataproc-initialization-actions-${REGION}/gpu/install_gpu_driver.sh,gs://goog-dataproc-initialization-actions-${REGION}/rapids/rapids.sh \
    --optional-components=JUPYTER,ZEPPELIN \
    --metadata gpu-driver-provider="NVIDIA",rapids-runtime="SPARK" \
    --bucket $GCS_BUCKET \
    --subnet=default \
    --enable-component-gateway
```

## 2, Setup Environment and Generate Dataset

Copy [churn data](../01-datasets/WA_Fn-UseC_-Telco-Customer-Churn-.csv) to the GCS bucket, copy the scripts to master node in the dataproc cluster. Create the zip file with `zip archive.zip -r churn generate.py` for Spark submission.

Modify the `INPUT_FILE` to point to the CSV file location in GCS.

Modify `gen.env.sh` to allocate the resources in the cluster, default resources is based 2 n1-standard-8 worker nodes. Run `generate.sh` to generate a larger dataset in Dataproc's HDFS. 