resource "google_dataproc_metastore_service" "create_dataproc_metastore" {
  service_id = local.dpms_nm
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
    # time_sleep.sleep_after_iam_permissions_grants,
    time_sleep.sleep_after_network_resources_creation
  ]
}

/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/

resource "time_sleep" "sleep_after_dpms_creation" {
  create_duration = "120s"
  depends_on = [
    google_dataproc_metastore_service.create_dataproc_metastore
  ]
}