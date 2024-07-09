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
admin_fqupn                 = "${var.gcp_account_name}"
location                    = "${var.gcp_region}"
umsa                        = "lab-lab-sa"
umsa_fqn                    = "${local.umsa}@${local.project_id}.iam.gserviceaccount.com"
gce_gmsa_fqn                = "${local.project_nbr}-compute@developer.gserviceaccount.com"
vpc_nm                      = "lab-vpc-${local.project_nbr}"
spark_subnet_nm             = "spark-snet"
spark_subnet_cidr           = "10.0.0.0/16"
bq_datamart_ds              = "lab_mart"
metastore_db_nm             = "lab_metastore_db"
metastore_nm                = "lab-metastore-${local.project_nbr}"
subnet_resource_uri         = "projects/${local.project_id}/regions/${local.location}/subnetworks/${local.spark_subnet_nm}"
dpgce_cluster_nm            = "lab-cluster-static-${local.project_nbr}"
dataproc_spark_bucket          = "lab-spark-bucket-${local.project_nbr}"
dataproc_spark_bucket_fqn      = "gs://lab-spark-${local.project_nbr}"
dataproc_data_and_code_bucket  = "lab_data_and_code_bucket-${local.project_nbr}"
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

module "gmsa_role_grants_gce" {
  source                  = "terraform-google-modules/iam/google//modules/member_iam"
  #version                 = "7.4.1"
  service_account_address = "${local.gce_gmsa_fqn}"
  prefix                  = "serviceAccount"
  project_id              = local.project_id
  project_roles = [

    "roles/dataproc.worker",
  ]
  depends_on = [
    module.umsa_creation
  ]
}
/******************************************
2a. IAM role grants to GCE Default Account 
(required for serverless spark connection)
 *****************************************/



/******************************************************
2. Service Account Impersonation Grants to Admin User
 ******************************************************/

module "umsa_impersonate_privs_to_admin" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam/"

  service_accounts = ["${local.umsa_fqn}"]
  project          = local.project_id
  mode             = "additive"
  bindings = {
    "roles/iam.serviceAccountUser" = [
      "user:${local.admin_fqupn}"
    ],
    "roles/iam.serviceAccountTokenCreator" = [
      "user:${local.admin_fqupn}"
    ]
  }
  depends_on = [
    module.umsa_creation
  ]
}

/******************************************************
3. IAM role grants to Admin User
 ******************************************************/

module "administrator_role_grants" {
  source   = "terraform-google-modules/iam/google//modules/projects_iam"
  projects = ["${local.project_id}"]
  mode     = "additive"

  bindings = {
    "roles/storage.admin" = [
      "user:${local.admin_fqupn}",
    ]
    "roles/metastore.admin" = [

      "user:${local.admin_fqupn}",
    ]
    "roles/dataproc.admin" = [
      "user:${local.admin_fqupn}",
    ]
    "roles/bigquery.admin" = [
      "user:${local.admin_fqupn}",
    ]
    "roles/bigquery.user" = [
      "user:${local.admin_fqupn}",
    ]
    "roles/bigquery.dataEditor" = [
      "user:${local.admin_fqupn}",
    ]
    "roles/bigquery.jobUser" = [
      "user:${local.admin_fqupn}",
    ]
    "roles/composer.environmentAndStorageObjectViewer" = [
      "user:${local.admin_fqupn}",
    ]
    "roles/iam.serviceAccountUser" = [
      "user:${local.admin_fqupn}",
    ]
    "roles/iam.serviceAccountTokenCreator" = [
      "user:${local.admin_fqupn}",
    ]
    "roles/composer.admin" = [
      "user:${local.admin_fqupn}",
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
    module.administrator_role_grants
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

resource "google_storage_bucket" "dataproc_spark_bucket_creation" {
  name                              = local.dataproc_spark_bucket
  location                          = local.location
  uniform_bucket_level_access       = true
  force_destroy                     = true
  depends_on = [
      time_sleep.sleep_after_network_and_firewall_creation
  ]
}

resource "google_storage_bucket" "dataproc_data_and_code_bucket_creation" {
  name                              = local.dataproc_data_and_code_bucket
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
    google_storage_bucket.dataproc_data_and_code_bucket_creation,
    google_storage_bucket.dataproc_spark_bucket_creation

  ]
}


/******************************************
8. Copy of data to dataproc_data_and_code_bucket
 *****************************************/

variable "datasets_to_upload" {
  type = map(string)
  default = {
    "../datasets/icecream-sales-forecasting/icecream_sales.csv"               = "datasets/icecream-sales-forecasting/icecream_sales.csv",
    "../datasets/retail-transactions-anomaly-detection/anomaly_detection.csv" = "datasets/retail-transactions-anomaly-detection/anomaly_detection.csv",
  }
}

resource "google_storage_bucket_object" "dataset_upload_to_gcs" {
  for_each = var.datasets_to_upload
  name     = each.value
  source   = "${path.module}/${each.key}"
  bucket   = "${local.dataproc_data_and_code_bucket}"
  depends_on = [
    time_sleep.sleep_after_bucket_creation
  ]
}

variable "notebooks_to_upload" {
  type = map(string)
  default = {
    "../notebooks/chicago-crimes-analysis/chicago-crimes-analytics.ipynb"                              = "notebooks/bigquery-tables/chicago-crimes-analytics.ipynb",
    "../notebooks/icecream-sales-forecasting/icecream-sales-forecasting.ipynb"                         = "notebooks/external-tables/icecream-sales-forecasting.ipynb",
    "../notebooks/retail-transactions-anomaly-detection/retail-transactions-anomaly-detection.ipynb"   = "notebooks/external-tables/retail-transactions-anomaly-detection.ipynb",
    "../notebooks/climate-analysis/climate-analysis-sfo.ipynb"                                         = "notebooks/bigquery-tables/climate-analysis-sfo.ipynb"
    "../notebooks/misc/hive-metastore-explorer.ipynb"                                                  = "notebooks/hive-metastore-utils/hive-metastore-explorer.ipynb"
  }
}

resource "google_storage_bucket_object" "notebook_upload_to_gcs" {
  for_each = var.notebooks_to_upload
  name     = each.value
  source   = "${path.module}/${each.key}"
  bucket   = "${local.dataproc_data_and_code_bucket}"
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
9. BigQuery dataset creation
******************************************/

resource "google_bigquery_dataset" "bq_dataset_creation" {
  dataset_id                  = local.bq_datamart_ds
  location                    = "US"
}



/******************************************
10. Create Dataproc Metastore with gRPC endpoint
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

  metadata_integration {
        data_catalog_config {
            enabled = true
        }
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
11. Create Dataproc GCE
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

    staging_bucket = "${local.dataproc_spark_bucket}"

    # Override or set some custom properties
    software_config {
      image_version = "2.0"
      override_properties = {
        "dataproc:dataproc.allow.zero.workers" = "false"
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
    time_sleep.sleep_after_network_and_storage_steps
    ]
}

/******************************************
DONE
******************************************/
