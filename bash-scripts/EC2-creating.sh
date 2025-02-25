#!/bin/bash

# Define variables
REGION="us-east-1"                              # Give yur region
INSTANCE_TYPE="t2.micro"                        # Give instance type
SECURITY_GROUP="sg-0a49e97c7dfa3d678"           # Security group ARN
KEY_NAME="alkari-testing"                       # Pem key name (must be already generated)
STORAGE_SIZE=30                                 # Storage in GB
AMI_ID="ami-04b4f1a9cf54c11d0"                  # Image ami ID
INSTANCE_NAME="alkari3"                         # Your instnace Name

# Dont change this
USER_DATA=$(cat <<EOF
#!/bin/bash
# Update system
apt update -y && apt upgrade -y

# Install Docker
apt install -y docker.io
systemctl start docker
systemctl enable docker

# Install Nginx Proxy
apt install -y nginx
systemctl start nginx
systemctl enable nginx
EOF
)


INSTANCE_ID=$(aws ec2 run-instances \
    --region "$REGION" \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --security-group-ids "$SECURITY_GROUP" \
    --block-device-mappings '[
        {"DeviceName": "/dev/xvda", "Ebs": {"VolumeSize": '"$STORAGE_SIZE"', "VolumeType": "gp3"}}
    ]' \
    --user-data "$USER_DATA" \
    --query 'Instances[0].InstanceId' \
    --output text)


aws ec2 create-tags --resources "$INSTANCE_ID" --tags Key=Name,Value="$INSTANCE_NAME"


echo "Instance created with ID: $INSTANCE_ID and Name: $INSTANCE_NAME"

# This script creates an AWS EC2 instance with specified settings,
# installs Docker and Nginx on boot, tags the instance with a name,
# and outputs the instance ID.
