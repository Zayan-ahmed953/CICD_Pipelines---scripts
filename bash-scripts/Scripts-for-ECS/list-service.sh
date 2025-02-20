#!/bin/bash
cluster_name="$1"
output_file="$2"

# Clear the output file if it exists
> $output_file

# Get all services in the cluster and process them in batches
aws ecs list-services --cluster $cluster_name --output text | awk '{print $2}' | while read service_arn; do
  # Fetch service details where desiredCount is not 0
  aws ecs describe-services --cluster $cluster_name --services $service_arn \
  --query 'services[?desiredCount!=`0`].[serviceName,desiredCount]' \
  --output text | awk '{print $1}' >> $output_file
done

# Sort and ensure the output is unique (optional)
sort -u $output_file -o $output_file

