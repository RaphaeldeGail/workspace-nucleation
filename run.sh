#!/bin/bash

DRY_RUN=false
while getopts 'd' OPTION; do
  case "$OPTION" in 
    d) 
      echo "This will be a dry run test..."
      DRY_RUN=true
      ;;

    ?) 
      echo "Usage: $(basename $0) [-d]"
      exit 1
      ;;
  esac
done

# The credentials file below should be generated prior to this script execution.
if [ ! -f $HOME/.config/gcloud/application_default_credentials.json ]; then
    echo 'The application default credentials could not be found.'
    echo "$HOME/.config/gcloud/application_default_credentials.json: File not found."
    echo 'Please log in to GCP prior to runnning this script with: `gcloud auth application-default login`'
    exit 1
fi
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcloud/application_default_credentials.json"
# Terraform settings
export TF_IN_AUTOMATION="true"
export TF_INPUT=0
# Uncomment the following line to enable DEBUG logging
#export TF_LOG="debug"


echo "*start: $(date)"

echo -ne 'Linting... '
RC=$(terraform fmt -diff -recursive .)
if [ $? != 0 ]; then
    echo 'Lint failed.'
    echo $RC
    exit 1
fi
echo 'Successfully lint.'

echo -ne 'Documenting... '
RC=$(terraform-docs .)
if [ $? != 0 ]; then
    echo 'Documentation failed.'
    echo $RC
    exit 1
fi
echo 'Succesfully documented.'

echo -ne 'Initializing working directory... '
RC=$(terraform init -no-color)
if [ $? != 0 ]; then
    echo 'Initialization failed.'
    echo $RC
    exit 1
fi
echo 'Working directory initialized.'

echo -ne 'Validating code... '
RC=$(terraform validate -no-color)
if [ $? != 0 ]; then
    echo 'Validation failed.'
    echo $RC
    exit 1
fi
echo 'Code validated.'

echo -ne 'Planning infrastructure update... '
RC=$(terraform plan -no-color -out plan.out)
if [ $? != 0 ]; then
    echo 'Infrastructure plan failed.'
    echo $RC
    exit 1
fi
echo 'Infrastructure update planned.'

RC=$(terraform show -json plan.out | jq '( .output_changes | to_entries | .[] | select(.value.actions != ["no-op"]) | {(.key): (.value.actions)} ), ( .resource_changes[] |  select(.change.actions != ["no-op"]) | {(.address): (.change.actions)} )')
if [ -z "$RC" ];
then
    echo '*WARNING: no infrastructure modifications are scheduled in this plan!'
    echo "*end: $(date)"
    exit 0
else
    echo '***Plan***'
    echo -e $RC
    echo '******'
fi

if $DRY_RUN; then
    echo "*end: $(date)"
    exit 0
fi

echo -ne 'Updating infrastructure... '
RC=$(terraform apply -no-color plan.out)
if [ $? != 0 ]; then
    echo 'Infrastructure update failed.'
    echo $RC
    exit 1
fi
rm -f plan.out
echo 'Infrastructre updated.'

echo "*end: $(date)"
exit 0
# End of script