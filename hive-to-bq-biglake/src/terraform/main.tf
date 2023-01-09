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
  gce_name                        = "gce-cdh-5-single-node"
  gce_subnet_nm                   = "gce-snet"
  gce_subnet_cidr                 = "10.6.0.0/16"
  cloudera_image_location         = "docker.io/cloudera/quickstart:latest"
  tf_sa_id                        =  "${local.project_id}@${local.project_id}.iam.gserviceaccount.com"
  tf_sa_key_location                = "../scripts-hydrated/local_key.json"
  hive_stage_bucket                 = "hive_stage-${local.project_id}"
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

#Cloudera legacy container
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
 project      = "${local.project_id}"
 name = "gce-boot-disk"
 type = "pd-standard"
 zone = "${local.zone}"
 size = 60
 image = module.gce-advanced-container.source_image
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
}



resource "google_storage_bucket" "hive_stage_bucket_creation" {
  project                           = local.project_id 
  name                              = local.hive_stage_bucket
  location                          = local.region
  uniform_bucket_level_access       = true
  force_destroy                     = true
  
}

resource "google_service_account_key" "tf_sa_key" {
  service_account_id =  "${local.tf_sa_id}"
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "local_file" "json_local_sa" {
    content     = base64decode(google_service_account_key.tf_sa_key.private_key)
    filename = "${local.tf_sa_key_location}"

}

resource "null_resource" "customize_hdfs" {
    provisioner "local-exec" {
        command = "cp ../scripts-templates/core-site-add.xml ../scripts-hydrated/ && sed -i s/___PROJECT_ID___/${local.project_id}/g ../scripts-hydrated/core-site-add.xml"
    }
}

#Container start-up time
resource "time_sleep" "wait_after_gce" {
depends_on = [google_compute_instance.gce-cdh-5-single-node]
create_duration = "3m"
}
