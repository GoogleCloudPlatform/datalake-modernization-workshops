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
# 1. Local variables declaration
*******************************************/

locals {
project_id                  = "${var.project_id}"
location                    = "${var.location}"
vpc_nm                      = "vpc-biglake"
subnet_nm                   = "snet-biglake"
subnet_cidr                 = "10.0.0.0/16"
dataset_name                = "biglake_dataset"
bq_connection               = "biglake-gcs"
}

provider "google" {
  project = local.project_id
  region  = local.location
}

/******************************************
# 2. Creation of a VPC
******************************************/
resource "google_compute_network" "default_network" {
  project                 = var.project_id
  name                    = local.vpc_nm
  description             = "Default network"
  auto_create_subnetworks = false
  mtu                     = 1460
}

/******************************************
# 3. Creation of a subnet for dataproc cluster
*******************************************/ 
resource "google_compute_subnetwork" "subnet" {
  project       = var.project_id
  name          = local.subnet_nm  
  ip_cidr_range = local.subnet_cidr
  region        = var.location
  network       = google_compute_network.default_network.id
  private_ip_google_access = true

  depends_on = [
    google_compute_network.default_network
  ]
}

/******************************************
# 4. Creation of firewall rules
*******************************************/
resource "google_compute_firewall" "subnet_firewall_rule" {
  project  = var.project_id
  name     = "subnet-firewall"
  network  = google_compute_network.default_network.id

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }
  source_ranges = [local.subnet_cidr]

  depends_on = [
    google_compute_subnetwork.subnet
  ]
}

/******************************************
# 5. Creation of a router
*******************************************/
resource "google_compute_router" "nat-router" {
  name    = "nat-router"
  region  = "${var.location}"
  network  = google_compute_network.default_network.id

  depends_on = [
    google_compute_firewall.subnet_firewall_rule
  ]
}

/******************************************
# 6. Creation of a NAT
*******************************************/
resource "google_compute_router_nat" "nat-config" {
  name                               = "nat-config"
  router                             = "${google_compute_router.nat-router.name}"
  region                             = "${var.location}"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  depends_on = [
    google_compute_router.nat-router
  ]
}

# /******************************************
# 7. Creation of IAM groups
# *******************************************/

# resource "null_resource" "create_groups" {
#    for_each = {
#       "us-sales" : "",
#       "australia-sales" : ""
#     }
#   provisioner "local-exec" {
#     command = <<-EOT
#       thegroup=`gcloud identity groups describe ${each.key}@${var.org_id}  | grep -i "id:"  | cut -d':' -f2 |xargs`
#       #create group if it doesn't exist
#       if [ -z "$thegroup" ]; then
#         gcloud identity groups create ${each.key}@${var.org_id} --organization="${var.org_id}" --group-type="security" 
#       fi
#     EOT
#   }

# }

# resource "time_sleep" "wait_30_seconds" {

#   create_duration = "30s"
  
#   depends_on = [
#     null_resource.create_groups
#     ]

# }

# /******************************************
# 8. Creation of IAM group memberships to the sales groups for the sales users
# *******************************************/
    
# resource "null_resource" "create_memberships" {
#    for_each = {
#       "us-sales" : format("%s",var.rls_username1),
#       "australia-sales" : format("%s",var.rls_username2)
#     }
#   provisioner "local-exec" {
#     command = <<-EOT
#       thegroup=`gcloud identity groups memberships list --group-email="${each.key}@${var.org_id}" | grep -i "id:"  | cut -d':' -f2 |xargs`
#       #add member if not already a member
#       if ! [[ "$thegroup" == *"${each.value}"* ]]; 
#       then   
#         gcloud identity groups memberships add --group-email="${each.key}@${var.org_id}" --member-email="${each.value}@${var.org_id}" 
#       fi
#     EOT
#   }

#   depends_on = [
#     time_sleep.wait_30_seconds
#   ]

# }

# /******************************************
# 9. Creation of IAM group membership to the sales groups for the marketing user
# *******************************************/
# resource "null_resource" "create_memberships_mkt" {
#    for_each = {
#       "us-sales" : format("%s",var.cls_username),
#       "australia-sales" : format("%s",var.cls_username)
#     }
#   provisioner "local-exec" {
#     command = <<-EOT
#       thegroup=`gcloud identity groups memberships list --group-email="${each.key}@${var.org_id}" | grep -i "id:"  | cut -d':' -f2 |xargs`
#       #add member if not already a member
#       if ! [[ "$thegroup" == *"${each.value}"* ]]; 
#       then   
#         gcloud identity groups memberships add --group-email="${each.key}@${var.org_id}" --member-email="${each.value}@${var.org_id}" 
#       fi
#     EOT
#   }

#   depends_on = [
#     null_resource.create_memberships
#   ]

# }

/******************************************
# 10. Project Viewer permissions granting for all users
*******************************************/
  
resource "google_project_iam_binding" "project_viewer" {
  project = var.project_id
  role    = "roles/viewer"

  members = [
    "user:${var.rls_username1}",
    "user:${var.rls_username2}",
    "user:${var.cls_username}"
  ]
}

/******************************************
# 11. Dataproc editor permissions granting for all users
*******************************************/
resource "google_project_iam_binding" "dataproc_admin" {
  project = var.project_id
  role    = "roles/dataproc.editor"

  members = [
    "user:${var.rls_username1}",
    "user:${var.rls_username2}",
    "user:${var.cls_username}"
  ]
}

/******************************************
# 12. Storage object admin permissions granting for all users
*******************************************/
resource "google_project_iam_binding" "storage_object_admin" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"

  members = [
    "user:${var.rls_username1}",
    "user:${var.rls_username2}",
    "user:${var.cls_username}"
  ]
}

/******************************************
# 13. Service account user permissions granting for all users
*******************************************/
resource "google_project_iam_binding" "service_account_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"

  members = [
    "user:${var.rls_username1}",
    "user:${var.rls_username2}",
    "user:${var.cls_username}"
  ]
}

/******************************************
# 14. Create Dataproc cluster buckets for all users
*******************************************/

resource "google_storage_bucket" "create_buckets" {

  name                              = "dataproc-bucket-${var.project_nbr}"
  location                          = local.location
  uniform_bucket_level_access       = true
  force_destroy                     = true

}

/******************************************
# 16. Storage admin permissions granting to all users to the bucket
*******************************************/

resource "google_storage_bucket_iam_binding" "dataproc_bucket_policy" {
  bucket = "dataproc-bucket-${var.project_nbr}"
  role = "roles/storage.admin"
   members = [
                "user:${var.rls_username1}",
                "user:${var.rls_username2}",
                "user:${var.cls_username}"
  ]

  depends_on = [google_storage_bucket.create_buckets]
}

/******************************************
# 17. Dataproc Worker role granting to the compute engine default service account
*******************************************/
    
resource "google_project_iam_member" "service_account_worker_role" {
  project  = var.project_id
  role     = "roles/dataproc.worker"
  member   = "serviceAccount:${var.project_nbr}-compute@developer.gserviceaccount.com"

}

/*******************************************
# 18. Copying dataset to the dataproc bucket
*******************************************/

resource "google_storage_bucket_object" "gcs_objects" {

  name        = "IceCreamSales.csv"
  source      = "../../01-datasets/IceCreamSales.csv"
  bucket      = "dataproc-bucket-${var.project_nbr}"
 
 depends_on = [google_storage_bucket.create_buckets]
}

/******************************************
19. Uploading of IceCream notebook to user's GCS bucket where Dataproc expects it 
*******************************************/

resource "google_storage_bucket_object" "gcs_objects_user_dataproc" {

  name        = "notebooks/jupyter/IceCream.ipynb"
  source      = "../../00-scripts-and-config/notebook/IceCream.ipynb"
  bucket      = "dataproc-bucket-${var.project_nbr}"
 
  depends_on = [google_storage_bucket.create_buckets]
}



/******************************************
# 19. Creation of Data Catalog Taxonomy with policy type of "FINE_GRAINED_ACCESS_CONTROL"
*******************************************/

resource "google_data_catalog_taxonomy" "business_critical_taxonomy" {
  project  = var.project_id
  region   = var.location
  # Must be unique accross your Org
  display_name           = "Business-Critical-${var.project_nbr}"
  description            = "A collection of policy tags"
  activated_policy_types = ["FINE_GRAINED_ACCESS_CONTROL"]
}
  
/******************************************
# 20. Creation of Data Catalog policy tag tied to the taxonomy
*******************************************/

resource "google_data_catalog_policy_tag" "financial_data_policy_tag" {
  taxonomy     = google_data_catalog_taxonomy.business_critical_taxonomy.id
  display_name = "Financial Data"
  description  = "A policy tag normally associated with low security items"

  depends_on = [
    google_data_catalog_taxonomy.business_critical_taxonomy,
  ]
}

/******************************************
# 21. Granting of fine grained reader permisions to rls_username1@ and rls_username2@
*******************************************/
resource "google_data_catalog_policy_tag_iam_member" "member" {
  for_each = {
    "user:${var.rls_username1}" : "",
    "user:${var.rls_username2}" : ""

  }
  policy_tag = google_data_catalog_policy_tag.financial_data_policy_tag.name
  role       = "roles/datacatalog.categoryFineGrainedReader"
  member     = each.key
  depends_on = [
    google_data_catalog_policy_tag.financial_data_policy_tag,
  ]
}

/******************************************
# 22. Creation of BigQuery dataset
*******************************************/

resource "google_bigquery_dataset" "bigquery_dataset" {
  dataset_id                  = local.dataset_name
  friendly_name               = local.dataset_name
  description                 = "Dataset for BigLake Demo"
  location                    = var.location
  delete_contents_on_destroy  = true
}

/******************************************
# 23. Creation of BigQuery connection
*******************************************/

 resource "google_bigquery_connection" "connection" {
    connection_id = local.bq_connection
    project = var.project_id
    location = var.location
    cloud_resource {}
    depends_on = [google_bigquery_dataset.bigquery_dataset]
} 

/******************************************
# 24. Granting of Storage Object Viewer to the default Google Managed Service Account asssociated with the BigQuery connection created
*******************************************/
resource "google_project_iam_member" "connectionPermissionGrant" {
    project = var.project_id
    role = "roles/storage.objectViewer"
    member = format("serviceAccount:%s", google_bigquery_connection.connection.cloud_resource[0].service_account_id)
}    

/******************************************
# 26. Creation of BigLake table
*******************************************/
resource "google_bigquery_table" "biglakeTable" {
    ## If you are using schema autodetect, uncomment the following to
    ## set up a dependency on the prior delay.
    # depends_on = [time_sleep.wait_7_min]
    dataset_id = google_bigquery_dataset.bigquery_dataset.dataset_id
    table_id   = "IceCreamSales"
    project = var.project_id
    schema = <<EOF
    [
            {
                "name": "country",
                "type": "STRING"
            },
            {
                "name": "month",
                "type": "DATE"
                },
            {
                "name": "Gross_Revenue",
                "type": "FLOAT"
            },
            {
                "name": "Discount",
                "type": "FLOAT",
                "policyTags": {
                  "names": [
                    "${google_data_catalog_policy_tag.financial_data_policy_tag.id}"
                    ]
                }
            },
            {
                "name": "Net_Revenue",
                "type": "FLOAT",
                "policyTags": {
                  "names": [
                    "${google_data_catalog_policy_tag.financial_data_policy_tag.id}"
                    ]
                }
            }
    ]
    EOF
    external_data_configuration {
        ## Autodetect determines whether schema autodetect is active or inactive.
        autodetect = false
        source_format = "CSV"
        connection_id = google_bigquery_connection.connection.name

        csv_options {
            quote                 = "\""
            field_delimiter       = ","
            allow_quoted_newlines = "false"
            allow_jagged_rows     = "false"
            skip_leading_rows     = 1
        }

        source_uris = [
            "gs://dataproc-bucket-${var.project_nbr}/IceCreamSales.csv",
        ]
    }
    deletion_protection = false
    depends_on = [
              google_bigquery_connection.connection,
              google_data_catalog_policy_tag_iam_member.member
              ]
}
  
/******************************************
# 27. Creation of Row Access Policy for Australia
*******************************************/
resource "null_resource" "create_aus_filter" {
  provisioner "local-exec" {
    command = <<-EOT
      read -r -d '' QUERY << EOQ
      CREATE ROW ACCESS POLICY
        Australia_filter
        ON
        ${local.dataset_name}.IceCreamSales
        GRANT TO
        ("user:${var.rls_username2}", "user:${var.cls_username}")
        FILTER USING
        (Country="Australia")
      EOQ
      bq query --nouse_legacy_sql $QUERY
    EOT
  }

  depends_on = [google_bigquery_table.biglakeTable]
}

/******************************************
# 28. Creation of Row Access Policy for United States
*******************************************/
resource "null_resource" "create_us_filter" {
  provisioner "local-exec" {
    command = <<-EOT
      read -r -d '' QUERY << EOQ
      CREATE ROW ACCESS POLICY
        US_filter
        ON
        ${local.dataset_name}.IceCreamSales
        GRANT TO
        (
          "user:${var.rls_username1}",
          "user:${var.cls_username}"
          )
        FILTER USING
        (Country="United States")
      EOQ
      bq query --nouse_legacy_sql $QUERY
    EOT
  }

  depends_on = [null_resource.create_aus_filter]
}
