# About:
# This script creates the Terraform tfvars file upon executing

PROJECT_ID=`gcloud config list --format "value(core.project)" 2>/dev/null`
PROJECT_NBR=`gcloud projects describe $PROJECT_ID | grep projectNumber | cut -d':' -f2 |  tr -d "'" | xargs`
PROJECT_NAME=`gcloud projects describe ${PROJECT_ID} | grep name | cut -d':' -f2 | xargs`
GCP_ACCOUNT_NAME=`gcloud auth list --filter=status:ACTIVE --format="value(account)"`
ORG_ID=`gcloud organizations list --format="value(name)"`
UPDATE_ORG_POLICIES="true"

echo "project_id = "\"$PROJECT_ID"\"" > terraform.tfvars
echo "project_number = "\"$PROJECT_NBR"\"" >> terraform.tfvars
echo "project_name = "\"$PROJECT_NAME"\"" >> terraform.tfvars
echo "gcp_account_name = "\"${GCP_ACCOUNT_NAME}"\"" >> terraform.tfvars
echo "org_id = "\"${ORG_ID}"\"" >> terraform.tfvars

echo "update_org_policies_bool = "\"$UPDATE_ORG_POLICIES"\"" >> terraform.tfvars 
