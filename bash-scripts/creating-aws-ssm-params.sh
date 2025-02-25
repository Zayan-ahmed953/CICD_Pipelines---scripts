#!/bin/bash

echo "Select the environment by entering the corresponding number"
echo "1. Integration"
echo "2. QA"
echo "3. Staging"
echo "4. Prod_AUS"
echo "5. Prod_EU"
echo "6. Prod_US"

read -p "Enter your choice (1-6): " choice

echo ""
read -p "Enter the worker name in capital letters, for example, INCOMING_SMS_HANDLER: " WORKER_NAME

export PARAM_PATH_PREFIX="/SAAS-WORKERS/DELIVERY_REPORT_PYTHON_WORKER"
case "$choice" in
  1)
    env="Integration"
    AWS_REGION="us-east-1"
    ;;
  2)
    env="QA"
    AWS_REGION="us-east-1"
    ;;
  3)
    env="Staging"
    AWS_REGION="us-east-1"
    ;;
  4)
    env="Prod_AUS"
    AWS_REGION="ap-southeast-2"
    ;;
  5)
    env="Prod_EU"
    AWS_REGION="eu-west-1"
    ;;
  6)
    env="Prod_US"
    AWS_REGION="us-east-1"
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac

echo ""
echo "Environment selected: $env"
echo "AWS Region: $AWS_REGION"
echo "Parameter Path Prefix: ${PARAM_PATH_PREFIX}${WORKER_NAME}"

echo ""
read -p "Are you sure you have chosen the right option? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "Operation aborted by the user."
  exit 1
fi

echo ""
read -p "To only add new variables, or to update old variables as well, enter 'overwrite' to update old variables as well: " action

if [ "$action" = "overwrite" ]; then
  OVERWRITE_FLAG="--overwrite"
else
  OVERWRITE_FLAG=""
fi

while IFS= read -r line; do
  # Skip empty lines and lines starting with #
  [[ -z "$line" || "$line" =~ ^# ]] && continue
  
  # Split the line into name and value, considering the use of '=' in value
  VARNAME=$(echo "$line" | cut -d '=' -f 1)
  VARVALUE=$(echo "$line" | cut -d '=' -f 2-)
  
  # Prepend the parameter path prefix to the VARNAME
  NEWVARNAME="${PARAM_PATH_PREFIX}${WORKER_NAME}/$VARNAME"
 
  echo ""
  # Print the variable name and value
  echo "$NEWVARNAME=$VARVALUE"
  
  # Store the variable in AWS SSM Parameter Store as a Secure String using cli-input-json
  aws ssm put-parameter --cli-input-json "{
    \"Name\": \"$NEWVARNAME\",
    \"Value\": \"$VARVALUE\",
    \"Type\": \"SecureString\"
  }" $OVERWRITE_FLAG --region $AWS_REGION
done < "${1}"


# To run the script provide the .snv file that only has the values for example Variable1=Value1
# If theres a naming convention that needs to be on the start give that in the line no 16 of this script 

# Before running the script you must have aws cli access to the aws account 

# example run 

# ./ssm.sh <path to env-file>
