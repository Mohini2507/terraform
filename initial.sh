#!/bin/bash
#This Script will inititalize the terraform and start the infra pipeline
###############################################################################
# Starting up
###############################################################################

rm -rf .terraform tfplan *.tfstate *.tfstate.*
source context/QA/terraform.tfvars

###############################################################################
# Setting up Variables 
###############################################################################

TF_PLUGIN_CACHE_DIR="/Users/skrishnan3/Documents/GitHub/POC/.terraform-plugins" terraform init -input=false \
    --backend-config "bucket=poc-spinnaker-bucket" \
    --backend-config "dynamodb_table=terraform_lock_table" \
    --backend-config "key=qa/esd/terraform.tfstate" \
    --backend-config "region=$region" \
    --backend-config "profile=$aws_profile_name"

###############################################################################
# Starting on Terraform Plan
###############################################################################

echo "Terraform Init has been Completed working on Plan now"

terraform plan \
    -var-file=context/QA/terraform.tfvars \
    -var blue_active=1 \
    -var green_active=0 \
    -var blue_asg_min_size="1" \
    -var blue_asg_max_size="1" \
    -var blue_asg_desired_capacity="1" \
    -var blue_esd_service_version="RestackPOC" \
    -var blue_aws_helper_version="RestackPOC_test" \
    -var blue_ami_id=$ami_var\
    -var green_asg_min_size="0" \
    -var green_asg_max_size="0" \
    -var green_asg_desired_capacity="0" \
    -var green_esd_service_version="RestackPOC-v1" \
    -var green_aws_helper_version="RestackPOC_test_v1" \
    -var green_ami_id=$ami_var \
    -input=false \
    -out=tfplan

###############################################################################
# Terraform Apply stage
###############################################################################

terraform apply -input=false tfplan
terraform state rm module.base.aws_autoscaling_group.blue_asg
terraform state rm module.base.aws_launch_configuration.blue_lc

###############################################################################
# Send Email for Pipeline Notification
###############################################################################

curl -qL -o jq https://stedolan.github.io/jq/download/linux64/jq && chmod +x ./jq
BUCKET=restack-json-upload-poc
OBJECT="$(aws s3 ls $BUCKET --recursive | sort | tail -n 1 | awk '{print $4}')"
aws s3 cp s3://restack-json-upload-poc/$OBJECT .
mv restack2*.json restack.json
export chkNotify=`./jq '.chkNotify' restack.json`
echo $chkNotify
 if [ $chkNotify == "true" ]
 then
  echo "Sendin Mail to user"
  aws s3 cp s3://stack.infra/email.txt .
  openssl s_client -crlf -quiet -starttls smtp -connect email-smtp.us-west-2.amazonaws.com:587 < email.txt
  echo "Mail Send Successfully"
  else
  echo "Notify is disabled, Skipping MAIL"
 fi
 echo "Exiting" 
