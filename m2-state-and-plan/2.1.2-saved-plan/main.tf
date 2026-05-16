# OpenTofu / Terraform equivalent of forjar.yaml (cookbook recipe 30)
#
# Saved-plan workflow — the "review then execute" split.
#
# Forjar:    `forjar plan --lock` writes a readable BLAKE3-hashed YAML
#            lock file that `git diff` can review before `forjar apply`.
# Terraform: `terraform plan -out=plan.tfplan` writes an OPAQUE BINARY
#            file. You cannot diff it in code review without running
#            `terraform show plan.tfplan` to re-render it as text.
#
# Run: terraform plan -out=plan.tfplan && terraform apply plan.tfplan
#
# Comparison checkpoint:
#   file plan.tfplan                   # -> "data" (binary)
#   cat  forjar.lock                   # -> human-readable YAML w/ BLAKE3

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    null  = { source = "hashicorp/null",  version = "~> 3.2" }
    local = { source = "hashicorp/local", version = "~> 2.5" }
  }
}

variable "app_name" {
  type    = string
  default = "web-stack"
}

# Stand-in for the planned infrastructure. In a real plan-file workflow
# you'd see this resource as a "create" action in the saved plan.
resource "null_resource" "app_data_dir" {
  triggers = { app_name = var.app_name }
  provisioner "local-exec" {
    command = "mkdir -p /tmp/forjar-demo/var/lib/${var.app_name}"
  }
}

resource "local_file" "app_config" {
  filename        = "/tmp/forjar-demo/etc/app/config.yaml"
  file_permission = "0644"
  content         = <<-EOT
    # Managed by Terraform — saved-plan demo
    app: ${var.app_name}
    version: 1.0
    port: 8080
  EOT
  depends_on = [null_resource.app_data_dir]
}

# Forjar parity: outputs are flat key/value/description tuples.
output "app_name" {
  value       = var.app_name
  description = "Stack name carried through the saved plan"
}

output "plan_workflow" {
  # The forjar equivalent in one line: `forjar plan --lock && git diff && forjar apply`
  value       = "terraform plan -out=plan.tfplan && terraform apply plan.tfplan"
  description = "Two-step saved-plan workflow for CI/CD review gates"
}
