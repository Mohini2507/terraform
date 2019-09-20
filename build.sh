#! /bin/bash
#This Script is the initial stage where the CodeBuild will call and this will invoke Terraform to create Infra
###############################################################################
# Enable debugging
###############################################################################

export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log

###############################################################################
# Setting up mode
###############################################################################

set -x
export AWS_DEFAULT_REGION=us-east-1
export mode="apply"
if [ "$mode" == "plan" ]
then
  echo "Terraform plan mode...no changes will be made to AWS."
elif [ "$mode" == "apply" ]
then
  echo "Terraform apply mode...changes may be made to AWS if needed."
else
  echo "Invalid mode. It must be 'plan' or 'apply'"
  echo "Usage: ./build.sh <plan | apply>"
  exit 1
fi

###############################################################################
# Starting Terraform now
###############################################################################

echo " Terraform Started... "
cd ..

#TF_PLUGIN_CACHE_DIR="/codebuild/output/src*/src/.terraform-plugins" terraform init -input=false \
#    --backend-config "bucket=tf-state-store-bucket" \
#    --backend-config "region=us-east-1" \
#    --backend-config "profile=default"

echo "Terraform Init has been Completed working on Plan now"

terraform init
###############################################################################
# Terraform Init Done, Changing permissions of initial.sh
###############################################################################

chmod 700 ./initial.sh

###############################################################################
# Starting ./initial.sh which will invoke Terraform
###############################################################################

./initial.sh

###############################################################################
# Changing Permission for Security Purpose
###############################################################################

chmod 400 ./initial.sh

###############################################################################
# Cleaning up
###############################################################################
echo "Removing generated folders which maintains state..."
rm -rf tfplan .terraform
