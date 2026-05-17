# OpenTofu / Terraform equivalent of forjar.yaml (cookbook recipe 38)
#
# State encryption — protect secrets at rest in the state file.
#
# Forjar:    BLAKE3 content-addressed signing. Tampering with a state
#            file changes the hash; the next apply refuses to proceed.
#            Protects state INTEGRITY end-to-end, not just confidentiality.
# Terraform: (NOT available — proprietary HCP Terraform feature only)
# OpenTofu:  1.7+ introduces a top-level `terraform { encryption {} }`
#            block. AES-GCM with a key from env var / static / GCP-KMS.
#            Protects state CONFIDENTIALITY at rest in the backend.
#
# Run (OpenTofu 1.7+ only):
#   export TF_VAR_state_passphrase=$(openssl rand -base64 32)
#   tofu init && tofu plan && tofu apply

terraform {
  required_version = ">= 1.7.0" # OpenTofu 1.7+ for the encryption block

  # OpenTofu 1.7+ state encryption block. The top-level `encryption {}`
  # block declares the key provider and the encryption method, then
  # opts the `state` and `plan` artifacts into encryption.
  encryption {
    key_provider "pbkdf2" "passphrase_key" {
      # Reads passphrase from $TF_VAR_state_passphrase at runtime.
      # In production: swap pbkdf2 -> aws_kms / gcp_kms / openbao.
      passphrase = var.state_passphrase
    }

    method "aes_gcm" "default" {
      keys = key_provider.pbkdf2.passphrase_key
    }

    state {
      method   = method.aes_gcm.default
      enforced = true
    }

    plan {
      method   = method.aes_gcm.default
      enforced = true
    }
  }

  required_providers {
    local = { source = "hashicorp/local", version = "~> 2.5" }
  }
}

variable "state_passphrase" {
  type        = string
  sensitive   = true
  description = "Passphrase for state-file AES-GCM encryption (≥32 chars)"
  # No default — must be supplied via TF_VAR_state_passphrase or -var.
}

# Sample resource whose attributes will be written to the (encrypted)
# state file. Forjar parity: `sensitive-config` resource that lands in
# the BLAKE3-signed lock file.
resource "local_file" "sensitive_config" {
  filename        = "/tmp/forjar-demo/var/lib/forjar/state/app-config.txt"
  file_permission = "0600"
  content         = <<-EOT
    # Managed by Terraform — state encryption demo
    # The state file recording this resource is AES-GCM encrypted on disk.
    resource_id: db-credentials
    note: state-file contents at rest are unreadable without the key
  EOT
}

output "encryption_algorithm" {
  value       = "aes-gcm (AES-256-GCM via OpenTofu pbkdf2 key provider)"
  description = "State encryption algorithm (forjar parity: BLAKE3 content-addressed signing)"
}
