# Shell Scripts for GCP Resource Management

This directory contains individual shell scripts for creating and managing single resources in Google Cloud Platform (GCP) using the `gcloud` command-line interface (CLI).

## Directory Structure

The scripts are organized by resource type:

- **aim**: Scripts for Identity and Access Management (IAM)
- **google-kubernetes**: Scripts for Google Kubernetes Engine (GKE)
- **load_balancer**: Scripts for creating and managing load balancers
- **net**: Scripts for networking resources (VPC, firewall rules, etc.)
- **sql**: Scripts for Cloud SQL instances
- **storage**: Scripts for Cloud Storage buckets
- **vm**: Scripts for Compute Engine virtual machines

## Usage

Most scripts can be executed directly after setting the necessary environment variables. For example:

```bash
# Set required environment variables
export SERVICE_ACCOUNT_NAME="your-service-account@your-project.iam.gserviceaccount.com"
export KEY="ssh-rsa AAAA..."

# Run a script
cd vm
./create_vm.sh
```

## Common Environment Variables

Many scripts require the following environment variables:

- `SERVICE_ACCOUNT_NAME`: The email address of the service account to use
- `KEY`: Your SSH public key for VM access
- `USER`: Your username for SSH access

## Script Descriptions

### VM Scripts

- `create_vm.sh`: Creates a basic VM with Nginx installed
- `take_vm_snapshot.sh`: Creates a snapshot of a VM's disk
- `vm_from_snapshot.sh`: Creates a VM from a disk snapshot
- `vm_from_image.sh`: Creates a VM from a custom image
- `vm_from_machine_image.sh`: Creates a VM from a machine image
- `vm_with_vpc.sh`: Creates a VM in a custom VPC
- `connection_to_private_cluster.sh`: Sets up a connection to a private GKE cluster

### Networking Scripts

- `create_custom_vpc.sh`: Creates a custom Virtual Private Cloud
- `create_fw_rule.sh`: Creates a firewall rule in the default VPC
- `create_fw_rule_custom_vpc.sh`: Creates a firewall rule in a custom VPC
- `create_peering.sh`: Sets up VPC peering between two networks
- `privte_service_acces.sh`: Configures private service access

### IAM Scripts

- `create_service_account.sh`: Creates a service account
- `create_alchemy_sa.sh`: Creates a service account for a specific application
- `create_role.sh`: Creates a custom IAM role
- `add_ssh.sh`: Adds SSH keys to project metadata
- `roles-check.sh`: Checks roles assigned to a service account

### And more...

Each script is self-contained and focused on a specific task, making them ideal for learning or for use in larger automation workflows.

## Notes

- These scripts are designed for demonstration and learning purposes
- Always review scripts before running them in a production environment
- Some scripts may need modification to work with your specific GCP project configuration