resource "google_dataproc_cluster" "create_phs" {
  project  = local.project_id 
  provider = google-beta
  name     = local.sphs_nm
  region   = local.location

  cluster_config {
    
    endpoint_config {
        enable_http_port_access = true
    }

    staging_bucket = local.sphs_bucket_nm
    
    # Override or set some custom properties
    software_config {
      image_version = "2.0"
      override_properties = {
        "dataproc:dataproc.allow.zero.workers"=true
        "dataproc:job.history.to-gcs.enabled"=true
        "spark:spark.history.fs.logDirectory"="gs://${local.sphs_bucket_nm}/*/spark-job-history"
        "mapred:mapreduce.jobhistory.read-only.dir-pattern"="gs://${local.sphs_bucket_nm}/*/mapreduce-job-history/done"
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
   time_sleep.sleep_after_network_resources_creation
  ]  
}

resource "google_storage_bucket" "create_sphs_bucket" {
  project                           = local.project_id 
  name                              = local.sphs_bucket_nm
  location                          = local.location
  uniform_bucket_level_access       = true
  force_destroy                     = true
}