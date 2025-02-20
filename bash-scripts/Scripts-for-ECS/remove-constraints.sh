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
activity_audit_svc
audience_manager_consumer_create_svc
audience_manager_consumer_identity_svc
audience_manager_consumer_property_svc
audience_manager_contact_list_migration_processor_svc
audience_manager_contact_processer_svc
audience_manager_conversations_processer_svc
audience_manager_csv_processer_svc
automation_campaign_worker-svc
business_hour_autoreply_worker_svc
campaign_task_event_listener_svc
chatbot_adapter_svc
consent_batch_processor
consent_callback_worker_svc
consent_executor
converasation_flow_event_processor_svc
converse_app_tasks_worker_svc
converse_event_worker_svc
converse_integrations_consents_worker_svc
converse_integrations_leads_worker_svc
converse_integration_worker_svc
converse_polling_dispatcher_svc
converse_polling_worker_svc
converse_sync_audit_worker_svc
converse_sync_consent_worker_svc
converse_sync_delivery_worker_svc
converse_sync_incoming_worker_svc
converse_sync_keyword_worker_svc
converse_sync_outgoing_worker_svc
converse_sync_worker_svc
conversive_ai_tracing_worker_svc
conversive_analytics_worker_svc
data_export_services_svc
dlr_worker_delivery_batch_processor_svc
dlr_worker_delivery_number_predictor_svc
dlr_worker_delivery_processor_svc
dlr_worker_delivery_push_to_url_svc
email_engine
incoming_mobile_verify_worker_svc
message_scheduler
migrate-mms-to-sf-svc
mobile_verify_worker_svc
pardot_lead_sync_worker-svc
process-mobile-notify-proxy-sf-svc
provider_consent_worker_svc
push_delivery_notifier_svc
push_notifications_svc
qr_code_analytics_svc
redis_subscriber_svc
repush-incoming-to-sf-svc
salesforce_push
shared_inbox_auto_reply_svc
sms_campaign_csv_render_worker-svc
subscription_worker_svc
sync_incoming_with_salesforce-svc
sync-proxy-incoming-status-svc
sync_sender_id_salesforce
sync_with_bullhorn_svc
sync_with_zoho_automation_v2_svc
sync_with_zoho_bulk_delivery_svc
sync_with_zoho_bulk_v2_svc
sync_with_zoho_delivery_v2_svc
sync_with_zoho_single_v2_svc
sync_with_zoho_v2_svc
web_user_worker_svc
)  # Replace with your actual service names

# Define the placement constraints JSON
PLACEMENT_CONSTRAINTS='[]'

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

