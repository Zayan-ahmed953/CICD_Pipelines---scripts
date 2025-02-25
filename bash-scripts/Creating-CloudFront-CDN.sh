#!/bin/bash

# Set variables
ORIGIN_NAME="forcdntesting-43553"  # Change this to your S3 bucket name
REGION="ap-south-1"  # Change this to match your bucket's region

# Create CloudFront distribution
aws cloudfront create-distribution --distribution-config "{
    \"CallerReference\": \"$(date +%s)\",
    \"Origins\": {
        \"Quantity\": 1,
        \"Items\": [
            {
                \"Id\": \"$ORIGIN_NAME\",
                \"DomainName\": \"$ORIGIN_NAME.s3-website.$REGION.amazonaws.com\",
                \"CustomOriginConfig\": {
                    \"HTTPPort\": 80,
                    \"HTTPSPort\": 443,
                    \"OriginProtocolPolicy\": \"http-only\"
                }
            }
        ]
    },
    \"DefaultCacheBehavior\": {
        \"TargetOriginId\": \"$ORIGIN_NAME\",
        \"ViewerProtocolPolicy\": \"redirect-to-https\",
        \"AllowedMethods\": {
            \"Quantity\": 2,
            \"Items\": [\"GET\", \"HEAD\"],
            \"CachedMethods\": {
                \"Quantity\": 2,
                \"Items\": [\"GET\", \"HEAD\"]
            }
        },
        \"ForwardedValues\": {
            \"QueryString\": false,
            \"Cookies\": {
                \"Forward\": \"none\"
            }
        },
        \"MinTTL\": 0,
        \"DefaultTTL\": 86400,
        \"MaxTTL\": 31536000
    },
    \"Comment\": \"S3 static website-backed CloudFront distribution\",
    \"Enabled\": true
}"


# This script creates an AWS CloudFront distribution for an S3 static website,  
# setting up caching, HTTPS redirection, and public access.
