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

# Cell Tower Anomaly Detection with PySpark and Map Reduce Word Count on Dataproc

Following are the lab modules:

[1. Understanding Data](airflow-execution.md#1-understanding-the-data)<br>
[2. Solution Architecture](airflow-execution.md#2-solution-diagram)<br>
[3. Uploading DAG files to DAGs folder](airflow-execution.md#3-uploading-dag-files-to-dags-folder)<br>
[4. Execution of Airflow DAG](airflow-execution.md#4-execution-of-airflow-dag)<br>
[5. BQ output tables](airflow-execution.md#5-bq-output-tables)<br>
[6. Logging](airflow-execution.md#6-logging)<br>

## 1. Understanding the data

The datasets used for this project are

1.[telecom_customer_churn_data.csv](01-datasets/telecom_customer_churn_data.csv) <br>
2.[service_threshold_data.csv](01-datasets/service_threshold_data.csv) <br>
3.[customer_data](01-datasets/cust_raw_data/L1_Customer_details_raw_part-00000-fc7d6e20-dbda-4143-91b5-d9414310dfd1-c000.snappy.parquet) <br>

- Telecom Customer Churn Data   - This dataset contains information of services provided to the customers by the celltowers.
- Service Threshold Data -  This dataset contains the performance metrics thresold information of the celltowers.
- Cust Raw Data - This is a folder which contains the files which are in parquet format and holds the information of the customer data.

## 2. Solution Diagram

![this is a screenshot](/images/Flow_of_Resources.jpeg)

**Model Pipeline**

The model pipeline involves the following steps: <br>
	- Create buckets in GCS <br>
	- Create Dataproc and Persistent History Server Cluster <br>
	- Copy the raw data files, pyspark and notebook files into GCS <br>
	- Create a Cloud Composer environment and Airflow job to run the workloads against a Dataproc GCE cluster <br>
	- Create external tables in a Dataproc Metastore environment <br>
	- Reading data from the above external tables, processing it and creating external tables on GCS bucket data in Google BigQuery

## 3. Uploading DAG files to DAGs folder (Execute this step only if the environment was setup through cloud shell)

* From the code repository, download the file located at: **00-scripts-and-config**>**composer****>**tl_pipeline_cluster.py**, **00-scripts-and-config**>**composer****>**tl_pipeline.py** and **00-scripts-and-config**>**composer****>**mr_pipeline.py**
* Rename file to YOUR_NAME_tl_pipeline_cluster.py, YOUR_NAME_tl_pipeline.py and YOUR_NAME_mr_pipeline.py
* Open the YOUR_NAME_tl_pipeline_cluster.py, YOUR_NAME_tl_pipeline.py and YOUR_NAME_mr_pipeline.py files and replace your name on row 25, 28 and 15 respectively
* Navigate to **Composer**>**YOUR_COMPOSER_ENV**
* Next, navigate to **Environment Configuration**>**DAGs folder URI**
* Next, upload the DAG files to the GCS bucket corresponding to the **DAGs folder URI**

![this is a screenshot](/images/composer_2.png)

![this is a screenshot](/images/composer_3.png)

## 4. Execution of Airflow DAG

* Navigate to **Composer**>**YOUR_COMPOSER_ENV**>**Open Airflow UI**

![this is a screenshot](/images/composer_5.png)

* Once the Airflow UI opens, navigate to **DAGs** and open your respective DAG
* Next, trigger your DAG by clicking on the **Trigger DAG** button

![this is a screenshot](/images/composer_6.png)

* Once the DAG is triggered, the DAG can be monitored directly through the Airflow UI as well as the Dataproc>Serverless>Batches window

![this is a screenshot](/images/composer_7.png)

## 5. BQ output tables

Navigate to BigQuery Console, and check the **de_bq_dataset** dataset. <br>
Once the Airflow DAG execution is completed, two new tables 'YOUR_NAME_kpis_by_cell_tower' and 'YOUR_NAME_kpis_by_customer' will be created:

![this is a screenshot](/images/bq_1.png)

To view the data in these tables -

* Select the table from BigQuery Explorer by navigating 'project_id' **>** 'dataset' **>** 'table_name'
* Click on the **Preview** button to see the data in the table

![this is a screenshot](/images/bq_preview.png)

**Note:** If the **Preview** button is not visible, run the below queries to view the data. However, these queries will be charged for the full table scan.

```
  SELECT * FROM `YOUR_PROJECT_ID.de_bq_dataset.YOUR_NAME_kpis_by_cell_tower` LIMIT 1000;
  SELECT * FROM `YOUR_PROJECT_ID.de_bq_dataset.YOUR_NAME_kpis_by_customer` LIMIT 1000;
```

![this is a screenshot](/images/bq_2.png)

## 6. Logging

#### 6.1 Airflow logging

* To view the logs of any step of the DAG execution, click on the **<DAG step>**>**Log** button <br>

![this is a screenshot](/images/composer_8.png)

#### 6.2 Dataproc Jobs Logs

Once you submit the job, you can see the job run under *Dataproc* > *Jobs* as shown below:

![this is a screenshot](/images/image6.png)

#### 6.3 Persistent History Server logs

To view the Persistent History server logs, Navigate to the cluster and open web interfaces and navigate to spark history server.

![this is a screenshot](/images/image30.png)

![this is a screenshot](/images/image31.png)

#### 6.4 Examine the wordcount output

Once you trigger the DAG, you can see the job run under *Dataproc* > *Jobs* as shown below:

![this is a screenshot](/images/Image6.png)

Once the job completes successfully, you will the see the bucket you chose be populated with your wordcount results.

![this is a screenshot](/images/image4.png)

On opening each file, we can see the output of the word count job in the form of: \<word\> \<count\> as shown below:

![this is a screenshot](/images/image5.png)
