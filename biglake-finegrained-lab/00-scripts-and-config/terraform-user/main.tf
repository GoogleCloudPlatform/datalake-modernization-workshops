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
1. Local variables declaration
*******************************************/

locals {
project_id                  = "${var.project_id}"
location                    = "${var.location}"
vpc_nm                      = "vpc-biglake"
subnet_nm                   = "snet-biglake"
subnet_cidr                 = "10.0.0.0/16"
dataset_name                = "biglake_dataset"
bq_connection               = "biglake-gcs"
user_id                     = split("@","${var.gcp_account_name}")[0]
}

provider "google" {
  project = local.project_id
  region  = local.location
}

/******************************************
1. Dataproc cluster creation 
*******************************************/

resource "google_dataproc_cluster" "dataproc_clusters" {
  name     = format( "%s-dataproc-cluster",local.user_id)
  project  = var.project_id
  region   = var.location
  cluster_config {
    staging_bucket = "dataproc-bucket-${var.project_nbr}"
    master_config {
      num_instances = 1
      machine_type  = "n1-standard-8"
      disk_config {
        #boot_disk_type    = "pd-ssd"
        boot_disk_size_gb = 1000
      }
    }
    
    preemptible_worker_config {
      num_instances = 0
    }
    endpoint_config {
        enable_http_port_access = "true"
    }
    # Override or set some custom properties
    software_config {
      image_version = "2.0-debian10"
      override_properties = {
        "dataproc:dataproc.personal-auth.user" = "${var.gcp_account_name}",
         "dataproc:dataproc.allow.zero.workers" = "true"
      }
      optional_components = [ "JUPYTER" ]
        
      
    }
    initialization_action {
      script      = "gs://goog-dataproc-initialization-actions-${var.location}/connectors/connectors.sh"
      timeout_sec = 300
    }
    initialization_action {
      script      = "gs://goog-dataproc-initialization-actions-${var.location}/python/pip-install.sh"
      timeout_sec = 300
    }

    gce_cluster_config {
      zone        = "${var.location}-a"
      subnetwork  = "projects/${local.project_id}/regions/${local.location}/subnetworks/${local.subnet_nm}"
      #service_account_scopes = ["cloud-platform"]
      service_account_scopes = ["https://www.googleapis.com/auth/iam"]
      internal_ip_only = true
      shielded_instance_config {
        enable_secure_boot          = true
        enable_vtpm                 = true
        enable_integrity_monitoring = true
        }
     metadata = {
        "spark-bigquery-connector-version" : "0.26.0",
        "PIP_PACKAGES" : "pandas prophet plotly"
        }   
    }
  }

}
