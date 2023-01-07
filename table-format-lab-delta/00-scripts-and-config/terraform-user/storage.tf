/******************************************************
Create storage buckets
 ******************************************************/
resource "google_storage_bucket" "create_spark_bucket" {
  project                           = local.project_id
  name                              = local.spark_bucket_nm
  location                          = local.location
  uniform_bucket_level_access       = true
  force_destroy                     = true
}

resource "google_storage_bucket" "create_data_bucket" {
  project                           = local.project_id
  name                              = local.data_bucket_nm
  location                          = local.location
  uniform_bucket_level_access       = true
  force_destroy                     = true
}

resource "google_storage_bucket" "create_code_bucket" {
  project                           = local.project_id
  name                              = local.code_bucket_nm
  location                          = local.location
  uniform_bucket_level_access       = true
  force_destroy                     = true
}

/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/

resource "time_sleep" "sleep_after_bucket_creation" {
  create_duration = "90s"
  depends_on = [
    google_storage_bucket.create_spark_bucket,
    google_storage_bucket.create_data_bucket,
    google_storage_bucket.create_code_bucket
  ]
}

/******************************************
Copy data to buckets
******************************************/

resource "google_storage_bucket_object" "copy_datasets" {
  for_each = fileset("../../01-datasets/", "*")
  source = "../../01-datasets/${each.value}"
  name = "${each.value}"
  bucket = "${local.data_bucket_nm}"
  depends_on = [
    time_sleep.sleep_after_bucket_creation
  ]
}

/*******************************************
Customize managed notebook post-startup script & Notebooks
********************************************/

resource "null_resource" "create_mnbs_post_startup_bash" {
    provisioner "local-exec" {
        command = "cp ../../04-templates/mnbs-exec-post-startup-template.sh ../../03-notebooks/mnbs-exec-post-startup.sh && sed -i s/YOUR_PROJECT_NBR/${local.project_nbr}/g ../../03-notebooks/mnbs-exec-post-startup.sh && sed -i s/YOUR_ACCOUNT_NAME/${local.user_id}/g ../../03-notebooks/mnbs-exec-post-startup.sh"
}
 depends_on = [
    google_storage_bucket.create_code_bucket
  ]
}

resource "null_resource" "create_notebook_1" {
    provisioner "local-exec" {
        command = "cp ../../04-templates/DeltaLakeLab-1.ipynb ../../03-notebooks/DeltaLakeLab-1.ipynb && sed -i s/YOUR_ACCOUNT_NAME/${local.user_id}/g ../../03-notebooks/DeltaLakeLab-1.ipynb"
}
 depends_on = [
    google_storage_bucket.create_code_bucket
  ]
}

resource "null_resource" "create_notebook_2" {
    provisioner "local-exec" {
        command = "cp ../../04-templates/DeltaLakeLab-2.ipynb ../../03-notebooks/DeltaLakeLab-2.ipynb && sed -i s/YOUR_ACCOUNT_NAME/${local.user_id}/g ../../03-notebooks/DeltaLakeLab-2.ipynb"
}
 depends_on = [
    google_storage_bucket.create_code_bucket
  ]
}

resource "null_resource" "create_notebook_3" {
    provisioner "local-exec" {
        command = "cp ../../04-templates/DeltaLakeLab-3.ipynb ../../03-notebooks/DeltaLakeLab-3.ipynb && sed -i s/YOUR_ACCOUNT_NAME/${local.user_id}/g ../../03-notebooks/DeltaLakeLab-3.ipynb"
}
 depends_on = [
    google_storage_bucket.create_code_bucket
  ]
}

resource "null_resource" "create_notebook_4" {
    provisioner "local-exec" {
        command = "cp ../../04-templates/DeltaLakeLab-4.ipynb ../../03-notebooks/DeltaLakeLab-4.ipynb && sed -i s/YOUR_ACCOUNT_NAME/${local.user_id}/g ../../03-notebooks/DeltaLakeLab-4.ipynb"
}
 depends_on = [
    google_storage_bucket.create_code_bucket
  ]
}

resource "null_resource" "create_notebook_5" {
    provisioner "local-exec" {
        command = "cp ../../04-templates/DeltaLakeLab-5.ipynb ../../03-notebooks/DeltaLakeLab-5.ipynb && sed -i s/YOUR_ACCOUNT_NAME/${local.user_id}/g ../../03-notebooks/DeltaLakeLab-5.ipynb"
}
 depends_on = [
    google_storage_bucket.create_code_bucket
  ]
}

resource "null_resource" "create_notebook_6" {
    provisioner "local-exec" {
        command = "cp ../../04-templates/DeltaLakeLab-6.ipynb ../../03-notebooks/DeltaLakeLab-6.ipynb && sed -i s/YOUR_ACCOUNT_NAME/${local.user_id}/g ../../03-notebooks/DeltaLakeLab-6.ipynb"
}
 depends_on = [
    google_storage_bucket.create_code_bucket
  ]
}

resource "null_resource" "create_notebook_7" {
    provisioner "local-exec" {
        command = "cp ../../04-templates/DeltaLakeLab-7.ipynb ../../03-notebooks/DeltaLakeLab-7.ipynb && sed -i s/YOUR_ACCOUNT_NAME/${local.user_id}/g ../../03-notebooks/DeltaLakeLab-7.ipynb"
}
 depends_on = [
    google_storage_bucket.create_code_bucket
  ]
}

resource "null_resource" "create_notebook_8" {
    provisioner "local-exec" {
        command = "cp ../../04-templates/DeltaLakeLab-8.ipynb ../../03-notebooks/DeltaLakeLab-8.ipynb && sed -i s/YOUR_ACCOUNT_NAME/${local.user_id}/g ../../03-notebooks/DeltaLakeLab-8.ipynb"
}
 depends_on = [
    google_storage_bucket.create_code_bucket
  ]
}

resource "null_resource" "create_notebook_9" {
    provisioner "local-exec" {
        command = "cp ../../04-templates/DeltaLakeLab-9.ipynb ../../03-notebooks/DeltaLakeLab-9.ipynb && sed -i s/YOUR_ACCOUNT_NAME/${local.user_id}/g ../../03-notebooks/DeltaLakeLab-9.ipynb"
}
 depends_on = [
    google_storage_bucket.create_code_bucket
  ]
}

/******************************************
Copy code to the code bucket
******************************************/

resource "google_storage_bucket_object" "upload_code_to_code_bucket" {
  for_each = fileset("../../03-notebooks/", "*")
  source = "../../03-notebooks/${each.value}"
  name = "${each.value}"
  bucket = "${local.code_bucket_nm}"
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

/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/

resource "time_sleep" "sleep_after_bucket_uploads" {
  create_duration = "90s"
  depends_on = [
    google_storage_bucket_object.copy_datasets,
    google_storage_bucket_object.upload_code_to_code_bucket,

  ]
}
