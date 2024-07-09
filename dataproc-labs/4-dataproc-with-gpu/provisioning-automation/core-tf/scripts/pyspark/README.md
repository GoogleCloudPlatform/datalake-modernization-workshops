# telco-churn-augmentation

This repository shows a realistic ETL workflow based on synthetic normalized data.  It consists of two pieces:

1.  _an augmentation script_, which synthesizes normalized (long-form) data from a wide-form input file, optionally augmenting it by duplicating records, and
2. _an ETL script_, which performs joins and aggregations in order to generate wide-form data from the synthetic long-form data.

From a performance evaluation perspective, the latter is the interesting workload; the former is just a data generator for the latter.

## Running as notebooks

The notebooks ([`augment.ipynb`](augment.ipynb) and [`etl.ipynb`](etl.ipynb)) are the best resource to understand the code and can be run interactively or with Papermill.  The published Papermill parameters are near the top of each notebook.

## Running as scripts

To run these in cluster mode on Spark, you'll need to package up the [modules](churn) that each script depends on, by creating a zip file:

`zip archive.zip -r churn generate.py`

Download the [RAPIDS Accelerator for Spark](https://repo1.maven.org/maven2/com/nvidia/rapids-4-spark_2.12/21.06.0/rapids-4-spark_2.12-21.06.0.jar) and [RAPIDS cuDF](https://repo1.maven.org/maven2/ai/rapids/cudf/21.06.1/cudf-21.06.1-cuda11.jar) jars.

Once you have the files on your local machine you will find the following files in the telco-churn-augmentation directory:

### gen.env.sh
This file contains a number of variables that need to be updated.
* **SPARK_HOME** - This is the directory where spark is installed.
* **MASTER** - This is the ip/name of your spark master server
* **HDFS_MASTER** - This is the ip/name of the HDFS master server if you are using HDFS
* **SCALE** - This determines the total number of records that will be generated. A value of 10000 (10K) will generate a dataset of rougly 25GB
* **TOTAL_CORES** - This is the total number of cores across all the nodes within the cluster. Do not include the master node unless it is also a worker
* **NUM_EXECUTORS** - This should be set to 1/4 the amount of cores specified in TOTAL_CORES
* **TOTAL_MEMORY** - This is the total amount of memory across all nodes within the cluster. Do not include the master node unless it is als a worker
* **INPUT_PREFIX** - This is the path to the data that will be processed. This path is the path used for OUTPUT_PATH in the gen.env.sh
* **OUTPUT_PATH** - This is the path where the results of the ETL/Analytics will be located _**This path is what should be used for the INPUT_PATH variable for the gpu.env.sh and cpu.env.sh files.**_

### generate.sh
This script generates the dataset that will be processed by the CPU and GPU ETL/Analytics jobs below.

### gpu.env.sh
This file contains a number of variables that need to be updated.
* **SPARK_HOME** - This is the directory where spark is installed.
* **SPARK_RAPIDS_DIR** - This is the directory where you have your rapids and cudf jars, assuming you have not copied them to $SPARK_HOME/jars
* **SPARK_CUDF_JAR** - This is the full name of the RAPIDS cuDF jar that you want to use during the ETL/Analytics run
* **SPARK_RAPIDS_JAR** - This is the full name of the RAPIDS Accelarator for Spark jar that you want to use during the ETL/Analytics run
* **MASTER** - This is the ip/name of your spark master server
* **HDFS_MASTER** - This is the ip/name of the HDFS master server if you are using HDFS
* **TOTAL_CORES** - This should be set to 5 time the number of GPUs you have in the cluster. We have found that 5 CPU cores per GPU executor performs best
* **NUM_EXECUTORS** - This should be set to number of GPUs you have in your cluster
* **RESOURCE_GPU_AMT** - This should be set to 0.2 as it is the decimal representation of the number of ratio of cores to GPUs. If the number of cores per executor is changed from 5, this value needs to be modifed accordingly
* **TOTAL_MEMORY** - This is the total amount of memory across all nodes within the cluster. Do not include the master node unless it is als a worker
* **INPUT_PREFIX** - This is the path to the data that will be processed. This path is the path used for OUTPUT_PATH in the gen.env.sh
* **OUTPUT_PATH** - This is the path where the results of the ETL/Analytics will be located

There are additional things such as S3 credentials, but those are only needed if you are using S3 storage for your input/output/prefixes

### gpu_etl.sh
This script runs the GPU accelerated ETL/Analytics part of this benchmark and will generate output in the OUTPUT_PATH location. It is important to clean out the OUTPUT_PATH prior to running this step.


### cpu.env.sh
This file contains a number of variables that need to be updated.
* **SPARK_HOME** - This is the directory where spark is installed.
* **MASTER** - This is the ip/name of your spark master server
* **HDFS_MASTER** - This is the ip/name of the HDFS master server if you are using HDFS
* **TOTAL_CORES** - This is the total number of cores across all the nodes within the cluster. Do not include the master node unless it is also a worker
* **NUM_EXECUTORS** - This should be set to 1/4 the amount of cores specified in TOTAL_CORES
* **TOTAL_MEMORY** - This is the total amount of memory across all nodes within the cluster. Do not include the master node unless it is als a worker
* **INPUT_PREFIX** - This is the path to the data that will be processed. This path is the path used for OUTPUT_PATH in the gen.env.sh
* **OUTPUT_PATH** - This is the path where the results of the ETL/Analytics will be located

There are additional things such as S3 credentials, but those are only needed if you are using S3 storage for your input/output/prefixes

### cpu_etl.sh
This script runs the ETL part of this benchmark and will generate output in the OUTPUT_PATH location. It is important to clean out the OUTPUT_PATH prior to running this step.

### logs
* This is where all logs are written to by default.

# Capturing Output and Spark Job History
Results for each benchmark will be captured in the ./logs directory. The timings captured will be similar to this output:

Use the following command to parse the logs
```
grep "Total time" logs/*
```
```
gpu_etl.sh.txt.1623100561:Total time was 312.34 to generate and process 70320000 records
gpu_etl.sh.txt.1623102500:Total time was 387.85 to generate and process 70320000 records
```

### Capture history server logs

As defined in $SPARK_HOME/conf/spark-defaults.conf, spark.eventLog.dir is the directory in which Spark events are logged. Each application will create a subdirectory in this location. Capturing this data can be helpful in comparing jobs with one another or with other configurations.

<!--
There are also script versions of each job: `generate.py` and `do-etl.py`.  Each of these supports some command-line arguments and has online help.

To run these in cluster mode on Spark, you'll need to package up the [modules](churn) that each script depends on, by creating a zip file:

`zip archive.zip -r churn generate.py`

Then you can pass `archive.zip` to your `--py-files` argument.

Here's an example command-line to run the data generator on Google Cloud Dataproc:

```
gcloud dataproc jobs submit pyspark generate.py \
  --py-files=archive.zip --cluster=$MYCLUSTER \
  --project=$MYPROJECT --region=$MYREGION \
  --properties spark.rapids.sql.enabled=False -- \
  --input-file=gs://$MYBUCKET/raw.csv \
  --output-prefix=gs://$MYBUCKET/generated-700m/ \
  --dup-times=100000
```

This will generate 100000 output records for every input record, or roughly 700 million records.  Note that we have disabled the RAPIDS Spark Accelerator plugin; this may be necessary for the data generator.
-->

## Tuning and configuration

The most critical configuration parameter for good GPU performance on the ETL job is `spark.rapids.sql.variableFloatAgg.enabled` -- if it isn't set to true, all of the floating-point aggregations will run on CPU, requiring costly transfers from device to host memory.

Here are the parameters I used when I tested on Dataproc:

- `spark.rapids.memory.pinnedPool.size=2G`
- `spark.sql.shuffle.partitions=16`
- `spark.sql.files.maxPartitionBytes=4096MB`
- `spark.rapids.sql.enabled=True`
- `spark.executor.cores=2`
- `spark.task.cpus=1`
- `spark.rapids.sql.concurrentGpuTasks=2`
- `spark.task.resource.gpu.amount=.5`
- `spark.executor.instances=8`
- `spark.rapids.sql.variableFloatAgg.enabled=True`
- `spark.rapids.sql.explain=NOT_ON_GPU`
