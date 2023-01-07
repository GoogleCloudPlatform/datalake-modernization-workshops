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
*******************************************/

locals {
lab_prefix                  = "dll"
project_id                  = "${var.project_id}"
project_nbr                 = "${var.project_nbr}"
location                    = "${var.location}"
gcp_account_name            = "${var.gcp_account_name}"
vpc_nm                      = "${local.lab_prefix}-vpc"
subnet_nm                   = "${local.lab_prefix}-snet"
nat_nm                      = "${local.lab_prefix}-nat"
nat_router_nm               = "${local.lab_prefix}-nat-router"
subnet_cidr                 = "10.0.0.0/16"
psa_ip_length               = 16
dataset_name                = "${local.lab_prefix}loan_bqds"
umsa                        = "${local.lab_prefix}-lab-sa"
umsa_fqn                    = "${local.umsa}@${local.project_id}.iam.gserviceaccount.com"
admin_upn_fqn               = "${var.gcp_account_name}"
user_id                     = split("@","${var.gcp_account_name}")[0]
spark_bucket_nm             = "${local.lab_prefix}-spark-bucket-${var.project_nbr}-${local.user_id}"
data_bucket_nm              = "${local.lab_prefix}-data-bucket-${var.project_nbr}-${local.user_id}"
code_bucket_nm              = "${local.lab_prefix}-code-bucket-${var.project_nbr}-${local.user_id}"
dpms_nm                     = "${local.lab_prefix}-hms-${local.project_nbr}"
sphs_nm                     = "${local.lab_prefix}-sphs-${local.project_nbr}"
sphs_bucket_nm              = "${local.lab_prefix}-sphs-bucket-${local.project_nbr}"
mnb_server_machine_type     = "n1-standard-4"
mnb_server_nm               = "${local.lab_prefix}-spark-ml-interactive-nb-server-${local.user_id}"
}

provider "google" {
  project = local.project_id
  region  = local.location
}

