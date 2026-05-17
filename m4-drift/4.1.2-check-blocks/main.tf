# OpenTofu / Terraform equivalent of forjar.yaml (cookbook recipe 32)
#
# Check blocks — post-apply policy / health assertions (OpenTofu 1.5+).
#
# Forjar:    10 falsifiable claims (C1-C10) are asserted on every apply —
#            deterministic hashing, idempotency, DAG ordering, cycle
#            detection, etc. They run against the engine's internal
#            invariants, closer to a property test than a health check.
# Terraform: `check { assert { condition = ... } }` blocks run AFTER
#            apply and read post-apply resource state. Failures emit
#            warnings — they don't roll back. Closer to a health probe
#            than a contract check.
#
# Run: terraform init && terraform apply

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    local = { source = "hashicorp/local", version = "~> 2.5" }
    null  = { source = "hashicorp/null", version = "~> 3.2" }
  }
}

variable "app_port" {
  type    = number
  default = 8080
}

# Equivalent of forjar's `health-endpoint` resource — a managed file
# that the check block asserts against post-apply.
resource "local_file" "health_endpoint" {
  filename        = "/tmp/forjar-demo/var/www/html/health"
  file_permission = "0644"
  content         = jsonencode({ status = "ok", version = "1.0" })
}

resource "local_file" "app_config" {
  filename        = "/tmp/forjar-demo/etc/app/checks.yaml"
  file_permission = "0644"
  content         = <<-EOT
    # Managed by Terraform — check blocks demo
    port: ${var.app_port}
    checks_mode: warn
  EOT
}

# Check block — post-apply assertion. Equivalent of forjar's `checks:`
# section that runs after all resources converge.
check "health_file_exists" {
  assert {
    condition     = fileexists(local_file.health_endpoint.filename)
    error_message = "Health endpoint file was not created after apply"
  }
}

# Multiple asserts per check — verify content shape and config presence.
check "health_payload_well_formed" {
  assert {
    condition     = can(jsondecode(local_file.health_endpoint.content))
    error_message = "Health endpoint content is not valid JSON"
  }
  assert {
    condition     = jsondecode(local_file.health_endpoint.content)["status"] == "ok"
    error_message = "Health endpoint did not report status=ok"
  }
}

# Forjar parity: this is the analogue of one of the 10 named C-claims —
# but Terraform check blocks read post-apply file content, while forjar
# C-claims read the engine's internal invariants.
check "config_well_formed" {
  assert {
    condition     = fileexists(local_file.app_config.filename)
    error_message = "App config file missing after apply"
  }
}

output "check_count" {
  value       = "3"
  description = "Number of post-apply check blocks (forjar parity: 10 C-claims)"
}
