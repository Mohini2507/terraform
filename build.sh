#! /bin/bash
#Author=Sumeet Krishnan
#This Script is the initial stage where the CodeBuild will call and this will invoke Packer for creation of AMI and Terraform to create Infra
###############################################################################
# Enable debugging
###############################################################################

export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log

###############################################################################
# Setting up mode
###############################################################################

set -x
export AWS_DEFAULT_REGION=us-west-2
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
# Fetching JSON Values (Use this if u want to do anything related to json values)
###############################################################################

curl -qL -o jq https://stedolan.github.io/jq/download/linux64/jq && chmod +x ./jq
BUCKET=restack-json-upload-poc
OBJECT="$(aws s3 ls $BUCKET --recursive | sort | tail -n 1 | awk '{print $4}')"
aws s3 cp s3://restack-json-upload-poc/$OBJECT .
mv restack2*.json restack.json
export EnvType=`./jq '.envType' restack.json`
echo "Enviroment type is:"
echo $EnvType
export BrmParam=`./jq '.brmParam' restack.json`
echo "BRM param is:"
echo $BrmParam
export Version=`./jq '.version' restack.json`
echo "Version no is:"
echo $Version
export Artifact=`./jq '.brmType' restack.json`
echo "Artifact selected is:"
echo $Artifact

###############################################################################
# AMI Created, Starting Terraform now
###############################################################################

echo " Ami Created Will move to Terraform now "
cd ..

TF_PLUGIN_CACHE_DIR="/codebuild/output/src*/src/.terraform-plugins" terraform init -input=false \
    --backend-config "bucket=poc-spinnaker-bucket" \
    --backend-config "region=us-west-2" \
    --backend-config "profile=default"

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
