#!/bin/bash

# Terraform settings
export TF_IN_AUTOMATION="true"
# The credentials file below should be generated prior to this script execution.
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcloud/application_default_credentials.json"
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
echo 'Lint succesfully done.'

echo -ne 'Documenting... '
RC=$(terraform-docs .)
if [ $? != 0 ]; then
    echo 'Documentation failed.'
    echo $RC
    exit 1
fi
echo 'Documented.'

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

apply=0
for action in $(terraform show -json plan.out | jq .resource_changes[].change.actions[])
do
    if [ $action != '"no-op"' ];
    then
        apply=1
    fi
done

if [ $apply == 0 ];
then
    echo '*WARNING: no infrastructure modifications are scheduled in this plan!'
fi

echo -ne 'Updating infrastructure... '
RC=$(terraform apply -no-color plan.out)
if [ $? != 0 ]; then
    echo 'Infrastructure update failed.'
    echo $RC
    exit 1
fi
echo 'Infrastructre updated.'

echo "*end: $(date)"