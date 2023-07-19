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
  bigquery_region                 = "us"
  vpc_nm                          = "vpc-main"
  gce_name                        = "gce-cdh-5-single-node"
  gce_subnet_nm                   = "gce-snet"
  gce_subnet_cidr                 = "10.6.0.0/16"
  cloudera_image_location         = "docker.io/cloudera/quickstart:latest"
  tf_sa_id                        =  "${local.project_id}@${local.project_id}.iam.gserviceaccount.com"
  tf_sa_key_location              = "../scripts-hydrated/local_key.json"
  hive_stage_bucket               = "hive_stage-${local.project_id}"
}


/******************************************
 API Enablement
 *****************************************/

resource "google_project_service" "service-serviceusage" {
  project = local.project_id
  service = "serviceusage.googleapis.com"
  disable_dependent_services  = true
}

resource "google_project_service" "service-cloudresourcemanager" {
  project = local.project_id
  service = "cloudresourcemanager.googleapis.com"
  disable_dependent_services  = true
}

resource "google_project_service" "service-servicemanagement" {
  project = local.project_id
  service = "servicemanagement.googleapis.com"
  disable_dependent_services  = true
}

resource "google_project_service" "service-orgpolicy" {
  project = local.project_id
  service = "orgpolicy.googleapis.com"
  disable_dependent_services  = true
}

resource "google_project_service" "service-compute" {
  project = local.project_id
  service = "compute.googleapis.com"
  disable_dependent_services  = true
}

resource "google_project_service" "service-bigquerystorage" {
  project = local.project_id
  service = "bigquerystorage.googleapis.com"
  disable_dependent_services  = true
}

resource "google_project_service" "service-bigqueryconnection" {
  project = local.project_id
  service = "bigqueryconnection.googleapis.com"
  disable_dependent_services  = true
}

resource "google_project_service" "service-dataproc" {
  project = local.project_id
  service = "dataproc.googleapis.com"
  disable_dependent_services  = true
}

resource "google_project_service" "service-biglake" {
  project = local.project_id
  service = "biglake.googleapis.com"
  disable_dependent_services  = true
}

resource "google_project_service" "enable_compute_google_apis" {
  project = local.project_id
  service = "compute.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "enable_container_google_apis" {
  project = local.project_id
  service = "container.googleapis.com"
  disable_dependent_services = true
  
}

resource "google_project_service" "service-servicenetworking" {
  project = local.project_id
  service = "servicenetworking.googleapis.com"
  disable_dependent_services  = true
}

resource "time_sleep" "google_api_activation_time_delay" {
  create_duration = "120s"
  depends_on = [
    google_project_service.service-serviceusage,
    google_project_service.service-cloudresourcemanager,
    google_project_service.service-servicemanagement,
    google_project_service.service-orgpolicy,
    google_project_service.service-compute,
    google_project_service.service-bigquerystorage,
    google_project_service.service-bigqueryconnection,
    google_project_service.service-dataproc,
    google_project_service.service-biglake,
    google_project_service.service-servicenetworking,
    google_project_service.enable_compute_google_apis,
    google_project_service.enable_container_google_apis
  ]  
}

/******************************************
 Org policies
 *****************************************/

resource "google_project_organization_policy" "orgPolicyUpdate_disableSerialPortLogging" {
  project                 = "${local.project_id}"
  constraint = "compute.disableSerialPortLogging"
  boolean_policy {
    enforced = false
  }
  depends_on = [
    time_sleep.google_api_activation_time_delay
  ]
}

resource "google_project_organization_policy" "orgPolicyUpdate_requireOsLogin" {
  project                 = "${local.project_id}"
  constraint = "compute.requireOsLogin"
  boolean_policy {
    enforced = false
  }
  depends_on = [
    time_sleep.google_api_activation_time_delay
  ]
}

resource "google_project_organization_policy" "orgPolicyUpdate_requireShieldedVm" {
  project                 = "${local.project_id}"
  constraint = "compute.requireShieldedVm"
  boolean_policy {
    enforced = false
  }
  depends_on = [
    time_sleep.google_api_activation_time_delay
  ]
}

resource "google_project_organization_policy" "orgPolicyUpdate_vmCanIpForward" {
  project                 = "${local.project_id}"
  constraint = "compute.vmCanIpForward"
  list_policy {
    allow {
      all = true
    }
  }
  depends_on = [
    time_sleep.google_api_activation_time_delay
  ]
}

resource "google_project_organization_policy" "orgPolicyUpdate_vmExternalIpAccess" {
  project                 = "${local.project_id}"
  constraint = "compute.vmExternalIpAccess"
  list_policy {
    allow {
      all = true
    }
  }
  depends_on = [
    time_sleep.google_api_activation_time_delay
  ]
}

resource "google_project_organization_policy" "orgPolicyUpdate_restrictVpcPeering" {
  project                 = "${local.project_id}"
  constraint = "compute.restrictVpcPeering"
  list_policy {
    allow {
      all = true
    }
  }
  depends_on = [
    time_sleep.google_api_activation_time_delay
  ]
}

resource "google_project_organization_policy" "orgPolicyUpdate_disableServiceAccountKeyCreation" {
  project                 = "${local.project_id}"
  constraint = "iam.disableServiceAccountKeyCreation"
   boolean_policy {
    enforced = false
  }
  depends_on = [
    time_sleep.google_api_activation_time_delay
  ]
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
 Custom Roles
 *****************************************/

resource "google_project_iam_custom_role" "customconnectiondelegate" {
  role_id     = "CustomConnectionDelegate"
  title       = "Custom Connection Delegate"
  description = "Used for BQ connections"
  permissions = ["biglake.tables.create","biglake.tables.delete","biglake.tables.get",
  "biglake.tables.list","biglake.tables.lock","biglake.tables.update",
  "bigquery.connections.delegate"]
  depends_on = [
    time_sleep.sleep_after_org_policy_updates
  ]
}

resource "google_project_iam_custom_role" "custom-role-custom-delegate" {
  role_id     = "CustomDelegate"
  title       = "Custom Delegate"
  description = "Used for BLMS connections"
  permissions = ["bigquery.connections.delegate"]
  depends_on = [
    google_project_iam_custom_role.customconnectiondelegate,
    time_sleep.sleep_after_org_policy_updates
  ]
}


/******************************************
 Network
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

#GCE subnet 
resource "google_compute_subnetwork" "gce-subnet" {
  project       = "${local.project_id}"
  name          = "${local.gce_subnet_nm}"
  ip_cidr_range = "${local.gce_subnet_cidr}"
  region        = "${local.region}"
  network       = google_compute_network.golden_demo_default_network.id
  private_ip_google_access = true
  depends_on = [
    time_sleep.sleep_after_org_policy_updates
  ]

}

resource "google_compute_firewall" "gce-subnet-firewall-rule" {
 project       = "${local.project_id}"
  name     = "gce-firewall"
  network  = google_compute_network.golden_demo_default_network.id

  allow {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]

  depends_on = [
    google_compute_subnetwork.gce-subnet
  ]
}

/******************************************
 Cloudera legacy container
 *****************************************/

module "gce-advanced-container" {
  source = "terraform-google-modules/container-vm/google"
    container = {
      image = "${local.cloudera_image_location}"
      #Needed to have a terminal inside the container
      tty = true
      stdin = true
      command = [
       "/usr/bin/docker-quickstart"
      ]
      securityContext = {
        privileged : true
      }
    }
  restart_policy = "OnFailure"
}

#GCE Boot disk
resource "google_compute_disk" "gce-boot-disk" {
  project = "${local.project_id}"
  name = "gce-boot-disk"
  type = "pd-standard"
  zone = "${local.zone}"
  size = 60
  image = module.gce-advanced-container.source_image
  depends_on = [
    google_project_service.enable_compute_google_apis
  ]
}

#GCE instance
resource "google_compute_instance" "gce-cdh-5-single-node" {
  project      = "${local.project_id}"
  name                      = "${local.gce_name}"
  machine_type              = "e2-standard-16"
  zone                      = "${local.zone}"
  boot_disk {
    source = google_compute_disk.gce-boot-disk.name
  }
  network_interface {
    network = google_compute_network.golden_demo_default_network.id
    subnetwork = google_compute_subnetwork.gce-subnet.id
    access_config {
    }
  }
  metadata = {
    gce-container-declaration = module.gce-advanced-container.metadata_value
  }
  labels = {
    container-vm = module.gce-advanced-container.vm_container_label
  }
  depends_on = [
    google_compute_disk.gce-boot-disk
  ]
}

/******************************************
 Storage
 *****************************************/

resource "google_storage_bucket" "hive_stage_bucket_creation" {
  project                           = local.project_id 
  name                              = local.hive_stage_bucket
  location                          = local.region
  uniform_bucket_level_access       = true
  force_destroy                     = true
  
}

/******************************************
 Service Account
 *****************************************/

resource "google_service_account" "service_account" {
  account_id   = local.project_id
  display_name = "Terraform Service Account"
  depends_on = [
    time_sleep.sleep_after_org_policy_updates
  ]
}

resource "google_project_iam_member" "service_account_owner" {
  project  = local.project_id
  role     = "roles/owner"
  member   = "serviceAccount:${google_service_account.service_account.email}"

  depends_on = [
    google_service_account.service_account
  ]
}

resource "google_service_account_key" "tf_sa_key" {
  service_account_id =  "${local.tf_sa_id}"
  public_key_type    = "TYPE_X509_PEM_FILE"
  depends_on = [
    google_service_account.service_account
  ]
}

resource "local_file" "json_local_sa" {
  content     = base64decode(google_service_account_key.tf_sa_key.private_key)
  filename = "${local.tf_sa_key_location}"
  depends_on = [
    google_service_account_key.tf_sa_key
  ]
}

/******************************************
 BigLake
 *****************************************/

# BigLake connection
resource "google_bigquery_connection" "biglake_connection" {
   connection_id = "biglake-connection"
   location      = local.bigquery_region
   friendly_name = "biglake-connection"
   description   = "biglake-connection"
   cloud_resource {}
   depends_on = [ 
      google_project_iam_custom_role.custom-role-custom-delegate
   ]
}

# Allow BigLake to read storage
resource "google_project_iam_member" "bq_connection_iam_object_viewer" {
  project  = local.project_id
  role     = "roles/storage.objectViewer"
  member   = "serviceAccount:${google_bigquery_connection.biglake_connection.cloud_resource[0].service_account_id}"

  depends_on = [
    google_bigquery_connection.biglake_connection
  ]
}

# Allow BigLake to custom role
resource "google_project_iam_member" "biglake_customconnectiondelegate" {
  project  = local.project_id
  role     = google_project_iam_custom_role.customconnectiondelegate.id
  member   = "serviceAccount:${google_bigquery_connection.biglake_connection.cloud_resource[0].service_account_id}"

  depends_on = [
    google_bigquery_connection.biglake_connection,
    google_project_iam_custom_role.customconnectiondelegate
  ]  
}

resource "null_resource" "customize_hdfs" {
  provisioner "local-exec" {
    command = "cp ../scripts-templates/core-site-add.xml ../scripts-hydrated/ && sed -i s/___PROJECT_ID___/${local.project_id}/g ../scripts-hydrated/core-site-add.xml"
  }
}

/******************************************
 Container start-up time
 *****************************************/

resource "time_sleep" "wait_after_gce" {
  depends_on = [google_compute_instance.gce-cdh-5-single-node]
  create_duration = "3m"
}
