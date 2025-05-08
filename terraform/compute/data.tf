# Remote state configuration to access outputs from the base state

# Data resource for base remote state with local backend
data "terraform_remote_state" "base" {
  backend = "local"

  config = {
    path = "/terraform/dockerswap/terraform.tfstate"
  }
}

# Example of how to access outputs from the base state:
# ${data.terraform_remote_state.base.outputs.vpc_id}
# ${data.terraform_remote_state.base.outputs.vpc_name}
# ${data.terraform_remote_state.base.outputs.subnetwork_central_name}
# ${data.terraform_remote_state.base.outputs.subnetwork_east_name}
# ${data.terraform_remote_state.base.outputs.subnetworks_ids}
# ${data.terraform_remote_state.base.outputs.bucket_name}
# ${data.terraform_remote_state.base.outputs.bucket_id}
# ${data.terraform_remote_state.base.outputs.project_metadata_id}
# ${data.terraform_remote_state.base.outputs.service_account_email}