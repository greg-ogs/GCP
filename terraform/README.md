# Terraform Infrastructure for GCP

This directory contains Terraform configurations for deploying a complete infrastructure on Google Cloud Platform (GCP). Unlike the individual scripts or task-based approaches, Terraform provides a declarative way to define and manage your entire infrastructure as code.

## Directory Structure

The Terraform configurations are organized into modules:

- **base**: Core infrastructure components including networking, IAM, and security
- **compute**: Compute resources including instance templates, instance groups, and load balancing

## Features

This Terraform configuration creates a complete infrastructure including:

- Custom VPC network with subnets in multiple regions
- Firewall rules for secure access
- Instance templates for different regions
- Managed instance groups with auto-healing
- Service accounts with appropriate permissions
- (Commented out) Global HTTP load balancer configuration

## Prerequisites

Before using these Terraform configurations, ensure you have:

1. Terraform installed (version 0.12+)
2. Google Cloud SDK installed and configured
3. A GCP project with billing enabled
4. Appropriate permissions to create resources

## Usage

### Initialize Terraform

First, initialize Terraform in the base directory:

```bash
cd terraform/base
terraform init
```

### Deploy Base Infrastructure

```bash
terraform plan -out=base.plan
terraform apply base.plan
```

### Deploy Compute Resources

After the base infrastructure is deployed, you can deploy the compute resources:

```bash
cd ../compute
terraform init
terraform plan -out=compute.plan
terraform apply compute.plan
```

### Destroy Resources

To clean up resources when you're done:

```bash
# First destroy compute resources
cd terraform/compute
terraform destroy

# Then destroy base infrastructure
cd ../base
terraform destroy
```

## State Management

These configurations use local state files by default. For production use, it's recommended to configure remote state storage using Google Cloud Storage or another backend.

## Variables

Key variables that you may want to customize:

- `project_id`: Your GCP project ID
- `region`: Default region for resources
- `zones`: Zones within the region for resources
- `network_name`: Name of the VPC network
- `subnet_cidr`: CIDR ranges for subnets

## Notes

- The Terraform configurations are designed for demonstration purposes
- Some advanced features like the HTTP load balancer are commented out but can be enabled
- Always review the plan output before applying changes
- Resources created by Terraform will incur costs in your GCP account