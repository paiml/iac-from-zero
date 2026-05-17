# OpenTofu / Terraform equivalent of forjar.yaml (cookbook recipe 35)
#
# Drift detection — refresh-only mode.
#
# Forjar:    drift detection is a LOCAL BLAKE3 hash compare against the
#            lock file. Runs in milliseconds, no API calls, no rate
#            limits. Detects any change to a tracked file.
# Terraform: `terraform plan -refresh-only` polls every cloud provider's
#            API to read current state, then diffs against the local
#            state file. Slow, expensive, and only detects drift for
#            resources Terraform originally created.
#
# Run:
#   terraform apply                       # initial converge
#   echo "manual edit" >> /tmp/forjar-demo/var/lib/app/config.yaml
#   terraform plan -refresh-only          # show detected drift
#   terraform apply -refresh-only         # accept drift into state, no convergence

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    local = { source = "hashicorp/local", version = "~> 2.5" }
    null  = { source = "hashicorp/null", version = "~> 3.2" }
  }
}

variable "app_name" {
  type    = string
  default = "hotfix-app"
}

# Equivalent of forjar's `app-config` — a file that may be hotfixed
# manually in production. -refresh-only mode lets you accept the hotfix
# into state without re-converging to the declared content.
resource "local_file" "app_config" {
  filename        = "/tmp/forjar-demo/var/lib/app/config.yaml"
  file_permission = "0644"
  content         = <<-EOT
    # Managed by Terraform — refresh-only drift demo
    # This config may be hotfixed manually.
    # -refresh-only accepts the hotfix into state.
    app: ${var.app_name}
    version: 1.0
    debug: false
  EOT
}

# Equivalent of forjar's `drift-check-script` resource — a helper script
# the operator runs locally. forjar's `forjar plan` already prints a
# drift report; Terraform needs the separate -refresh-only invocation.
resource "local_file" "drift_check_script" {
  filename        = "/tmp/forjar-demo/usr/local/bin/check-drift.sh"
  file_permission = "0755"
  content         = <<-EOT
    #!/bin/bash
    set -euo pipefail
    echo "=== Drift Check ==="
    echo "Running terraform plan -refresh-only..."
    terraform plan -refresh-only
    echo "Note: -refresh-only mode never applies changes."
    echo "Forjar parity: 'forjar plan' uses BLAKE3 hash compare instead."
  EOT
  depends_on      = [local_file.app_config]
}

output "mode" {
  value       = "refresh-only"
  description = "Apply mode (forjar parity: forjar plan uses BLAKE3 hash compare)"
}

output "changes_applied" {
  value       = "0"
  description = "refresh-only applies zero changes — only state is updated"
}
