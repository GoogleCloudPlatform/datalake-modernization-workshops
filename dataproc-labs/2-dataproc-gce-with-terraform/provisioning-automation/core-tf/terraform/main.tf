/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/******************************************
Local variables declaration
 *****************************************/

locals {
project_id                  = "${var.project_id}"
project_nbr                 = "${var.project_number}"
admin_upn_fqn               = "${var.gcp_account_name}"
location                    = "${var.gcp_region}"
umsa                        = "dpgce-lab-sa"
umsa_fqn                    = "${local.umsa}@${local.project_id}.iam.gserviceaccount.com"
dpgce_spark_bucket          = "dpgce-spark-bucket-${local.project_nbr}"
dpgce_spark_bucket_fqn      = "gs://dpgce-spark-${local.project_nbr}"
dpgce_spark_sphs_nm         = "dpgce-sphs-${local.project_nbr}"
dpgce_spark_sphs_bucket     = "dpgce-sphs-${local.project_nbr}"
dpgce_spark_sphs_bucket_fqn = "gs://dpgce-sphs-${local.project_nbr}"
vpc_nm                      = "dpgce-vpc-${local.project_nbr}"
spark_subnet_nm             = "spark-snet"
spark_subnet_cidr           = "10.0.0.0/16"
dpgce_data_and_code_bucket  = "dpgce_data_and_code_bucket-${local.project_nbr}"
bq_datamart_ds              = "cell_tower_reporting_mart"
CC_GMSA_FQN                 = "service-${local.project_nbr}@cloudcomposer-accounts.iam.gserviceaccount.com"
GCE_GMSA_FQN                = "${local.project_nbr}-compute@developer.gserviceaccount.com"
CLOUD_COMPOSER2_IMG_VERSION = "${var.cloud_composer_image_version}"
metastore_db_nm             = "dpgce_metastore_db"
metastore_nm                = "dpgce-metastore-${local.project_nbr}"
subnet_resource_uri         = "projects/${local.project_id}/regions/${local.location}/subnetworks/${local.spark_subnet_nm}"
dpgce_cluster_nm            = "dpgce-cluster-static-${local.project_nbr}"
}



/******************************************
1. User Managed Service Account Creation
 *****************************************/
module "umsa_creation" {
  source     = "terraform-google-modules/service-accounts/google"
  #version    = "4.1.1"
  project_id = local.project_id
  names      = ["${local.umsa}"]
  display_name = "User Managed Service Account"
  description  = "User Managed Service Account for Serverless Spark"

}

/******************************************
2a. IAM role grants to User Managed Service Account
 *****************************************/

module "umsa_role_grants" {
  source                  = "terraform-google-modules/iam/google//modules/member_iam"
  #version                 = "7.4.1"
  service_account_address = "${local.umsa_fqn}"
  prefix                  = "serviceAccount"
  project_id              = local.project_id
  project_roles = [
    
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountTokenCreator",
    "roles/storage.objectViewer",
    "roles/storage.admin",
    "roles/metastore.admin",
    "roles/metastore.editor",
    "roles/metastore.user",
    "roles/metastore.metadataEditor",
    "roles/dataproc.worker",
    "roles/dataproc.editor",
    "roles/bigquery.dataEditor",
    "roles/bigquery.admin",
    "roles/composer.worker",
    "roles/composer.admin"

  ]
  depends_on = [
    module.umsa_creation
  ]
}

/******************************************
2b. IAM role grants to Google Managed Service Account for Cloud Composer 2
 *****************************************/

module "gmsa_role_grants_cc" {
  source                  = "terraform-google-modules/iam/google//modules/member_iam"
  service_account_address = "${local.CC_GMSA_FQN}"
  prefix                  = "serviceAccount"
  project_id              = local.project_id
  project_roles = [
    
    "roles/composer.ServiceAgentV2Ext",
  ]
  depends_on = [
    module.umsa_role_grants
  ]
}

/******************************************
2c. IAM role grants to Google Managed Service 
Account for Compute Engine (for Cloud Composer 2 to download images)
 *****************************************/

module "gmsa_role_grants_gce" {
  source                  = "terraform-google-modules/iam/google//modules/member_iam"
  service_account_address = "${local.GCE_GMSA_FQN}"
  prefix                  = "serviceAccount"
  project_id              = local.project_id
  project_roles = [
    
    "roles/editor",
  ]
  depends_on = [
    module.umsa_role_grants
  ]
}

/******************************************************
3. Service Account Impersonation Grants to Admin User
 ******************************************************/

module "umsa_impersonate_privs_to_admin" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam/"

  service_accounts = ["${local.umsa_fqn}"]
  project          = local.project_id
  mode             = "additive"
  bindings = {
    "roles/iam.serviceAccountUser" = [
      "user:${local.admin_upn_fqn}"
    ],
    "roles/iam.serviceAccountTokenCreator" = [
      "user:${local.admin_upn_fqn}"
    ]
  }
  depends_on = [
    module.umsa_creation
  ]
}

/******************************************************
4. IAM role grants to Admin User
 ******************************************************/

module "administrator_role_grants" {
  source   = "terraform-google-modules/iam/google//modules/projects_iam"
  projects = ["${local.project_id}"]
  mode     = "additive"

  bindings = {
    "roles/storage.admin" = [
      "user:${local.admin_upn_fqn}",
    ]
    "roles/metastore.admin" = [

      "user:${local.admin_upn_fqn}",
    ]
    "roles/dataproc.admin" = [
      "user:${local.admin_upn_fqn}",
    ]
    "roles/bigquery.admin" = [
      "user:${local.admin_upn_fqn}",
    ]
    "roles/bigquery.user" = [
      "user:${local.admin_upn_fqn}",
    ]
    "roles/bigquery.dataEditor" = [
      "user:${local.admin_upn_fqn}",
    ]
    "roles/bigquery.jobUser" = [
      "user:${local.admin_upn_fqn}",
    ]
    "roles/composer.environmentAndStorageObjectViewer" = [
      "user:${local.admin_upn_fqn}",
    ]
    "roles/iam.serviceAccountUser" = [
      "user:${local.admin_upn_fqn}",
    ]
    "roles/iam.serviceAccountTokenCreator" = [
      "user:${local.admin_upn_fqn}",
    ]
    "roles/composer.admin" = [
      "user:${local.admin_upn_fqn}",
    ]
  }
  depends_on = [
    module.umsa_role_grants,
    module.umsa_impersonate_privs_to_admin
  ]

  }

/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/
resource "time_sleep" "sleep_after_identities_permissions" {
  create_duration = "120s"
  depends_on = [
    module.umsa_creation,
    module.umsa_role_grants,
    module.umsa_impersonate_privs_to_admin,
    module.administrator_role_grants,
    module.gmsa_role_grants_cc,
    module.gmsa_role_grants_gce
  ]
}

/******************************************
5. VPC Network & Subnet Creation
 *****************************************/
module "vpc_creation" {
  source                                 = "terraform-google-modules/network/google"
  version                                = "~> 4.0"
  project_id                             = local.project_id
  network_name                           = local.vpc_nm
  routing_mode                           = "REGIONAL"

  subnets = [
    {
      subnet_name           = "${local.spark_subnet_nm}"
      subnet_ip             = "${local.spark_subnet_cidr}"
      subnet_region         = "${local.location}"
      subnet_range          = local.spark_subnet_cidr
      subnet_private_access = true
    }
  ]
  depends_on = [
    time_sleep.sleep_after_identities_permissions
  ]
}

/******************************************
6. Firewall rules creation
 *****************************************/

resource "google_compute_firewall" "allow_intra_snet_ingress_to_any" {
  project   = local.project_id 
  name      = "allow-intra-snet-ingress-to-any"
  network   = local.vpc_nm
  direction = "INGRESS"
  source_ranges = [local.spark_subnet_cidr]
  allow {
    protocol = "all"
  }
  description        = "Creates firewall rule to allow ingress from within Spark subnet on all ports, all protocols"
  depends_on = [
    module.vpc_creation, 
    module.administrator_role_grants
  ]
}

/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/
resource "time_sleep" "sleep_after_network_and_firewall_creation" {
  create_duration = "120s"
  depends_on = [
    module.vpc_creation,
    google_compute_firewall.allow_intra_snet_ingress_to_any
  ]
}

/******************************************
7. Storage bucket creation
 *****************************************/

resource "google_storage_bucket" "dpgce_spark_bucket_creation" {
  name                              = local.dpgce_spark_bucket
  location                          = local.location
  uniform_bucket_level_access       = true
  force_destroy                     = true
  depends_on = [
      time_sleep.sleep_after_network_and_firewall_creation
  ]
}

resource "google_storage_bucket" "dpgce_spark_sphs_bucket_creation" {
  name                              = local.dpgce_spark_sphs_bucket
  location                          = local.location
  uniform_bucket_level_access       = true
  force_destroy                     = true
  depends_on = [
      time_sleep.sleep_after_network_and_firewall_creation
  ]
}

resource "google_storage_bucket" "dpgce_data_and_code_bucket_creation" {
  name                              = local.dpgce_data_and_code_bucket
  location                          = local.location
  uniform_bucket_level_access       = true
  force_destroy                     = true
  depends_on = [
      time_sleep.sleep_after_network_and_firewall_creation
  ]
}


/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/
resource "time_sleep" "sleep_after_bucket_creation" {
  create_duration = "60s"
  depends_on = [
    google_storage_bucket.dpgce_data_and_code_bucket_creation,
    google_storage_bucket.dpgce_spark_sphs_bucket_creation,
    google_storage_bucket.dpgce_spark_bucket_creation

  ]
}

/******************************************
8a. Copy of Pyspark scripts to dpgce_data_and_code_bucket
 *****************************************/

resource "google_storage_bucket_object" "pyspark_scripts_upload_to_gcs" {
  for_each = fileset("../scripts/pyspark/", "*")
  source = "../scripts/pyspark/${each.value}"
  name = "scripts/pyspark/${each.value}"
  bucket = "${local.dpgce_data_and_code_bucket}"
  depends_on = [
    time_sleep.sleep_after_bucket_creation
  ]
}

/******************************************
8b. Copy of Airflow DAG script to dpgce_data_and_code_bucket
 *****************************************/

resource "google_storage_bucket_object" "airflow_dag_upload_to_gcs" {
  for_each = fileset("../scripts/composer-dag/", "*")
  source = "../scripts/composer-dag/${each.value}"
  name = "scripts/composer-dag/${each.value}"
  bucket = "${local.dpgce_data_and_code_bucket}"
  depends_on = [
    time_sleep.sleep_after_bucket_creation
  ]
}

/******************************************
8c. Copy of data to dpgce_data_and_code_bucket
 *****************************************/

resource "google_storage_bucket_object" "csv_files_upload_to_gcs" {
  for_each = fileset("../datasets/", "*")
  source = "../datasets/${each.value}"
  name = "datasets/${each.value}"
  bucket = "${local.dpgce_data_and_code_bucket}"
  depends_on = [
    time_sleep.sleep_after_bucket_creation
  ]
}

resource "google_storage_bucket_object" "other_files_upload_to_gcs" {
  for_each = fileset("../datasets/cust_raw_data/", "*")
  source = "../datasets/cust_raw_data/${each.value}"
  name = "datasets/cust_raw_data/${each.value}"
  bucket = "${local.dpgce_data_and_code_bucket}"
  depends_on = [
    time_sleep.sleep_after_bucket_creation
  ]
}

/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/

resource "time_sleep" "sleep_after_network_and_storage_steps" {
  create_duration = "120s"
  depends_on = [
      time_sleep.sleep_after_network_and_firewall_creation,
      time_sleep.sleep_after_bucket_creation
  ]
}

/******************************************
9a. PHS creation
******************************************/

# Docs: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dataproc_cluster

resource "google_dataproc_cluster" "sphs_creation" {
  provider = google-beta
  name     = local.dpgce_spark_sphs_nm
  region   = local.location

  cluster_config {
    
    endpoint_config {
        enable_http_port_access = true
    }

    staging_bucket = local.dpgce_spark_bucket
    
    # Override or set some custom properties
    software_config {
      image_version = "2.0"
      override_properties = {
        "dataproc:dataproc.allow.zero.workers"=true
        "dataproc:job.history.to-gcs.enabled"=true
        "spark:spark.history.fs.logDirectory"="${local.dpgce_spark_sphs_bucket_fqn}/*/spark-job-history"
        "spark:spark.eventLog.dir"="${local.dpgce_spark_sphs_bucket_fqn}/events/spark-job-history"
        "mapred:mapreduce.jobhistory.read-only.dir-pattern"="${local.dpgce_spark_sphs_bucket_fqn}/*/mapreduce-job-history/done"
        "mapred:mapreduce.jobhistory.done-dir"="${local.dpgce_spark_sphs_bucket_fqn}/events/mapreduce-job-history/done"
        "mapred:mapreduce.jobhistory.intermediate-done-dir"="${local.dpgce_spark_sphs_bucket_fqn}/events/mapreduce-job-history/intermediate-done"
        "yarn:yarn.nodemanager.remote-app-log-dir"="${local.dpgce_spark_sphs_bucket_fqn}/yarn-logs"

      }      
    }
    gce_cluster_config {
      subnetwork =  local.subnet_resource_uri 
      service_account = local.umsa_fqn
      service_account_scopes = [
        "cloud-platform"
      ]
    }
  }
  depends_on = [
    module.administrator_role_grants,
    module.vpc_creation,
    time_sleep.sleep_after_network_and_storage_steps
  ]  
}

/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/
resource "time_sleep" "sleep_after_phs_creation" {
  create_duration = "180s"
  depends_on = [
      google_dataproc_cluster.sphs_creation
  ]
}

/******************************************
9b. BigQuery dataset creation
******************************************/

resource "google_bigquery_dataset" "bq_dataset_creation" {
  dataset_id                  = local.bq_datamart_ds
  location                    = "US"
}

/******************************************
10. Cloud Composer 2 creation
******************************************/

resource "google_composer_environment" "cloud_composer_env_creation" {
  name   = "${local.project_id}-cc2"
  region = local.location
  provider = google-beta
  config {

    software_config {
      image_version = local.CLOUD_COMPOSER2_IMG_VERSION 
      env_variables = {
        
        AIRFLOW_VAR_PROJECT_ID = "${local.project_id}"
        AIRFLOW_VAR_PROJECT_NBR = "${local.project_nbr}"        
        AIRFLOW_VAR_REGION = "${local.location}"
        AIRFLOW_VAR_CODE_BUCKET = "${local.dpgce_data_and_code_bucket}"
        AIRFLOW_VAR_BQ_DATASET = "${local.bq_datamart_ds}"
        AIRFLOW_VAR_METASTORE_DB = "${local.bq_datamart_ds}"
        AIRFLOW_VAR_SUBNET_URI = "${local.subnet_resource_uri}"
        
        AIRFLOW_VAR_UMSA = "${local.umsa}"
       
        AIRFLOW_VAR_PHS = "${local.dpgce_spark_sphs_nm}"
      }
    }

    node_config {
      network    = local.vpc_nm
      subnetwork = local.spark_subnet_nm
      service_account = local.umsa_fqn
    }
  }

  depends_on = [
    time_sleep.sleep_after_phs_creation
  ] 

  timeouts {
    create = "75m"
  } 
}

/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/
resource "time_sleep" "sleep_after_composer_creation" {
  create_duration = "300s"
  depends_on = [
      google_composer_environment.cloud_composer_env_creation
  ]
}

/******************************************
11. Cloud Composer 2 DAG bucket capture so we can upload DAG to it
******************************************/

output "CLOUD_COMPOSER_DAG_BUCKET" {
  value = google_composer_environment.cloud_composer_env_creation.config.0.dag_gcs_prefix
}

/*******************************************
12. Upload Airflow DAG to Composer DAG bucket
******************************************/
# Remove the gs:// prefix and /dags suffix

resource "google_storage_bucket_object" "airflow_dag_upload_to_cc2_dag_bucket" {
  for_each = fileset("../scripts/composer-dag/", "*")
  source = "../scripts/composer-dag/${each.value}"
  name = "dags/${each.value}"
  bucket = substr(substr(google_composer_environment.cloud_composer_env_creation.config.0.dag_gcs_prefix, 5, length(google_composer_environment.cloud_composer_env_creation.config.0.dag_gcs_prefix)), 0, (length(google_composer_environment.cloud_composer_env_creation.config.0.dag_gcs_prefix)-10))
  depends_on = [
    time_sleep.sleep_after_composer_creation
  ]
}

/******************************************
13. Output important variables needed for the demo
******************************************/

output "PROJECT_ID" {
  value = local.project_id
}

output "PROJECT_NBR" {
  value = local.project_nbr
}

output "LOCATION" {
  value = local.location
}

output "VPC_NM" {
  value = local.vpc_nm
}

output "SPARK_SUBNET" {
  value = local.spark_subnet_nm
}

output "PERSISTENT_HISTORY_SERVER_NM" {
  value = local.dpgce_spark_sphs_nm
}

output "UMSA_FQN" {
  value = local.umsa_fqn
}

output "CODE_AND_DATA_BUCKET" {
  value = local.dpgce_data_and_code_bucket
}

/******************************************
14. Create Dataproc Metastore with gRPC endpoint
******************************************/

resource "google_dataproc_metastore_service" "datalake_metastore" {
  provider      = google-beta
  service_id    = local.metastore_nm
  location      = local.location
  tier          = "DEVELOPER"
  network       = "projects/${local.project_id}/global/networks/${local.vpc_nm}"

 maintenance_window {
    hour_of_day = 2
    day_of_week = "SUNDAY"
  }

 hive_metastore_config {
    version = "3.1.2"
    endpoint_protocol = "GRPC"
    
  }
  depends_on = [
    module.administrator_role_grants,
    time_sleep.sleep_after_network_and_storage_steps
  ]
}

/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/
resource "time_sleep" "sleep_after_metastore_creation" {
  create_duration = "300s"
  depends_on = [
      google_dataproc_metastore_service.datalake_metastore
  ]
}

/******************************************
15. Create Dataproc GCE
******************************************/

resource "google_dataproc_cluster" "gce_cluster" {
  provider = google-beta
  name     = "${local.dpgce_cluster_nm}"
  region   = local.location

  cluster_config {
    endpoint_config {
      enable_http_port_access = true
    }

    preemptible_worker_config {
      num_instances = 0
    }

    staging_bucket = "${local.dpgce_spark_bucket}"

    # Override or set some custom properties
    # 1. Version
    # 2. BYO Persistent Spark History Server - by pointing to the logs underlying the service
    # 3. Optional componet of Jupyter
    software_config {
      image_version = "2.0"
      optional_components = [ "JUPYTER" ]
      override_properties = {
        "dataproc:dataproc.allow.zero.workers" = "false"
        "spark:spark.history.fs.logDirectory"="${local.dpgce_spark_sphs_bucket_fqn}/*/spark-job-history"
        "spark:spark.eventLog.dir"="${local.dpgce_spark_sphs_bucket_fqn}/events/spark-job-history"
        "mapred:mapreduce.jobhistory.read-only.dir-pattern"="${local.dpgce_spark_sphs_bucket_fqn}/*/mapreduce-job-history/done"
        "mapred:mapreduce.jobhistory.done-dir"="${local.dpgce_spark_sphs_bucket_fqn}/events/mapreduce-job-history/done"
        "mapred:mapreduce.jobhistory.intermediate-done-dir"="${local.dpgce_spark_sphs_bucket_fqn}/events/mapreduce-job-history/intermediate-done"
        "yarn:yarn.nodemanager.remote-app-log-dir"="${local.dpgce_spark_sphs_bucket_fqn}/yarn-logs"
        "dataproc:dataproc.logging.stackdriver.enable"=true
        "dataproc:dataproc.monitoring.stackdriver.enable"=true
        "yarn:yarn.log-aggregation.enabled"=true
        "dataproc:dataproc.logging.stackdriver.job.yarn.container.enable"=true
        "dataproc:jobs.file-backed-output.enable"=true
        "dataproc:dataproc.logging.stackdriver.job.driver.enable"=true
      }
    }
    initialization_action {
      script      = "gs://goog-dataproc-initialization-actions-${local.location}/connectors/connectors.sh"
      timeout_sec = 300
    }

    # Override or set some custom properties
    master_config {
      num_instances = 1
      machine_type  = "n1-standard-4"
      disk_config {
        boot_disk_type    = "pd-standard"
        boot_disk_size_gb = 500
      }
    }

    worker_config {
      num_instances    = 2
      machine_type     = "n1-standard-4"
      disk_config {
        boot_disk_type    = "pd-standard"
        boot_disk_size_gb = 500
      }
    }

    gce_cluster_config {
      subnetwork =  "projects/${local.project_id}/regions/${local.location}/subnetworks/${local.spark_subnet_nm}"
      service_account = local.umsa_fqn
      service_account_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
      internal_ip_only = true
      shielded_instance_config {
        enable_secure_boot          = true
        enable_vtpm                 = true
        enable_integrity_monitoring = true
        }
      metadata = {
        "spark-bigquery-connector-version" : "0.26.0"
        }   
    }
    metastore_config {
    dataproc_metastore_service = google_dataproc_metastore_service.datalake_metastore.id
  }

  }
  depends_on = [
    time_sleep.sleep_after_network_and_storage_steps,
    google_dataproc_cluster.sphs_creation,
    time_sleep.sleep_after_composer_creation
    ]
}

/******************************************
DONE
******************************************/
