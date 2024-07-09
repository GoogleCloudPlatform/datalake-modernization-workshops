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
variable "org_id" {
 description = "Organization ID in which project created"
}
variable "gcp_region" {
 description = "The GCP region you want to use"
}
