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
activity_audit_svc
audience_manager_consumer_create_svc
audience_manager_consumer_identity_svc
audience_manager_consumer_property_svc
audience_manager_contact_list_migration_processor_svc
audience_manager_contact_processer_svc
audience_manager_conversations_processer_svc
audience_manager_csv_processer_svc
billing_usage_event_worker_svc
billing_worker_svc
business_hour_autoreply_worker_svc
campaign_task_event_listener_svc
chatbot_adapter_svc
consent_batch_processor
consent_callback_worker_svc
consent_executor
converse_app_tasks_worker_svc
converse_event_worker_svc
converse_integration_worker_svc
converse_integrations_consents_worker_svc
converse_integrations_leads_worker_svc
converse_polling_dispatcher_svc
converse_polling_worker_svc
converse_sync_audit_worker_svc
converse_sync_consent_worker_svc
converse_sync_delivery_worker_svc
converse_sync_incoming_worker_svc
converse_sync_keyword_worker_svc
converse_sync_outgoing_worker_svc
converse_sync_worker_svc
converse_tasks_worker_svc
converse_worker_svc
conversive_ai_tracing_worker_svc
conversive_analytics_worker_svc
credit_deduction_svc
data_export_services_svc
delivery-report-python-engine-svc
delivery_report_python_engine_bulk_svc
delivery_report_python_engine_default_svc
delivery_report_python_engine_priority_svc
dlr_worker_delivery_batch_processor-svc
dlr_worker_delivery_number_predictor_svc
dlr_worker_delivery_processor_svc
dlr_worker_delivery_push_to_url_svc
email_engine
incoming-sms-handler-svc
incoming_mobile_verify_worker_svc
message_scheduler
message_scheduler_svc
metering_sync_service
migrate-mms-to-sf-svc
mobile_verify_worker
mobile_verify_worker_svc
onebill_balance_sync_svc
pardot_lead_sync_worker-svc
process_message_events_svc
provider_consent_worker_svc
push_delivery_notifier_svc
push_notifications_svc
push_notifications_svc_1
python-scheduler_svc
qr_code_analytics_svc
redis_subscriber_svc
repush-incoming-to-sf-svc
saas-adhoc-svc
salesforce_push
send_message_svc
sms_campaign_csv_render_worker-svc
subscription_worker_svc
sync_incoming_with_salesforce-svc
sync_sender_id_salesforce
sync_with_bulk_delivery_svc
sync_with_bullhorn_svc
sync_with_zoho_automation_v2_svc
sync_with_zoho_bulk_v2_svc
sync_with_zoho_delivery_v2_svc
sync_with_zoho_single_v2_svc
sync_with_zoho_v2_svc
usage_event_batch_processor_svc
web_user_worker_svc
zoho-campaign-worker-svc
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

