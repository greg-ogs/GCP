#!/bin/bash
# Install nginx
apt-get update
apt-get install -y nginx

# Get instance metadata
INSTANCE_NAME=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/name" -H "Metadata-Flavor: Google")
INSTANCE_ZONE=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/zone" -H "Metadata-Flavor: Google" | cut -d/ -f4)
NGINX_DEFAULT_PAGE="/var/www/html/index.nginx-debian.html"
TEXT_TO_APPEND="<p>This is the instance: ${INSTANCE_NAME} and the instance zone is: ${INSTANCE_ZONE}</p>"
echo "$TEXT_TO_APPEND" >> "$NGINX_DEFAULT_PAGE"
systemctl restart nginx
