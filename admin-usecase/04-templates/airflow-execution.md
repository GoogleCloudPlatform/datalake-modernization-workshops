<!---->
  Copyright 2022 Google LLC
 
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
 
       http://www.apache.org/licenses/LICENSE-2.0
 
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
 <!---->

# Autoscaling on Dataproc though GCP Cloud Composer/Airflow

Following are the lab modules:

[1. Understanding Data](airflow-execution.md#1-understanding-the-data)<br>
[2. Solution Architecture](airflow-execution.md#2-solution-diagram)<br>
[3. Uploading DAG files to DAGs folder](airflow-execution.md#3-uploading-dag-files-to-dags-folder)<br>
[4. Running the job on Dataproc Cluster on GCE](airflow-execution.md#4-running-the-job-on-dataproc-cluster-on-gce)<br>
[5. Viewing the output](airflow-execution.md#5-viewing-the-output)<br>
[6. Logging](airflow-execution.md#6-logging)<br>
[7. Running the job as a serverless batch on Dataproc](airflow-execution.md#7-running-the-job-as-a-serverless-batch-on-dataproc)<br>
[8. Viewing the output](airflow-execution.md#8-viewing-the-output)<br>
[9. Logging](airflow-execution.md#9-logging)<br>

## 1. Understanding the data

The dataset used for this project is Shakespeare dataset from Bigquery public data

#### 1. **Shakespeare data**<br>
   Contains a word index of the works of Shakespeare, giving the number of times each word appears in each corpus.<br>

## 2. Solution Architecture

<kbd>
<img src= images/Flow_of_Resources.jpeg>
</kbd>

![PICT1](../../images/Flow_of_Resources.jpeg)

<br>

**Data Pipeline**

The data pipeline involves the following steps: <br>
	- Create buckets in GCS <br>
	- Create Dataproc and Persistent History Server Cluster <br>
	- Create a Composer Environment<br>
	- Executing the code through Cloud Composer <br>
	- Viewing the output in the Dataproc UI

## 3. Uploading DAG files to DAGs folder (Execute this step only if the environment was setup through cloud shell)

* From the code repository, download the file located at: **01-scripts-and-config**>**composer**>**pipeline_cluster.py** and **01-scripts-and-config**>**composer**>**pipeline.py**
* Rename files to ADMIN_ID_pipeline_cluster.py and ADMIN_ID_pipeline.py
* Open the files ADMIN_ID_pipeline_cluster.py and ADMIN_ID_pipeline.py and replace your name on row 22 and row 24 respectively
* Navigate to **Composer**>**YOUR_COMPOSER_ENV**
* Next, navigate to **Environment Configuration**>**DAGs folder URI**
* Next, upload the DAG file to the GCS bucket corresponding to the **DAGs folder URI**

![this is a screenshot](/images/composer_2.png)

![this is a screenshot](/images/composer_3.png)

## 4. Running the job on Dataproc Cluster on GCE

* Navigate to **Composer**>**YOUR_COMPOSER_ENV**>**Open Airflow UI**

![this is a screenshot](/images/composer_5.png)

* Once the Airflow UI opens, navigate to **DAGs** and open your respective DAG
* Next, trigger your DAG by clicking on the **Trigger DAG** button

![this is a screenshot](/images/composer_6.png)

* Once the DAG is triggered, the DAG can be monitored directly through the Airflow UI as well as the Dataproc>Jobs window

![this is a screenshot](/images/composer_7.png)

## 5. Viewing the output

![this is a screenshot](/images/op_1c.png)

![this is a screenshot](/images/op_2c.png)

## 6. Logging

#### 6.1 Airflow logging

* To view the logs of any step of the DAG execution, click on the **<DAG step>**>**Log** button <br>

![this is a screenshot](/images/composer_8.png)

#### 6.2 Persistent History Server logs

To view the Persistent History server logs, click the 'View History Server' button on the Dataproc batches monitoring page and the logs will be shown as below:

![this is a screenshot](/images/image30.png)

![this is a screenshot](/images/image31.png)

## 7. Running the job as a serverless batch on Dataproc

* Navigate to **Composer**>**YOUR_COMPOSER_ENV**>**Open Airflow UI**

![this is a screenshot](/images/composer_5.png)

* Once the Airflow UI opens, navigate to **DAGs** and open your respective DAG
* Next, trigger your DAG by clicking on the **Trigger DAG** button

![this is a screenshot](/images/composer_6.png)

* Once the DAG is triggered, the DAG can be monitored directly through the Airflow UI as well as the Dataproc>Serverless>Batches window

![this is a screenshot](/images/composer_7.png)

## 8. Viewing the output

Once the batch completes executing successfully, the output can be viewed in the Dataproc batches UI as shown below:<br>

![this is a screenshot](/images/op_1.png)

![this is a screenshot](/images/op_2.png)

## 9. Logging

#### 9.1 Airflow logging

* To view the logs of any step of the DAG execution, click on the **<DAG step>**>**Log** button <br>

![this is a screenshot](/images/composer_8.png)

#### 9.2 Serverless Batch logs

Logs associated with the application can be found in the logging console under
**Dataproc > Serverless > Batches > <batch_name>**.
<br> You can also click on “View Logs” button on the Dataproc batches monitoring page to get to the logging page for the specific Spark job.

![this is a screenshot](/images/image10.png)

![this is a screenshot](/images/image11.png)

#### 9.3 Persistent History Server logs

To view the Persistent History server logs, click the 'View History Server' button on the Dataproc batches monitoring page and the logs will be shown as below:

![this is a screenshot](/images/image12.png)

![this is a screenshot](/images/image13.png)
