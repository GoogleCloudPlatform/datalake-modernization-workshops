resource "google_notebooks_runtime" "create_mnb_server" {

  project              = local.project_id
  provider             = google-beta
  name                 = local.mnb_server_nm
  location             = local.location

  access_config {
    access_type        = "SERVICE_ACCOUNT"
    runtime_owner      = local.umsa_fqn
  }

  software_config {
    post_startup_script = "gs://${local.code_bucket_nm}/mnbs-exec-post-startup.sh"
    post_startup_script_behavior = "RUN_EVERY_START"
  }

  virtual_machine {
    virtual_machine_config {
      machine_type     = local.mnb_server_machine_type
      network = "projects/${local.project_id}/global/networks/${local.vpc_nm}"
      subnet = "projects/${local.project_id}/regions/${local.location}/subnetworks/${local.subnet_nm}"

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
  depends_on = [time_sleep.sleep_after_bucket_creation,
                null_resource.create_mnbs_post_startup_bash,
                null_resource.create_notebook_1,
                null_resource.create_notebook_2,
                null_resource.create_notebook_3,
                null_resource.create_notebook_4,
                null_resource.create_notebook_5,
                null_resource.create_notebook_6,
                null_resource.create_notebook_7,
                null_resource.create_notebook_8,
                null_resource.create_notebook_9
  ]
}
