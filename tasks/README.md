# GCP Tasks - Mini-Project Configurations

This directory contains complete mini-project configurations for Google Cloud Platform (GCP). Each task script creates and configures multiple related resources to demonstrate more complex GCP workflows and resource interactions.

## Purpose

Unlike the individual scripts in the `shell_scripts` directory, these task scripts are designed to:

1. Demonstrate how multiple GCP resources work together
2. Show complete workflows for common cloud architecture patterns
3. Provide end-to-end examples that can be used as templates for real-world projects

## Available Tasks

### Task 3
Creates a complete VM deployment workflow:
- Creates a VM with Nginx installed
- Creates a snapshot of the VM
- Creates a second VM from the snapshot
- Creates a machine image from the first VM
- Creates a third VM from the machine image

### Task 4
Sets up a custom VPC network with multiple VM instances:
- Creates a custom VPC with two subnets in different regions (us-central1, us-east1)
- Establishes network peering between custom VPC and default network
- Deploys three VMs across different networks and regions with Nginx
- Configures firewall rules to allow HTTP traffic

### Task 5
Demonstrates Cloud Storage bucket operations:
- Creates multiple storage buckets with different configurations
- Uploads and synchronizes content between buckets
- Configures different storage classes (Standard, Nearline, Coldline)
- Enables object versioning and manages access controls
- Generates signed URLs for secure, time-limited access

### Task 6
Sets up a private MySQL Cloud SQL instance:
- Creates a VM with Python environment for application deployment
- Establishes a custom VPC network with private Google access
- Implements Private Service Access for secure Cloud SQL connectivity
- Creates a MySQL database instance with no public IP
- Uses Secret Manager to store and retrieve database credentials

### Task 7
Implements a scalable web application with database backend:
- Creates managed instance groups (MIGs) for Nginx and application servers
- Sets up a private Cloud SQL MySQL instance with secure connectivity
- Deploys a Python Flask application with SQLAlchemy for database access
- Configures health checks and autoscaling for high availability
- Establishes proper networking and security with firewall rules

### Task 8
Empty template for future task implementation.

## Usage

To run a task, you'll need to set the required environment variables first:

```bash
# Set required environment variables
export SERVICE_ACCOUNT_NAME="your-service-account@your-project.iam.gserviceaccount.com"
export KEY="ssh-rsa AAAA..."

# Run a task
./task_3.sh
```

## Prerequisites

Before running these tasks, ensure you have:

1. A GCP project set up and configured
2. The `gcloud` CLI installed and authenticated
3. Appropriate permissions in your GCP project
4. Required environment variables set

## Notes

- These tasks are designed for demonstration and learning purposes
- Each task is independent and can be run separately
- Tasks may create resources that incur costs in your GCP account
- Remember to clean up resources after you're done to avoid unnecessary charges
- Some tasks may need modification to work with your specific GCP project configuration