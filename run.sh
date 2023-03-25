#!/bin/bash

# TODO: Run fails if apply requires confirmation to create resources.

# Terraform settings
export TF_IN_AUTOMATION="true"
export TF_INPUT=0
TF_CLI_ARGS="-no-color"
TF_CLI_ARGS_fmt="-diff -recursive"
# Workspace selected from argument call
export TF_WORKSPACE="$1-workspace"
# Uncomment the following line to enable DEBUG logging
#export TF_LOG="debug"

# Function to call any terraform subcommand.
action() {
    echo -ne "\taction: " $(echo $1 | tr '[:lower:]' '[:upper:]') " ... "
    if [ "$1" == "docs" ]; then
        RC=$(terraform-docs .)
    else
        RC=$(terraform $1)
    fi
    if [ $? != 0 ]; then
        echo "failed."
        echo $RC
        exit 1
    fi
    echo "succeeded."
}

echo "*start: $(date)"

action "fmt"
action "docs"
action "init"
action "validate"
action "apply"

echo "*end: $(date)"
exit 0
# End of script