# Datalake Modernization Hands-on Labs

## About
This repository features self-contained, hands-on-labs with detailed and step-by-step instructions, associated collateral (data, code, configuration, terraform etc) that demystify products, features and integration points to architect and build modern datalakes on GCP.

## Labs

| # | Use Case | Lab summary | Author |
| -- | :--- | :--- |:--- |
| 1. |[Admin Use Case](admin-usecase/README.md)| GCP Infrastructure Provisioning via Terraform and Cloud Shell||
| 2. |[Data Engineer Use Case](data-engineer-usecase/README.md)|Running Spark workloads on Dataproc-GCE and Dataproc-Serverless; Read data from GCS,uses  Dataproc Metastore service for metadata, processes data and persists to BigQuery||
| 3. |[Data Scientist Use Case](s8s-spark-mlops/README.md)| Spark based MLOps at scale powered by Dataproc Serverless Spark for scalable ML training and inferencing, Vertex AI Pipelines for orchestration of ML tasks, with Vertex AI Workbench notebooks for experimentation/IDE||
|4.|[Big Lake Fine Grained Access Control Use Case](biglake-finegrained-lab/README.md)|Implementing fine-grained access control on data lakes, made possible by BigLake with a minimum viable example of Icecream sales forecasting on a Spark notebook hosted on a personal auth Cloud Dataproc GCE cluster.||
|5.|[Delta Lake Table Format Lab](table-format-lab-delta/README.md)|This lab aims to demystify Delta Lake with Apache Spark on Cloud Dataproc, with a minimum viable sample of the core features of the table format on a Data Lake on Cloud Storage.||
|6.|[Hive to BigQuery with BigLake migration](hive-to-bq-biglake/README.md)|This workshop contains a step by step demo that shows to migrate a HIVE workload from a on-prem Hadoop deployment based on legacy Cloudera 5.7 distribution to a Google Cloud modern DataLake.||
|7.|[From Data Analysis with pandas to Data Engineering with SPARK](pandas-spark/README.md)|This workshop contains a step by step demo that shows a typical Data Analytics user journey where data analysts explore and analyze data using python (pandas) and then the data engineer teams formalizes the code using scalable frameworks like SPARK.||



## Contributing
See the contributing [instructions](CONTRIBUTING.md) to get started contributing.

## License
All solutions within this repository are provided under the Apache 2.0 license. Please see the LICENSE file for more detailed terms and conditions.

## Disclaimer
This repository and its contents are not an official Google Product.

## Contact
Share you feedback, ideas, by logging [issues](../../issues).

## Release History

| # | Release Summary | Date |  Contributor |
| -- | :--- | :--- |:--- |
| 1. |Initial release| 12/02/2022| Various|
| 2. ||||
| 3. ||||
