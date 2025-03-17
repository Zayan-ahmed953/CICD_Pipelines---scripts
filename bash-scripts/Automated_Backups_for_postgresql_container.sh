# 1- Mount the hostdir where you want to store the archived backups to the /backups path within the container


# services:
#   postgres:
#     image: postgres:15
#     container_name: postgres_db
#     ports:
#       - "5432:5432"
#     environment:
#       POSTGRES_USER: postgres
#       POSTGRES_PASSWORD: password  # Set a password
#       POSTGRES_DB: yourdatabase  # Default database
#     volumes:
#       - /var/backups/postgresql:/backups  # Mount backup directory
#     restart: unless-stopped
    
    
    
    
# 2- Save the following script on your machine where the container is running and give the values as needed 


#!/bin/bash

# Set variables
TIMESTAMP=$(date +%d-%B-%Y)
BACKUP_BASE_DIR="/var/backups/postgresql"  # Backup directory on host
S3_BUCKET="s3://fip-fastapi-docker-env-postgres-backups"
DB_PASSWORD="oisadjoajsdaoja"

# Ensure backup directory exists
sudo mkdir -p "$BACKUP_BASE_DIR"

# Export PostgreSQL credentials
export PGPASSWORD="$DB_PASSWORD"

# Check PostgreSQL connection before proceeding
if ! psql -U postgres -h localhost -d postgres -c "SELECT 1" &>/dev/null; then
    echo "Error: Unable to connect to PostgreSQL. Check if the database is running."
    exit 1
fi

# Loop through each database
for db in $(psql -U postgres -h localhost -d postgres -t -c "SELECT datname FROM pg_database WHERE datistemplate = false;"); do
    db=$(echo "$db" | tr -d ' ')  # Remove leading/trailing spaces

    DB_BACKUP_DIR="$BACKUP_BASE_DIR/$db"
    mkdir -p "$DB_BACKUP_DIR"

    BACKUP_FILE="$DB_BACKUP_DIR/${db}_backup_$TIMESTAMP.sql.gz"
    
    echo "Backing up database: $db..."
    if docker exec -t postgres_db pg_dump -U postgres -d "$db" | gzip > "$BACKUP_FILE"; then
        echo "Backup successful: $BACKUP_FILE"
    else
        echo "Error: Failed to backup database: $db"
        continue
    fi

    # Upload only if the backup file does not exist on S3
    S3_DB_PATH="$S3_BUCKET/$db"
    S3_BACKUP_FILE="$S3_DB_PATH/${db}_backup_$TIMESTAMP.sql.gz"
    
    # Check if the file already exists on S3
    if aws s3 ls "$S3_BACKUP_FILE" &>/dev/null; then
        echo "Backup already exists on S3. Skipping upload: $S3_BACKUP_FILE"
    else
        echo "Uploading $BACKUP_FILE to S3: $S3_DB_PATH"
        aws s3 cp "$BACKUP_FILE" "$S3_BACKUP_FILE"

        if [[ $? -eq 0 ]]; then
            echo "Upload successful: $S3_BACKUP_FILE"
        else
            echo "Error: Failed to upload $BACKUP_FILE to S3"
        fi
    fi

done

# Remove old backups (optional, keep only the last 7 days)
find "$BACKUP_BASE_DIR" -type f -mtime +7 -exec rm {} \;

echo "Full PostgreSQL backup completed and uploaded to S3."



# 3- Make the script executable and run on the host 

# Cronjob for 11pm IST daily backup 

# 30 17 * * * AWS_SHARED_CREDENTIALS_FILE=/home/ubuntu/.aws/credentials sudo -E bash /home/ubuntu/pg_full_backup.sh > /home/ubuntu/backup_cron_logs.log 2>&1
