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
  project_id                      = "${var.gcp_project_id}"
  region                          = "${var.gcp_region}"
  zone                            = "${var.gcp_zone}"
  vpc_nm                          = "vpc-main"
  spark_subnet                    = "spark-snet"
  spark_subnet_cidr               = "10.0.0.0/16"
  psa_ip_length                   = 16
  tf_sa_id                        =  "${local.project_id}@${local.project_id}.iam.gserviceaccount.com"
  spark_stage_bucket             = "spark-stage-${local.project_id}"
  spark_nb = "spark-interactive-nb"
  spark_nb_machine_type  = "n1-standard-4"
  spark_sa                        = "spark-sa"
  spark_sa_fqn                    = "${local.spark_sa}@${local.project_id}.iam.gserviceaccount.com"
  spark_phs = "spark-phs-${local.project_id}"
  spark_metastore = "spark-metastore-${local.project_id}"
  
}


resource "google_project_organization_policy" "orgPolicyUpdate_disableSerialPortLogging" {
  project                 = "${local.project_id}"
  constraint = "compute.disableSerialPortLogging"
  boolean_policy {
    enforced = false
  }
}

resource "google_project_organization_policy" "orgPolicyUpdate_requireOsLogin" {
  project                 = "${local.project_id}"
  constraint = "compute.requireOsLogin"
  boolean_policy {
    enforced = false
  }
}

resource "google_project_organization_policy" "orgPolicyUpdate_requireShieldedVm" {
  project                 = "${local.project_id}"
  constraint = "compute.requireShieldedVm"
  boolean_policy {
    enforced = false
  }
}

resource "google_project_organization_policy" "orgPolicyUpdate_vmCanIpForward" {
  project                 = "${local.project_id}"
  constraint = "compute.vmCanIpForward"
  list_policy {
    allow {
      all = true
    }
  }
}

resource "google_project_organization_policy" "orgPolicyUpdate_vmExternalIpAccess" {
  project                 = "${local.project_id}"
  constraint = "compute.vmExternalIpAccess"
  list_policy {
    allow {
      all = true
    }
  }
}

resource "google_project_organization_policy" "orgPolicyUpdate_restrictVpcPeering" {
  project                 = "${local.project_id}"
  constraint = "compute.restrictVpcPeering"
  list_policy {
    allow {
      all = true
    }
  }
}

resource "google_project_organization_policy" "orgPolicyUpdate_disableServiceAccountKeyCreation" {
  project                 = "${local.project_id}"
  constraint = "iam.disableServiceAccountKeyCreation"
   boolean_policy {
    enforced = false
  }
}



resource "time_sleep" "sleep_after_org_policy_updates" {
  create_duration = "3m"
  depends_on = [
    google_project_organization_policy.orgPolicyUpdate_disableSerialPortLogging,
    google_project_organization_policy.orgPolicyUpdate_requireOsLogin,
    google_project_organization_policy.orgPolicyUpdate_requireShieldedVm,
    google_project_organization_policy.orgPolicyUpdate_vmCanIpForward,
    google_project_organization_policy.orgPolicyUpdate_vmExternalIpAccess,
    google_project_organization_policy.orgPolicyUpdate_restrictVpcPeering,
    google_project_organization_policy.orgPolicyUpdate_disableServiceAccountKeyCreation,
  ]
}

/******************************************
Golden demo resources
 *****************************************/
 #vpc-main
resource "google_compute_network" "golden_demo_default_network" {
  project                 = "${local.project_id}"
  description             = "Default network"
  name                    = "${local.vpc_nm}"
  auto_create_subnetworks = false
  mtu                     = 1460
   depends_on = [
    time_sleep.sleep_after_org_policy_updates
  ]
}

/******************************************
Plug-in resources
 *****************************************/
#Enable API - Service Networking
resource "google_project_service" "enable_servicenetworking_google_apis" {
  project = local.project_id
  service = "servicenetworking.googleapis.com"
  disable_dependent_services = true
  
}


#SPARK Service Account
module "spark_sa_creation" {
  source     = "terraform-google-modules/service-accounts/google"
  project_id = local.project_id
  names      = ["${local.spark_sa}"]
  display_name = "User Managed Service Account"
  description  = "User Managed Service Account for Serverless Spark"
}


#SPARK Service Account Grants
module "spark_sa_role_grants" {
  source                  = "terraform-google-modules/iam/google//modules/member_iam"
  service_account_address = "${local.spark_sa_fqn}"
  prefix                  = "serviceAccount"
  project_id              = local.project_id
  project_roles = [
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountTokenCreator",
    "roles/storage.objectAdmin",
    "roles/storage.admin",
    "roles/metastore.admin",
    "roles/metastore.editor",
    "roles/dataproc.worker",
    "roles/bigquery.dataEditor",
    "roles/bigquery.admin",
    "roles/dataproc.editor",
    "roles/artifactregistry.writer",
    "roles/logging.logWriter",
    "roles/cloudbuild.builds.editor",
    "roles/aiplatform.admin",
    "roles/aiplatform.viewer",
    "roles/aiplatform.user",
    "roles/viewer",
    "roles/composer.worker",
    "roles/composer.admin",
    "roles/cloudfunctions.admin",
    "roles/cloudfunctions.serviceAgent",
    "roles/cloudscheduler.serviceAgent"


  ]
  depends_on = [
    module.spark_sa_creation
  ]
}

#SPARK subnet 
resource "google_compute_subnetwork" "spark-subnet" {
  project                     = "${local.project_id}"
  name                        = "${local.spark_subnet}"
  ip_cidr_range               = "${local.spark_subnet_cidr}"
  region                      = "${local.region}"
  network                     = google_compute_network.golden_demo_default_network.id
  private_ip_google_access = true

}
#SPARK subnet PSA 
resource "google_compute_global_address" "reserved_ip_for_psa_creation" { 
  project = local.project_id
  name          = "private-service-access-ip"
  purpose       = "VPC_PEERING"
  network       =  google_compute_network.golden_demo_default_network.id
  address_type  = "INTERNAL"
  prefix_length = local.psa_ip_length
  
  depends_on = [
    google_compute_subnetwork.spark-subnet
  ]
}
#SPARK subnet Service Networking 
resource "google_service_networking_connection" "private_connection_with_service_networking" {
  network       =  google_compute_network.golden_demo_default_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.reserved_ip_for_psa_creation.name]

  depends_on = [
    google_project_service.enable_servicenetworking_google_apis,
    google_compute_subnetwork.spark-subnet,
    google_compute_global_address.reserved_ip_for_psa_creation
  ]
}

#SPARK Subnet firewall rule
resource "google_compute_firewall" "spark-subnet-firewall-rule" {
 project       = "${local.project_id}"
  name     = "spark-firewall"
  network  = google_compute_network.golden_demo_default_network.id
  direction = "INGRESS"  
  allow {
    protocol = "all"
  }

  source_ranges = ["${local.spark_subnet_cidr}"]

  depends_on = [
    google_compute_subnetwork.spark-subnet
  ]
}

#SPARK GCS Bucket
resource "google_storage_bucket" "spark_stage_bucket_creation" {
  project                           = local.project_id 
  name                              = local.spark_stage_bucket
  location                          = local.region
  uniform_bucket_level_access       = true
  force_destroy                     = true
  
}
#Customize notebook startup script (upload .ipynb)
resource "null_resource" "customize_startup_script" {
    provisioner "local-exec" {
        command = "cp ../scripts-templates/nb-exec-post-startup.sh ../scripts-hydrated/ && sed -i s/___PROJECT_ID___/${local.project_id}/g ../scripts-hydrated/nb-exec-post-startup.sh"
    }
    depends_on = [
    google_storage_bucket.spark_stage_bucket_creation
  ]
}

#Upload the contents of `scripts-hydrated` to GCS
resource "google_storage_bucket_object" "scripts_dir_upload_to_gcs" {
  for_each = fileset("${path.module}/../scripts-hydrated/", "*")
  source = "${path.module}/../scripts-hydrated/${each.value}"
  name = "${each.value}"
  bucket = "${local.spark_stage_bucket}"
  depends_on = [
    google_storage_bucket.spark_stage_bucket_creation
  ]
}
#Vertex AI managed notebook
resource "google_notebooks_runtime" "spark_nb_server_creation" {
  project              = local.project_id
  name                 = local.spark_nb
  location             = local.region

  access_config {
    access_type        = "SERVICE_ACCOUNT"
    runtime_owner      = local.spark_sa_fqn
  }

  software_config {
    post_startup_script = "gs://${local.spark_stage_bucket}/nb-exec-post-startup.sh"
    post_startup_script_behavior = "DOWNLOAD_AND_RUN_EVERY_START"
  }

  virtual_machine {
    virtual_machine_config {
      machine_type     = local.spark_nb_machine_type
      #network = google_compute_network.golden_demo_default_network.id
      #network = "projects/${local.project_id}/global/networks/${local.vpc_nm}"
      #subnet = "projects/${local.project_id}/regions/${local.region}/subnetworks/${local.spark_subnet}" 

      data_disk {
        initialize_params {
          disk_size_gb = "100"
          disk_type    = "PD_STANDARD"
        }
      }
      container_images {
        repository = "gcr.io/deeplearning-platform-release/base-cpu"
        tag = "latest"
      }
    }
  }
  depends_on = [
    google_storage_bucket_object.scripts_dir_upload_to_gcs
  ]  
}

#Persistent History Server dataproc single node cluster
resource "google_dataproc_cluster" "phs_creation" {
  project  = local.project_id 
  name     = local.spark_phs
  region   = local.region

  cluster_config {
    
    endpoint_config {
        enable_http_port_access = true
    }

    staging_bucket = local.spark_stage_bucket
    software_config {
      image_version = "2.0"
      override_properties = {
        "dataproc:dataproc.allow.zero.workers"=true
        "dataproc:job.history.to-gcs.enabled"=true
        "spark:spark.history.fs.logDirectory"="gs://${local.spark_stage_bucket}/spark-job-history"
        "mapred:mapreduce.jobhistory.read-only.dir-pattern"="gs://${local.spark_stage_bucket}/mapreduce-job-history/done"
      }      
    }
    gce_cluster_config {
      subnetwork =  "projects/${local.project_id}/regions/${local.region}/subnetworks/${local.spark_subnet}" 
      service_account = local.spark_sa_fqn
      service_account_scopes = [
        "cloud-platform"
      ]
    }
  }
  depends_on = [
    google_notebooks_runtime.spark_nb_server_creation
  ]  
}
#Dataproc Metastore
resource "google_dataproc_metastore_service" "metastore_creation" {
  project  = local.project_id 
  service_id = local.spark_metastore
  location   = local.region
  port       = 9080
  tier       = "DEVELOPER"
  network    = google_compute_network.golden_demo_default_network.id

  maintenance_window {
    hour_of_day = 2
    day_of_week = "SUNDAY"
  }

  hive_metastore_config {
    version = "3.1.2"
  }

  depends_on = [
    google_dataproc_cluster.phs_creation   
  ]
}


