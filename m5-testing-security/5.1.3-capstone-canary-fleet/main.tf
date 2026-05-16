# OpenTofu / Terraform equivalent of forjar.yaml (cookbook recipe 94)
#
# CAPSTONE — canary deployment fleet.
#
# Forjar:    one recipe (94-canary-deployment) with all 10 falsifiable
#            claims asserted live against the running fleet. Health gate,
#            traffic switch, rollback — all declarative resources.
# Terraform: hand-rolled with null_resource + local-exec for each phase.
#            No first-class "canary" or "health gate" primitive — every
#            piece is glued together with shell scripts triggered by
#            resource lifecycle and depends_on. The create_before_destroy
#            lifecycle on the canary slot is what enforces "update canary
#            first" — replacing it boots the new green BEFORE the old
#            blue tears down.
#
# Run: terraform init && terraform apply
#      ./traffic-switch.sh green   # promote canary after health gate
#      ./rollback.sh               # roll back on failure

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    null  = { source = "hashicorp/null",  version = "~> 3.2" }
    local = { source = "hashicorp/local", version = "~> 2.5" }
  }
}

variable "app_name" {
  type    = string
  default = "myapp"
}

variable "blue_port" {
  type    = number
  default = 8001
}

variable "green_port" {
  type    = number
  default = 8002
}

variable "deploy_dir" {
  type    = string
  default = "/tmp/forjar-demo/opt/deploy"
}

variable "health_threshold" {
  type    = number
  default = 3
}

# ── Primary (blue) slot ──
# Stable production slot. No lifecycle protections beyond default —
# replaced only after the canary proves healthy.
resource "null_resource" "primary_blue" {
  triggers = {
    app_name = var.app_name
    port     = var.blue_port
    slot     = "blue"
  }
  provisioner "local-exec" {
    command = "echo 'PRIMARY (blue) slot converged on port ${var.blue_port}'"
  }
}

# ── Canary (green) slot ──
# create_before_destroy enforces "update canary FIRST" — the new green
# boots before the old green tears down. This is the lifecycle hook
# that makes the hand-rolled canary pattern work without downtime.
resource "null_resource" "canary_green" {
  triggers = {
    app_name = var.app_name
    port     = var.green_port
    slot     = "green"
  }
  lifecycle {
    create_before_destroy = true
  }
  provisioner "local-exec" {
    command = "echo 'CANARY (green) slot converged on port ${var.green_port}'"
  }
  depends_on = [null_resource.primary_blue]
}

# ── Health gate script ──
# Equivalent of forjar's `health-gate` resource — hand-rolled curl loop.
# In forjar this is a `health-gate` declarative resource with built-in
# retry + threshold.
resource "local_file" "health_gate" {
  filename        = "${var.deploy_dir}/health-gate.sh"
  file_permission = "0755"
  content         = <<-EOT
    #!/bin/bash
    set -euo pipefail
    SLOT="$${1:-green}"
    PORT=$( [ "$SLOT" = "blue" ] && echo "${var.blue_port}" || echo "${var.green_port}" )
    for i in $(seq 1 ${var.health_threshold}); do
      curl -sf --max-time 5 "http://127.0.0.1:$${PORT}/healthz" >/dev/null
      echo "Check $i/${var.health_threshold}: PASS"
      sleep 1
    done
    echo "Health gate PASSED — $SLOT healthy"
  EOT
  depends_on = [null_resource.canary_green]
}

# ── Traffic switch script ──
resource "local_file" "traffic_switch" {
  filename        = "${var.deploy_dir}/traffic-switch.sh"
  file_permission = "0755"
  content         = <<-EOT
    #!/bin/bash
    set -euo pipefail
    SLOT="$${1:-green}"
    echo "proxy_pass http://${var.app_name}_$${SLOT};" > /etc/nginx/conf.d/active-slot.conf
    echo "$SLOT" > "${var.deploy_dir}/active-slot"
    nginx -t && nginx -s reload
    echo "Traffic switched to $SLOT"
  EOT
  depends_on = [local_file.health_gate]
}

# Forjar parity: this output enumerates what the recipe-94 outputs block
# exposes. In forjar, the 10 C-claims would be asserted automatically
# against the live fleet on every apply.
output "fleet_summary" {
  value = {
    app_name      = var.app_name
    blue_endpoint = "http://127.0.0.1:${var.blue_port}"
    green_endpoint = "http://127.0.0.1:${var.green_port}"
    health_gate   = local_file.health_gate.filename
    traffic_switch = local_file.traffic_switch.filename
  }
  description = "Canary fleet endpoints + helper scripts (forjar parity: outputs + 10 C-claims)"
}
