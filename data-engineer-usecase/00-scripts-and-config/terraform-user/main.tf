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
user_id                     = split("@","${var.gcp_account_name}")[0]
composer_nm                 = "${var.composer_nm}"
composer_bucket             = "${var.composer_bucket_nm}"
location                    = "us-central1"
dp_gce_bucket_nm            = "de-${local.user_id}-dp-gce-bucket-${local.project_nbr}"
dp_gce_cluster_nm           = "${local.user_id}-dp-gce-cluster"
metastore_nm                = "de-metastore-${local.project_nbr}"
subnet_nm                   = "de-subnet-${local.project_nbr}"
umsa                        = "de-umsa-${local.project_nbr}"
umsa_fqn                    = "${local.umsa}@${local.project_id}.iam.gserviceaccount.com"
}

/******************************************
1. Storage bucket creation
 *****************************************/

resource "google_storage_bucket" "dp_gce_bucket_creation" {
  name                              = "${local.dp_gce_bucket_nm}"
  location                          = "${local.location}"
  uniform_bucket_level_access       = true
  force_destroy                     = true
}

/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/
resource "time_sleep" "sleep_after_bucket_creation" {
  create_duration = "60s"
  depends_on = [
    google_storage_bucket.dp_gce_bucket_creation
  ]
}

/******************************************
2. Dataproc on GCE cluster creation
******************************************/

resource "google_dataproc_cluster" "tf_gce_cluster" {
  provider = google-beta
  name     = "${local.dp_gce_cluster_nm}"
  region   = local.location

  cluster_config {

    endpoint_config {
      enable_http_port_access = true
    }

    staging_bucket = "${local.dp_gce_bucket_nm}"

    # Override or set some custom properties
    software_config {
      image_version = "2.0"
      optional_components = [ "JUPYTER" ]
      override_properties = {
        "dataproc:dataproc.allow.zero.workers" = "false"
      }
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
      subnetwork =  "projects/${local.project_id}/regions/${local.location}/subnetworks/${local.subnet_nm}"
      service_account = local.umsa_fqn
      service_account_scopes = [
        "cloud-platform"
      ]
    }
    metastore_config {
    dataproc_metastore_service = "projects/${local.project_id}/locations/${local.location}/services/${local.metastore_nm}"
  }

  }
  depends_on = [
    time_sleep.sleep_after_bucket_creation
    ]
}

/******************************************
3. Customize scripts and notebooks
 *****************************************/
 # Copy from templates and replace variables


resource "null_resource" "serverless-dag-customization" {
    provisioner "local-exec" {
        command = "cp ../../05-templates/tl_pipeline.py ../../00-scripts-and-config/composer/ && sed -i s/USER_ID/${local.user_id}/g ../../00-scripts-and-config/composer/tl_pipeline.py"
        interpreter = ["bash", "-c"]
    }
}

resource "null_resource" "cluster-dag-customization" {
    provisioner "local-exec" {
        command = "cp ../../05-templates/tl_pipeline_cluster.py ../../00-scripts-and-config/composer/ && sed -i s/USER_ID/${local.user_id}/g ../../00-scripts-and-config/composer/tl_pipeline_cluster.py"
        interpreter = ["bash", "-c"]
    }
}

resource "null_resource" "mr-dag-customization" {
    provisioner "local-exec" {
        command = "cp ../../05-templates/mr_pipeline.py ../../00-scripts-and-config/composer/ && sed -i s/USER_ID/${local.user_id}/g ../../00-scripts-and-config/composer/mr_pipeline.py"
        interpreter = ["bash", "-c"]
    }
}

resource "null_resource" "composer-instructions-file-update" {
    provisioner "local-exec" {
        command = "cp ../../05-templates/airflow-execution.md ../../03-execution-instructions/ && sed -i s/YOUR_NAME/${local.user_id}/g ../../03-execution-instructions/airflow-execution.md && sed -i s/YOUR_COMPOSER_ENV/${local.composer_nm}/g ../../03-execution-instructions/airflow-execution.md && sed -i s/YOUR_PROJECT_ID/${local.project_id}/g ../../03-execution-instructions/airflow-execution.md"
        interpreter = ["bash", "-c"]
    }
}

resource "null_resource" "console-instructions-file-update" {
    provisioner "local-exec" {
        command = "cp ../../05-templates/console-execution.md ../../03-execution-instructions/ && sed -i s/YOUR_PROJECT_ID/${local.project_id}/g ../../03-execution-instructions/console-execution.md && sed -i s/YOUR_UMSA_NAME/${local.umsa}/g ../../03-execution-instructions/console-execution.md && sed -i s/YOUR_PROJECT_NUMBER/${local.project_nbr}/g ../../03-execution-instructions/console-execution.md && sed -i s/YOUR_NAME/${local.user_id}/g ../../03-execution-instructions/console-execution.md"
        interpreter = ["bash", "-c"]
    }
}

resource "null_resource" "cloud-shell-instructions-file-update" {
    provisioner "local-exec" {
        command = "cp ../../05-templates/gcloud-execution.md ../../03-execution-instructions/ && sed -i s/YOUR_PROJECT_ID/${local.project_id}/g ../../03-execution-instructions/gcloud-execution.md && sed -i s/YOUR_NAME/${local.user_id}/g ../../03-execution-instructions/gcloud-execution.md"
        interpreter = ["bash", "-c"]
    }
}

/*******************************************
4. Upload Airflow DAG to Composer DAG bucket
******************************************/

resource "google_storage_bucket_object" "upload_cc2_dag_to_airflow_dag_bucket" {
  name   = "dags/${local.user_id}_tl_pipeline.py"
  source = "../composer/tl_pipeline.py"
  bucket = "${local.composer_bucket}"
  depends_on = [
    null_resource.serverless-dag-customization
  ]
}

resource "google_storage_bucket_object" "upload_cc2_dag_to_airflow_dag_bucket_2" {
  name   = "dags/${local.user_id}_tl_pipeline_cluster.py"
  source = "../composer/tl_pipeline_cluster.py"
  bucket = "${local.composer_bucket}"
  depends_on = [
    null_resource.cluster-dag-customization
  ]
}

resource "google_storage_bucket_object" "upload_cc2_dag_to_airflow_dag_bucket_3" {
  name   = "dags/${local.user_id}_mr_pipeline.py"
  source = "../composer/mr_pipeline.py"
  bucket = "${local.composer_bucket}"
  depends_on = [
    null_resource.mr-dag-customization
  ]
}

/******************************************
5. Output important variables needed for the demo
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

output "DP_CLUSTER_NAME" {
  value = "${local.dp_gce_bucket_nm}"
}

/******************************************
DONE
******************************************/
