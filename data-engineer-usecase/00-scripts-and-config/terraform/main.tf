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
location                    = "us-central1"
umsa                        = "de-umsa-${local.project_nbr}"
umsa_fqn                    = "${local.umsa}@${local.project_id}.iam.gserviceaccount.com"
vpc_nm                      = "de-vpc-${local.project_nbr}"
subnet_nm                   = "de-subnet-${local.project_nbr}"
subnet_cidr                 = "10.2.0.0/16"
composer_nm                 = "de-composer-${local.project_nbr}"
code_and_data_bucket_nm     = "de-code-and-data-bucket-${local.project_nbr}"
output_bucket_nm            = "de-output-bucket-${local.project_nbr}"
phs_bucket_nm               = "de-phs-bucket-${local.project_nbr}"
composer_umsa               = "de-cc-umsa-${local.project_nbr}"
phs_cluster_nm              = "de-phs-cluster-${local.project_nbr}"
bq_dataset_nm               = "de_bq_dataset"
metastore_db_nm             = "de_metastore_db"
metastore_nm                = "de-metastore-${local.project_nbr}"
composer_umsa_fqn           = "${local.composer_umsa}@${local.project_id}.iam.gserviceaccount.com"
gce_gmsa_fqn                = "${local.project_nbr}-compute@developer.gserviceaccount.com"
cc_gmsa_fqn                 = "service-${local.project_nbr}@cloudcomposer-accounts.iam.gserviceaccount.com"
cloud_composer2_img_version = "composer-2.0.11-airflow-2.2.3"
firewall_nm                 = "de-firewall-nm-${local.project_nbr}"
}

/******************************************
1. Update organization policies in parallel
 *****************************************/
resource "google_project_organization_policy" "orgPolicyUpdate_disableSerialPortLogging" {
  project     = var.project_id
  constraint = "compute.disableSerialPortLogging"
  boolean_policy {
    enforced = false
  }
}

resource "google_project_organization_policy" "orgPolicyUpdate_requireOsLogin" {
  project     = var.project_id
  constraint = "compute.requireOsLogin"
  boolean_policy {
    enforced = false
  }
}

resource "google_project_organization_policy" "orgPolicyUpdate_requireShieldedVm" {
  project     = var.project_id
  constraint = "compute.requireShieldedVm"
  boolean_policy {
    enforced = false
  }
}

resource "google_project_organization_policy" "orgPolicyUpdate_vmCanIpForward" {
  project     = var.project_id
  constraint = "compute.vmCanIpForward"
  list_policy {
    allow {
      all = true
    }
  }
}

resource "google_project_organization_policy" "orgPolicyUpdate_vmExternalIpAccess" {
  project     = var.project_id
  constraint = "compute.vmExternalIpAccess"
  list_policy {
    allow {
      all = true
    }
  }
}

resource "google_project_organization_policy" "orgPolicyUpdate_restrictVpcPeering" {
  project     = var.project_id
  constraint = "compute.restrictVpcPeering"
  list_policy {
    allow {
      all = true
    }
  }
}

/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/
resource "time_sleep" "sleep_after_org_policy_updates" {
  create_duration = "120s"
  depends_on = [
    google_project_organization_policy.orgPolicyUpdate_disableSerialPortLogging,
    google_project_organization_policy.orgPolicyUpdate_requireOsLogin,
    google_project_organization_policy.orgPolicyUpdate_requireShieldedVm,
    google_project_organization_policy.orgPolicyUpdate_vmCanIpForward,
    google_project_organization_policy.orgPolicyUpdate_vmExternalIpAccess,
    google_project_organization_policy.orgPolicyUpdate_restrictVpcPeering
  ]
}

/******************************************
2. Enable Google APIs in parallel
 *****************************************/

resource "google_project_service" "enable_orgpolicy_google_apis" {
  project = var.project_id
  service = "orgpolicy.googleapis.com"
  disable_dependent_services = true
  depends_on = [
    time_sleep.sleep_after_org_policy_updates
  ]
}

resource "google_project_service" "enable_dataproc_google_apis" {
  project = var.project_id
  service = "dataproc.googleapis.com"
  disable_dependent_services = true
  depends_on = [
    time_sleep.sleep_after_org_policy_updates
  ]
}


resource "google_project_service" "enable_composer_google_apis" {
  project = var.project_id
  service = "composer.googleapis.com"
  disable_dependent_services = true
  depends_on = [
    time_sleep.sleep_after_org_policy_updates
  ]
}

resource "google_project_service" "enable_storage_google_apis" {
  project = var.project_id
  service = "storage.googleapis.com"
  disable_dependent_services = true
  depends_on = [
    time_sleep.sleep_after_org_policy_updates
  ]
}

resource "google_project_service" "enable_compute_google_apis" {
  project = var.project_id
  service = "compute.googleapis.com"
  disable_dependent_services = true
  depends_on = [
    time_sleep.sleep_after_org_policy_updates
  ]
}

resource "google_project_service" "enable_metastore_google_apis" {
  project = var.project_id
  service = "metastore.googleapis.com"
  disable_dependent_services = true
  depends_on = [
    time_sleep.sleep_after_org_policy_updates
  ]
}

resource "google_project_service" "enable_bigquery_google_apis" {
  project = var.project_id
  service = "bigquery.googleapis.com"
  disable_dependent_services = true
  depends_on = [
    time_sleep.sleep_after_org_policy_updates
  ]
}

resource "google_project_service" "enable_notebooks_google_apis" {
  project = var.project_id
  service = "notebooks.googleapis.com"
  disable_dependent_services = true
  depends_on = [
    time_sleep.sleep_after_org_policy_updates
  ]
}

resource "google_project_service" "enable_aiplatform_google_apis" {
  project = var.project_id
  service = "aiplatform.googleapis.com"
  disable_dependent_services = true
  depends_on = [
    time_sleep.sleep_after_org_policy_updates
  ]
}

resource "google_project_service" "enable_logging_google_apis" {
  project = var.project_id
  service = "logging.googleapis.com"
  disable_dependent_services = true
  depends_on = [
    time_sleep.sleep_after_org_policy_updates
  ]
}

resource "google_project_service" "enable_monitoring_google_apis" {
  project = var.project_id
  service = "monitoring.googleapis.com"
  disable_dependent_services = true
  depends_on = [
    time_sleep.sleep_after_org_policy_updates
  ]
}
resource "google_project_service" "enable_servicenetworking_google_apis" {
  project = var.project_id
  service = "servicenetworking.googleapis.com"
  disable_dependent_services = true
  depends_on = [
    time_sleep.sleep_after_org_policy_updates
  ]
}

resource "google_project_service" "enable_cloudbuild_google_apis" {
  project = var.project_id
  service = "cloudbuild.googleapis.com"
  disable_dependent_services = true
  depends_on = [
    time_sleep.sleep_after_org_policy_updates
  ]
}

resource "google_project_service" "enable_cloudresourcemanager_google_apis" {
  project = var.project_id
  service = "cloudresourcemanager.googleapis.com"
  disable_dependent_services = true
  depends_on = [
    time_sleep.sleep_after_org_policy_updates
  ]
}

/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/
resource "time_sleep" "sleep_after_api_enabling" {
  create_duration = "180s"
  depends_on = [
    google_project_service.enable_cloudresourcemanager_google_apis,
    google_project_service.enable_cloudbuild_google_apis,
    google_project_service.enable_servicenetworking_google_apis,
    google_project_service.enable_monitoring_google_apis,
    google_project_service.enable_logging_google_apis,
    google_project_service.enable_aiplatform_google_apis,
    google_project_service.enable_notebooks_google_apis,
    google_project_service.enable_bigquery_google_apis,
    google_project_service.enable_metastore_google_apis,
    google_project_service.enable_compute_google_apis,
    google_project_service.enable_storage_google_apis,
    google_project_service.enable_composer_google_apis,
    google_project_service.enable_dataproc_google_apis,
    google_project_service.enable_orgpolicy_google_apis
  ]
}

/******************************************
3a. User Managed Service Account Creation
 *****************************************/
module "umsa_creation" {
  source     = "terraform-google-modules/service-accounts/google"
  #version    = "4.1.1"
  project_id = local.project_id
  names      = ["${local.umsa}"]
  display_name = "User Managed Service Account"
  description  = "User Managed Service Account"
  depends_on = [
    time_sleep.sleep_after_org_policy_updates,
    time_sleep.sleep_after_api_enabling
  ]

}

/******************************************
3b. Composer User Managed Service Account Creation
 *****************************************/
module "cc_umsa_creation" {
  source     = "terraform-google-modules/service-accounts/google"
  #version    = "4.1.1"
  project_id = local.project_id
  names      = ["${local.composer_umsa}"]
  display_name = "Composer User Managed Service Account"
  description  = "User Managed Service Account for Composer Environment"
  depends_on = [
    time_sleep.sleep_after_org_policy_updates,
    time_sleep.sleep_after_api_enabling
  ]

}

/******************************************
4a. IAM role grants to User Managed Service Account
 *****************************************/

module "umsa_role_grants" {
  source                  = "terraform-google-modules/iam/google//modules/member_iam"
  #version                 = "7.4.1"
  service_account_address = "${local.umsa_fqn}"
  prefix                  = "serviceAccount"
  project_id              = local.project_id
  project_roles = [

    "roles/storage.admin",
    "roles/dataproc.worker",
    "roles/bigquery.dataEditor",
    "roles/bigquery.user",
    "roles/dataproc.editor",
    "roles/viewer",
    "roles/notebooks.admin"

  ]
  depends_on = [
    module.umsa_creation,
      time_sleep.sleep_after_org_policy_updates,
    time_sleep.sleep_after_api_enabling
  ]
}

/******************************************
4b. IAM role grants to User Managed Service Account for Cloud Composer 2
 *****************************************/

module "composer_umsa_role_grants" {
  source                   = "terraform-google-modules/iam/google//modules/member_iam"
  #version                 = "7.4.1"
  service_account_address  = "${local.composer_umsa_fqn}"
  prefix                   = "serviceAccount"
  project_id               = local.project_id
  project_roles = [

    "roles/composer.worker",
    "roles/dataproc.editor",
    "roles/iam.serviceAccountUser",
    "roles/composer.ServiceAgentV2Ext"

  ]
  depends_on = [
    module.cc_umsa_creation,
      time_sleep.sleep_after_org_policy_updates,
    time_sleep.sleep_after_api_enabling
  ]
}

/******************************************
4c. IAM role grants to Google Managed Service
Account for Compute Engine (for Cloud Composer 2 to download images)
 *****************************************/

module "gmsa_role_grants_gce" {
  source                   = "terraform-google-modules/iam/google//modules/member_iam"
  #version                 = "7.4.1"
  service_account_address  = "${local.gce_gmsa_fqn}"
  prefix                   = "serviceAccount"
  project_id               = local.project_id
  project_roles = [

    "roles/editor",
  ]
  depends_on = [
    module.umsa_role_grants,
      time_sleep.sleep_after_org_policy_updates,
    time_sleep.sleep_after_api_enabling
  ]
}

/******************************************
4d. IAM role grants to Google Managed Service Account for Cloud Composer 2
 *****************************************/

module "gmsa_role_grants_cc" {
  source                  = "terraform-google-modules/iam/google//modules/member_iam"
  service_account_address = "${local.cc_gmsa_fqn}"
  prefix                  = "serviceAccount"
  project_id              = local.project_id
  project_roles = [

    "roles/composer.ServiceAgentV2Ext",
  ]
  depends_on = [
    module.umsa_role_grants,
      time_sleep.sleep_after_org_policy_updates,
    time_sleep.sleep_after_api_enabling
  ]
}


/******************************************************
4e. IAM role grants to Admin User
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
    "roles/iam.serviceAccountAdmin" = [
      "user:${local.admin_upn_fqn}",
    ]
    "roles/compute.networkAdmin" = [
      "user:${local.admin_upn_fqn}",
    ]
    "roles/compute.admin" = [
      "user:${local.admin_upn_fqn}",
    ]

  }
  depends_on = [
    module.umsa_creation,
    module.umsa_role_grants,
      time_sleep.sleep_after_org_policy_updates,
    time_sleep.sleep_after_api_enabling
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
    module.cc_umsa_creation,
    module.umsa_role_grants,
    module.composer_umsa_role_grants,
    module.gmsa_role_grants_gce,
    module.gmsa_role_grants_cc,
    module.administrator_role_grants
  ]
}

/******************************************
5. VPC Network & Subnet Creation
 *****************************************/
module "vpc_creation" {
  source                                 = "terraform-google-modules/network/google"
  version                                = "~> 4.0"
  project_id                             = "${local.project_id}"
  network_name                           = "${local.vpc_nm}"
  routing_mode                           = "REGIONAL"

  subnets = [
    {
      subnet_name           = "${local.subnet_nm}"
      subnet_ip             = "${local.subnet_cidr}"
      subnet_region         = "${local.location}"
      subnet_range          = "${local.subnet_cidr}"
      subnet_private_access = true
    }
  ]
  depends_on = [
    time_sleep.sleep_after_identities_permissions,
      time_sleep.sleep_after_org_policy_updates,
    time_sleep.sleep_after_api_enabling
  ]
}

/******************************************
6. Firewall rules creation
 *****************************************/

resource "google_compute_firewall" "allow_intra_snet_ingress_to_any" {
  project   = "${local.project_id}"
  name      = "${local.firewall_nm}"
  network   = "${local.vpc_nm}"
  direction = "INGRESS"
  source_ranges = [local.subnet_cidr]
  allow {
    protocol = "all"
  }
  description        = "Creates firewall rule to allow ingress from within subnet on all ports, all protocols"
  depends_on = [
    module.vpc_creation,
    module.administrator_role_grants,
      time_sleep.sleep_after_org_policy_updates,
    time_sleep.sleep_after_api_enabling
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

resource "google_storage_bucket" "output_bucket_creation" {
  name                              = "${local.output_bucket_nm}"
  location                          = "${local.location}"
  uniform_bucket_level_access       = true
  force_destroy                     = true
  depends_on = [
      time_sleep.sleep_after_network_and_firewall_creation,
        time_sleep.sleep_after_org_policy_updates,
    time_sleep.sleep_after_api_enabling
  ]
}

resource "google_storage_bucket" "code_and_data_bucket_creation" {
  name                              = "${local.code_and_data_bucket_nm}"
  location                          = "${local.location}"
  uniform_bucket_level_access       = true
  force_destroy                     = true
  depends_on = [
      time_sleep.sleep_after_network_and_firewall_creation,
        time_sleep.sleep_after_org_policy_updates,
    time_sleep.sleep_after_api_enabling
  ]
}

resource "google_storage_bucket" "phs_bucket_creation" {
  name                              = "${local.phs_bucket_nm}"
  location                          = "${local.location}"
  uniform_bucket_level_access       = true
  force_destroy                     = true
  depends_on = [
      time_sleep.sleep_after_network_and_firewall_creation,
        time_sleep.sleep_after_org_policy_updates,
    time_sleep.sleep_after_api_enabling
  ]
}

/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/
resource "time_sleep" "sleep_after_bucket_creation" {
  create_duration = "60s"
  depends_on = [
    google_storage_bucket.output_bucket_creation,
    google_storage_bucket.phs_bucket_creation,
    google_storage_bucket.code_and_data_bucket_creation
  ]
}

/******************************************
8. Copy of Pyspark scripts and datasets to code_and_data_bucket
 *****************************************/

resource "google_storage_bucket_object" "pyspark_scripts_upload_to_gcs" {
  for_each = fileset("../pyspark/", "*")
  source = "../pyspark/${each.value}"
  name = "cell-tower-anomaly-detection/00-scripts-and-config/pyspark/${each.value}"
  bucket = "${local.code_and_data_bucket_nm}"
  depends_on = [
    time_sleep.sleep_after_bucket_creation,
      time_sleep.sleep_after_org_policy_updates,
    time_sleep.sleep_after_api_enabling
  ]
}

resource "google_storage_bucket_object" "data_files_upload_to_gcs" {
  for_each = fileset("../../01-datasets/", "*")
  source = "../../01-datasets/${each.value}"
  name = "cell-tower-anomaly-detection/01-datasets/${each.value}"
  bucket = "${local.code_and_data_bucket_nm}"
  depends_on = [
    time_sleep.sleep_after_bucket_creation,
      time_sleep.sleep_after_org_policy_updates,
    time_sleep.sleep_after_api_enabling
  ]
}

resource "google_storage_bucket_object" "other_files_upload_to_gcs" {
  for_each = fileset("../../01-datasets/cust_raw_data/", "*")
  source = "../../01-datasets/cust_raw_data/${each.value}"
  name = "cell-tower-anomaly-detection/01-datasets/cust_raw_data/${each.value}"
  bucket = "${local.code_and_data_bucket_nm}"
  depends_on = [
    time_sleep.sleep_after_bucket_creation,
      time_sleep.sleep_after_org_policy_updates,
    time_sleep.sleep_after_api_enabling
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
      google_storage_bucket_object.other_files_upload_to_gcs,
      google_storage_bucket_object.data_files_upload_to_gcs,
      google_storage_bucket_object.pyspark_scripts_upload_to_gcs
  ]
}

/******************************************
9. PHS creation
******************************************/

resource "google_dataproc_cluster" "sphs_creation" {
  provider = google-beta
  name     = local.phs_cluster_nm
  region   = local.location

  cluster_config {

    endpoint_config {
        enable_http_port_access = true
    }

    staging_bucket = local.phs_bucket_nm

    # Override or set some custom properties
    software_config {
      image_version = "2.0"
      override_properties = {
        "dataproc:dataproc.allow.zero.workers"=true
        "dataproc:job.history.to-gcs.enabled"=true
        "spark:spark.history.fs.logDirectory"="gs://${local.phs_bucket_nm}/*/spark-job-history"
        "mapred:mapreduce.jobhistory.read-only.dir-pattern"="gs://${local.phs_bucket_nm}/*/mapreduce-job-history/done"
      }
    }
    gce_cluster_config {
      subnetwork =  "projects/${local.project_id}/regions/${local.location}/subnetworks/${local.subnet_nm}"
      service_account = local.umsa_fqn
      service_account_scopes = [
        "cloud-platform"
      ]
    }
  }
  depends_on = [
    module.administrator_role_grants,
    module.vpc_creation,
    time_sleep.sleep_after_network_and_storage_steps,
      time_sleep.sleep_after_org_policy_updates,
    time_sleep.sleep_after_api_enabling
  ]
}

/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/
resource "time_sleep" "sleep_after_phs_creation" {
  create_duration = "60s"
  depends_on = [
      google_dataproc_cluster.sphs_creation
  ]
}

/******************************************
10. Dataproc Metastore Creation
******************************************/
resource "google_dataproc_metastore_service" "datalake_metastore" {
  service_id = local.metastore_nm
  location   = local.location
  port       = 9080
  tier       = "DEVELOPER"
  network    = "projects/${local.project_id}/global/networks/${local.vpc_nm}"

 maintenance_window {
    hour_of_day = 2
    day_of_week = "SUNDAY"
  }

 hive_metastore_config {
    version = "3.1.2"
  }
  depends_on = [
    module.administrator_role_grants,
    module.vpc_creation,
    time_sleep.sleep_after_network_and_storage_steps,
      time_sleep.sleep_after_org_policy_updates,
    time_sleep.sleep_after_api_enabling
  ]
}

/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/
resource "time_sleep" "sleep_after_metastore_creation" {
  create_duration = "180s"
  depends_on = [
      google_dataproc_metastore_service.datalake_metastore
  ]
}

/******************************************
11. Cloud Composer 2 creation
******************************************/

resource "google_composer_environment" "cloud_composer_env_creation" {
  name   = local.composer_nm
  region = local.location
  provider = google-beta
  config {

    software_config {
      image_version = local.cloud_composer2_img_version
      env_variables = {
        AIRFLOW_VAR_PROJECT_ID = "${local.project_id}"
        AIRFLOW_VAR_REGION = "${local.location}"
        AIRFLOW_VAR_OUTPUT_FILE_BUCKET = "${local.output_bucket_nm}"
        AIRFLOW_VAR_PHS: "${local.phs_cluster_nm}"
        AIRFLOW_VAR_SUBNET: "${local.subnet_nm}"
        AIRFLOW_VAR_BQ_DATASET: "${local.bq_dataset_nm}"
        AIRFLOW_VAR_UMSA = "${local.umsa}"
        AIRFLOW_VAR_METASTORE_DB:"${local.metastore_db_nm}"
        AIRFLOW_VAR_METASTORE:"${local.metastore_nm}"
        AIRFLOW_VAR_CODE_AND_DATA_BUCKET: "${local.code_and_data_bucket_nm}"


      }
    }

    node_config {
      network    = local.vpc_nm
      subnetwork = local.subnet_nm
      service_account = local.composer_umsa_fqn
    }
  }
  depends_on = [
    time_sleep.sleep_after_network_and_firewall_creation,
      time_sleep.sleep_after_org_policy_updates,
    time_sleep.sleep_after_api_enabling
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
  create_duration = "180s"
  depends_on = [
      google_composer_environment.cloud_composer_env_creation
  ]
}
/******************************************
12. BigQuery dataset creation
******************************************/

resource "google_bigquery_dataset" "bq_dataset_creation" {
  dataset_id                  = local.bq_dataset_nm
  location                    = "US"
  delete_contents_on_destroy  = true
  depends_on = [
    time_sleep.sleep_after_identities_permissions,
      time_sleep.sleep_after_org_policy_updates,
    time_sleep.sleep_after_api_enabling
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

output "VPC_NAME" {
  value = local.vpc_nm
}

output "SUBNET_NAME" {
  value = local.subnet_nm
}

output "UMSA_FQN" {
  value = local.umsa_fqn
}

output "OUTPUT_BUCKET_NAME" {
  value = local.output_bucket_nm
}

output "COMPOSER_ENVIRONMENT_NAME" {
  value = local.composer_nm
}

output "METASTORE_NAME" {
  value = local.metastore_nm
}

output "PERSISTENT_HISTORY_SERVER_NAME" {
  value = local.phs_cluster_nm
}

output "BIGQUERY_DATASET_NAME" {
  value = local.bq_dataset_nm
}

output "CLOUD_COMPOSER_DAG_BUCKET" {
  value = google_composer_environment.cloud_composer_env_creation.config.0.dag_gcs_prefix
}


/******************************************
DONE
******************************************/
