#!/bin/bash

# -----------------------------------------------------------------------------
# Script Name: force_update_services.sh
# Description: Forces an update for specified AWS ECS services within a cluster
#              by reapplying their current desired task counts.
# Usage: ./force_update_services.sh <cluster_name> <aws_region>
# Example: ./force_update_services.sh workers us-west-2
# -----------------------------------------------------------------------------

# Exit immediately if a command exits with a non-zero status
set -e

# Function to display usage instructions
usage() {
    echo "Usage: $0 <cluster_name> <aws_region>"
    echo "Example: $0 workers us-west-2"
    exit 1
}

# Check if exactly two arguments are provided (cluster name and AWS region)
if [ "$#" -ne 2 ]; then
    echo "Error: Both cluster name and AWS region are required."
    usage
fi

# Assign the first argument as the cluster name
CLUSTER_NAME="$1"

# Assign the second argument as the AWS region
AWS_REGION="$2"

# Define the list of ECS services to update
# NOTE: Do not use commas between service names. Use spaces instead.
services=(
sync_with_zoho_bulk_v2_svc
sync_with_zoho_delivery_v2_svc
sync_with_zoho_single_v2_svc
sync_with_zoho_v2_svc
web_user_worker_svc
)  # Replace with your actual service names

# Iterate over each service in the services array
for SERVICE_NAME in "${services[@]}"; do
    echo "---------------------------------------------"
    echo "Processing service '$SERVICE_NAME' in cluster '$CLUSTER_NAME'..."

    # Retrieve the current desired task count for the service
    DESIRED_COUNT=$(aws ecs describe-services \
        --cluster "$CLUSTER_NAME" \
        --services "$SERVICE_NAME" \
        --query "services[0].desiredCount" \
        --output text \
        --region "$AWS_REGION")

    # Check if the describe-services command was successful
    if [ "$DESIRED_COUNT" == "None" ] || [ -z "$DESIRED_COUNT" ]; then
        echo "✖ Failed to retrieve desired task count for service '$SERVICE_NAME'." >&2
        continue  # Skip to the next service
    fi

    echo "✔ Current desired task count for '$SERVICE_NAME': $DESIRED_COUNT"

    # Update the service with the same desired task count to force a new deployment
    UPDATE_COMMAND=(aws ecs update-service --force-new-deployment
        --cluster "$CLUSTER_NAME"
        --service "$SERVICE_NAME"
        --desired-count "$DESIRED_COUNT"
        --region "$AWS_REGION")

    echo "🔄 Forcing update for service '$SERVICE_NAME' with desired count $DESIRED_COUNT..."

    # Execute the update-service command
    if "${UPDATE_COMMAND[@]}" >/dev/null 2>&1; then
        echo "✔ Successfully forced update for service '$SERVICE_NAME'."
    else
        echo "✖ Failed to force update for service '$SERVICE_NAME'." >&2
    fi
done

echo "---------------------------------------------"
echo "All specified services have been processed."

