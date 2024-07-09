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
umsa                        = "lab-sa"
umsa_fqn                    = "${local.umsa}@${local.project_id}.iam.gserviceaccount.com"
spark_event_log_bucket      = "spark-event-log-bucket-${local.project_nbr}"
spark_event_log_bucket_fqn  = "gs://${local.spark_event_log_bucket}"
spark_cluster_bucket        = "spark-cluster-bucket-${local.project_nbr}"
spark_cluster_bucket_fqn    = "gs://${local.spark_cluster_bucket}"
spark_event_log_bucket_s8s  = "spark-event-log-bucket-s8s-${local.project_nbr}"
spark_event_log_bucket_s8s_fqn = "gs://${local.spark_event_log_bucket_s8s}"
vpc_nm                      = "vpc-${local.project_nbr}"
spark_subnet_nm             = "spark-snet"
spark_subnet_cidr           = "10.0.0.0/16"
data_bucket                 = "data_bucket-${local.project_nbr}"
code_bucket                 = "code_bucket-${local.project_nbr}"
bq_datamart_ds              = "gpu_lab_ds"
subnet_resource_uri         = "projects/${local.project_id}/regions/${local.location}/subnetworks/${local.spark_subnet_nm}"
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
2. IAM role grants to User Managed Service Account
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
    "roles/bigquery.admin"

  ]
  depends_on = [
    module.umsa_creation
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
    "roles/iam.serviceAccountUser" = [
      "user:${local.admin_upn_fqn}",
    ]
    "roles/iam.serviceAccountTokenCreator" = [
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

resource "google_storage_bucket" "spark_event_log_bucket_creation" {
  name                              = local.spark_event_log_bucket
  location                          = local.location
  uniform_bucket_level_access       = true
  force_destroy                     = true
  depends_on = [
      time_sleep.sleep_after_network_and_firewall_creation
  ]
}


resource "google_storage_bucket" "spark_cluster_bucket_creation" {
  name                              = local.spark_cluster_bucket
  location                          = local.location
  uniform_bucket_level_access       = true
  force_destroy                     = true
  depends_on = [
      time_sleep.sleep_after_network_and_firewall_creation
  ]
}

resource "google_storage_bucket" "spark_event_log_bucket_s8s_creation" {
  name                              = local.spark_event_log_bucket_s8s
  location                          = local.location
  uniform_bucket_level_access       = true
  force_destroy                     = true
  depends_on = [
      time_sleep.sleep_after_network_and_firewall_creation
  ]
}

resource "google_storage_bucket" "data_bucket_creation" {
  name                              = local.data_bucket
  location                          = local.location
  uniform_bucket_level_access       = true
  force_destroy                     = true
  depends_on = [
      time_sleep.sleep_after_network_and_firewall_creation
  ]
}
resource "google_storage_bucket" "code_bucket_creation" {
  name                              = local.code_bucket
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
    google_storage_bucket.data_bucket_creation,
    google_storage_bucket.code_bucket_creation,
    google_storage_bucket.spark_event_log_bucket_creation,
    google_storage_bucket.spark_cluster_bucket_creation,
    google_storage_bucket.spark_event_log_bucket_s8s_creation,
  ]
}

/******************************************
8a. Copy of Pyspark scripts to code_bucket
 *****************************************/

resource "google_storage_bucket_object" "pyspark_scripts_l1_upload_to_gcs" {
  for_each = fileset("../scripts/pyspark/", "*")
  source = "../scripts/pyspark/${each.value}"
  name = "churn/${each.value}"
  bucket = "${local.code_bucket}"
  depends_on = [
    time_sleep.sleep_after_bucket_creation
  ]
}

resource "google_storage_bucket_object" "pyspark_scripts_l2a_upload_to_gcs" {
  for_each = fileset("../scripts/pyspark/churn_utils", "*")
  source = "../scripts/pyspark/churn_utils/${each.value}"
  name = "churn/churn_utils/${each.value}"
  bucket = "${local.code_bucket}"
  depends_on = [
    time_sleep.sleep_after_bucket_creation
  ]
}

resource "google_storage_bucket_object" "pyspark_scripts_l2b_upload_to_gcs" {
  for_each = fileset("../scripts/pyspark/data-generator-util", "*")
  source = "../scripts/pyspark/data-generator-util/${each.value}"
  name = "churn/data-generator-util/${each.value}"
  bucket = "${local.code_bucket}"
  depends_on = [
    time_sleep.sleep_after_bucket_creation
  ]
}


/******************************************
8b. Copy of data to data_bucket
 *****************************************/

resource "google_storage_bucket_object" "data_files_upload_to_gcs" {
  for_each = fileset("../datasets/", "*")
  source = "../datasets/${each.value}"
  name = "churn/input/${each.value}"
  bucket = "${local.data_bucket}"
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
      time_sleep.sleep_after_bucket_creation,
      google_storage_bucket_object.pyspark_scripts_l1_upload_to_gcs,
      google_storage_bucket_object.pyspark_scripts_l2a_upload_to_gcs,
      google_storage_bucket_object.pyspark_scripts_l2b_upload_to_gcs,
      google_storage_bucket_object.data_files_upload_to_gcs
  ]
}


/******************************************
DONE
******************************************/
