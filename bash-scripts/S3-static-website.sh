#!/bin/bash

# Variables
BUCKET_NAME="forcdntesting-43553"
REGION="ap-south-1"
FOLDER_PATH="/home/zayan/alkari-automation/mywebapp"  # Change this to the folder you want to upload


# Create S3 bucket
aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION" --create-bucket-configuration LocationConstraint="$REGION"

# Enable public access block settings (disable block public access)
aws s3api delete-public-access-block --bucket "$BUCKET_NAME"

# Enable static website hosting
aws s3 website s3://$BUCKET_NAME/ --index-document index.html --error-document error.html

# Create bucket policy for full public access
cat > bucket-policy.json <<EOL
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
        }
    ]
}
EOL

# Apply the bucket policy
aws s3api put-bucket-policy --bucket "$BUCKET_NAME" --policy file://bucket-policy.json


echo "S3 bucket '$BUCKET_NAME' created successfully with public access and static website hosting enabled."

# Upload files recursively to the S3 bucket
aws s3 cp "$FOLDER_PATH" "s3://$BUCKET_NAME/" --recursive

# Clean up
rm bucket-policy.json

echo "S3 bucket '$BUCKET_NAME' created successfully with public access and static website hosting enabled."
echo "Files from '$FOLDER_PATH' have been uploaded to 's3://$BUCKET_NAME/'"

# This script creates an S3 bucket, configures it for static website hosting with public access,
# uploads files from a specified folder, and cleans up the temporary bucket policy file.
