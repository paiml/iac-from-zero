# OpenTofu / Terraform equivalent of forjar.yaml (cookbook recipe 37)
#
# Testing DSL — declarative assertions on plan and apply outcomes.
#
# Forjar:    `forjar plan-test` runs the DAG resolution and asserts on
#            the YAML diff without touching real hosts — the unit-test
#            layer of IAC. Plus the 10 C-claims as continuous property
#            tests on the engine.
# Terraform: `.tftest.hcl` files declare `run "..." { command = ...
#            assert { condition = ... } }` blocks. `terraform test`
#            discovers and runs them. Sibling file: tests/basic.tftest.hcl
#
# Run:
#   terraform init
#   terraform test                  # discovers tests/*.tftest.hcl
#   terraform test -filter=tests/basic.tftest.hcl

terraform {
  required_version = ">= 1.6.0"   # `terraform test` requires 1.6+
  required_providers {
    local = { source = "hashicorp/local", version = "~> 2.5" }
  }
}

variable "app_name" {
  type    = string
  default = "test-app"
}

variable "app_port" {
  type    = number
  default = 8080
}

# The "module under test" — a minimal resource the .tftest.hcl file
# asserts against. Forjar parity: the recipe under test is the same
# YAML config the production apply runs against.
resource "local_file" "test_config" {
  filename        = "/tmp/forjar-demo/etc/test-app/config.yaml"
  file_permission = "0644"
  content         = <<-EOT
    # Managed by Terraform — testing DSL demo
    server_name: ${var.app_name}.local
    port: ${var.app_port}
    workers: 2
  EOT
}

output "config_path" {
  value       = local_file.test_config.filename
  description = "Path to the generated config (asserted by tests/basic.tftest.hcl)"
}

output "configured_port" {
  value       = var.app_port
  description = "Port the test assertion checks against"
}
