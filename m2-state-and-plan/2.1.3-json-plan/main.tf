# OpenTofu / Terraform equivalent of forjar.yaml (cookbook recipe 31)
#
# JSON plan output for CI/CD policy gating.
#
# Forjar:    `forjar plan --format json` emits a structured plan with the
#            same shape (resource_changes[] with before/after).
# Terraform: requires a TWO-STEP conversion — first emit the binary
#            tfplan, then `terraform show -json` to convert it.
#
# Run:
#   terraform plan -out=plan.tfplan
#   terraform show -json plan.tfplan > plan.json
#
# Sample CI policy gates (jq queries against plan.json):
#   # Count resources scheduled for create:
#   jq '[.resource_changes[] | select(.change.actions[] == "create")] | length' plan.json
#
#   # Fail the pipeline if anything is being destroyed:
#   jq -e '[.resource_changes[] | select(.change.actions[] == "delete")] | length == 0' plan.json
#
#   # OPA / conftest input shape matches forjar's --format json directly,
#   # so the same Rego policy works against both tools.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    local = { source = "hashicorp/local", version = "~> 2.5" }
    null  = { source = "hashicorp/null",  version = "~> 3.2" }
  }
}

variable "policy_engine" {
  type    = string
  default = "opa"
}

# Two resources so the JSON plan has a non-trivial resource_changes array.
resource "null_resource" "web_packages" {
  triggers = { policy_engine = var.policy_engine }
}

resource "local_file" "web_config" {
  filename        = "/tmp/forjar-demo/etc/web/config.json"
  file_permission = "0644"
  content         = jsonencode({
    server  = "web-stack"
    port    = 8080
    workers = 4
  })
  depends_on = [null_resource.web_packages]
}

# Embedded OPA / Rego policy — runs against the JSON plan emitted by
# `terraform show -json`. forjar's CI policy gate uses the SAME shape,
# so this Rego applies unchanged to `forjar plan --format json`.
resource "local_file" "opa_policy" {
  filename        = "/tmp/forjar-demo/etc/forjar/policies/plan-check.rego"
  file_permission = "0644"
  content         = <<-EOT
    # Policy engine: ${var.policy_engine}
    package terraform.plan
    default allow = true
    deny[msg] {
      change := input.resource_changes[_]
      change.change.actions[_] == "delete"
      msg := sprintf("cannot destroy %s in production", [change.address])
    }
  EOT
}

output "json_plan_command" {
  value       = "terraform show -json plan.tfplan | jq '.resource_changes | length'"
  description = "Count plan resources for CI gating (forjar parity: forjar plan --format json | jq)"
}
