#!/bin/bash

# -----------------------------------------------------------------------------
# Script Name: add_placement_constraints.sh
# Description: Adds placement constraints to specified AWS ECS services within a cluster.
# Usage: ./add_placement_constraints.sh <cluster_name>
# Example: ./add_placement_constraints.sh my-ecs-cluster
# -----------------------------------------------------------------------------

# Exit immediately if a command exits with a non-zero status
set -e

# Function to display usage instructions
usage() {
    echo "Usage: $0 <cluster_name>"
    echo "Example: $0 my-ecs-cluster"
    exit 1
}

# Check if at least one argument is provided (cluster name)
if [ "$#" -lt 1 ]; then
    echo "Error: Cluster name is required."
    usage
fi

# Assign the first argument as the cluster name
CLUSTER_NAME="$1"

# Define the list of ECS services to update
# NOTE: Do not use commas between service names. Use spaces instead.


services=(
sync_with_zoho_bulk_v2_svc
sync_with_zoho_delivery_v2_svc
sync_with_zoho_single_v2_svc
sync_with_zoho_v2_svc
web_user_worker_svc
)  # Replace with your actual service names

# Define the placement constraints JSON
PLACEMENT_CONSTRAINTS='[
    {
        "type": "memberOf",
        "expression": "attribute:type == encrypted"
    }
]'

# Iterate over each service in the services array
for SERVICE_NAME in "${services[@]}"; do
    echo "---------------------------------------------"
    echo "Updating service '$SERVICE_NAME' in cluster '$CLUSTER_NAME'..."
    
    # Execute the AWS CLI command to update the service with placement constraints
    aws ecs update-service \
        --cluster "$CLUSTER_NAME" \
        --service "$SERVICE_NAME" \
        --placement-constraints "$PLACEMENT_CONSTRAINTS"

    # Check if the update was successful
    if [ $? -eq 0 ]; then
        echo "✔ Successfully updated service '$SERVICE_NAME'."
    else
        echo "✖ Failed to update service '$SERVICE_NAME'." >&2
    fi
done

echo "---------------------------------------------"
echo "All specified services have been processed."

