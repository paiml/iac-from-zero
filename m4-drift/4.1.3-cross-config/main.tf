# OpenTofu / Terraform equivalent of forjar.yaml (cookbook recipe 39)
#
# Cross-config sharing — read outputs from another stack's state.
#
# Forjar:    explicit recipe imports by ID + BLAKE3 hash. If the upstream
#            recipe's hash changes since the lock was written, apply
#            refuses — drift is surfaced at the CONSUMER side.
# Terraform: `terraform_remote_state` data source reads another state
#            file's outputs at plan time. Implicit dependency — there's
#            no version pin; whatever's in the upstream state file at
#            read time is what you get. Drift in the upstream state
#            silently propagates downstream.
#
# Run: terraform init && terraform plan && terraform apply

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    local = { source = "hashicorp/local", version = "~> 2.5" }
  }
}

# Upstream state — would normally be the `network-stack` config's state
# file in S3 / Consul / local backend. For this demo we use a local
# backend pointing at a directory the operator pre-populates.
data "terraform_remote_state" "network" {
  backend = "local"
  config = {
    # In production: backend = "s3", config = { bucket=..., key=..., region=... }
    path = "${path.module}/state/network-stack.tfstate"
  }
  # Defaults are used if the state file is unreadable — forjar's
  # equivalent is `default:` in the data block.
  defaults = {
    subnet_cidr = "10.0.1.0/24"
    gateway_ip  = "10.0.1.1"
  }
}

# Equivalent of forjar's `app-network-config` resource — consumes
# upstream outputs. The interpolation is what couples the two stacks.
resource "local_file" "app_network_config" {
  filename        = "/tmp/forjar-demo/etc/app/network.conf"
  file_permission = "0644"
  content         = <<-EOT
    # Managed by Terraform — cross-config outputs
    # Values imported from network-stack via terraform_remote_state.
    SUBNET=${data.terraform_remote_state.network.outputs.subnet_cidr}
    GATEWAY=${data.terraform_remote_state.network.outputs.gateway_ip}
  EOT
}

# Equivalent of forjar's `db-network-config` resource — also consumes
# the upstream outputs.
resource "local_file" "db_network_config" {
  filename        = "/tmp/forjar-demo/etc/db/network.conf"
  file_permission = "0644"
  content         = <<-EOT
    # Managed by Terraform — cross-config outputs
    listen_addresses='${data.terraform_remote_state.network.outputs.subnet_cidr}'
    gateway=${data.terraform_remote_state.network.outputs.gateway_ip}
  EOT
}

output "subnet_cidr" {
  value       = data.terraform_remote_state.network.outputs.subnet_cidr
  description = "Subnet CIDR imported from network-stack"
}

output "gateway_ip" {
  value       = data.terraform_remote_state.network.outputs.gateway_ip
  description = "Gateway IP imported from network-stack"
}
