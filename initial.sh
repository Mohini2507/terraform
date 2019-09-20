#!/bin/bash
#This Script will inititalize the terraform and start the infra pipeline
###############################################################################
# Starting up
###############################################################################

rm -rf .terraform tfplan *.tfstate *.tfstate.*
source s3/s3.tf

###############################################################################
# Setting up Variables 
###############################################################################

#TF_PLUGIN_CACHE_DIR="/Users/skrishnan3/Documents/GitHub/POC/.terraform-plugins" terraform init -input=false \
#    --backend-config "bucket=tf-state-store-bucket" \
#    --backend-config "region=$region" \
#    --backend-config "profile=$aws_profile_name"

###############################################################################
# Starting on Terraform Plan
###############################################################################

echo "Terraform Init has been Completed working on Plan now"

terraform plan \
    -var-file=s3/s3.tf \
    -var blue_active=1 \
    -var green_active=0 \
    -var blue_aws_helper_version="RestackPOC_test" \
    -input=false \
    -out=tfplan

###############################################################################
# Terraform Apply stage
###############################################################################

terraform apply -input=false tfplan
echo "Exiting" 
