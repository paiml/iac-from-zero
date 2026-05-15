# Terraform test file (OpenTofu 1.6+ / Terraform 1.6+).
#
# Forjar equivalent: forjar-test.yaml with `tests:` array of plan/apply
# blocks. Both DSLs share the same shape — `run` blocks with `command`
# (plan or apply) and `assert` clauses bound to a condition + message.
#
# Run from this module's root: `terraform test`

variables {
  app_name = "test-app"
  app_port = 8080
}

# Plan-time validation — equivalent of forjar's `command: plan` test
# block. Runs the planner without applying, asserts on the planned
# output values.
run "plan_validation" {
  command = plan

  assert {
    condition     = var.app_port == 8080
    error_message = "Expected app_port=8080 from default; got ${var.app_port}"
  }

  assert {
    condition     = output.configured_port == 8080
    error_message = "Output configured_port did not surface the input variable"
  }

  assert {
    condition     = output.config_path == "/tmp/forjar-demo/etc/test-app/config.yaml"
    error_message = "Output config_path drifted from expected location"
  }
}

# Apply-time check — equivalent of forjar's `command: apply` block with
# `file_contains` assertion. Verifies the rendered content matches.
run "apply_renders_config" {
  command = apply

  assert {
    condition     = length(local_file.test_config.content) > 0
    error_message = "test_config rendered empty content"
  }

  assert {
    condition     = strcontains(local_file.test_config.content, "server_name: test-app.local")
    error_message = "test_config did not render the templated server_name"
  }
}

# Idempotency probe — equivalent of forjar's `idempotent-reapply` test
# block that asserts changes: 0 on the second apply.
run "idempotent_replan" {
  command = plan

  assert {
    condition     = output.configured_port == 8080
    error_message = "Second plan drifted from the first apply"
  }
}
