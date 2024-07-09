variable "project_id" {
  type        = string
  description = "project id required"
}
variable "project_name" {
 type        = string
 description = "project name"
}
variable "project_number" {
 type        = string
 description = "project number"
}
variable "gcp_account_name" {
 description = "lab user's FQN"
}
variable "deployment_service_account_name" {
 description = "Cloudbuild_Service_account/lab user having permission to deploy terraform resources"
}
variable "org_id" {
 description = "Organization ID in which project created"
}
variable "cloud_composer_image_version" {
 description = "Version of Cloud Composer 2 image to use"
}
variable "gcp_region" {
 description = "The GCP region you want to use"
}