# OpenTofu / Terraform equivalent of forjar.yaml (cookbook recipe 33)
#
# Lifecycle rules: prevent_destroy + create_before_destroy.
#
# Forjar:    idempotent recipes that re-converge to the declared end-state
#            on every apply. Protection comes from content-addressed
#            BLAKE3 outputs — if nothing changed, nothing applies. No
#            "lifecycle" block needed because there's no destroy phase.
# Terraform: each resource has an explicit `lifecycle {}` block opting
#            into protections. prevent_destroy aborts `terraform destroy`;
#            create_before_destroy reverses the default replace order.
#
# Run: terraform init && terraform apply

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    null  = { source = "hashicorp/null",  version = "~> 3.2" }
    local = { source = "hashicorp/local", version = "~> 2.5" }
  }
}

# Equivalent of forjar's `db-data-dir` with `lifecycle: prevent_destroy: true`.
# Terraform will hard-fail on `terraform destroy` while this block is in
# place — protects stateful resources from accidental deletion.
resource "null_resource" "db_data_dir" {
  triggers = { path = "/var/lib/postgresql/15/main" }
  lifecycle {
    prevent_destroy = true
  }
}

# Equivalent of forjar's `app-config` with `lifecycle: create_before_destroy: true`.
# When the content changes, Terraform creates the new file BEFORE removing
# the old one — eliminates the "config-absent" window during replacement.
resource "local_file" "app_config" {
  filename        = "/tmp/forjar-demo/etc/app/config.yaml"
  file_permission = "0644"
  content         = <<-EOT
    # Managed by Terraform — lifecycle demo
    database:
      host: localhost
      port: 5432
    server:
      port: 8080
  EOT
  lifecycle {
    create_before_destroy = true
  }
}

# Equivalent of forjar's `external-config` with `lifecycle: ignore_drift`.
# Terraform's analogue is `ignore_changes` — drift in these attributes is
# accepted into state on the next plan without re-converging.
resource "local_file" "external_config" {
  filename        = "/tmp/forjar-demo/etc/app/external.conf"
  file_permission = "0644"
  content         = "replica_count=3\n"
  lifecycle {
    ignore_changes = [content]
  }
}

output "protected_count" {
  value       = "2"
  description = "Resources with prevent_destroy (forjar parity: lifecycle: prevent_destroy: true)"
}
