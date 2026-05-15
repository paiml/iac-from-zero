# OpenTofu / Terraform equivalent of forjar.yaml (cookbook recipe 36)
#
# Resource targeting — apply a slice of the graph, not the whole plan.
#
# Forjar:    `forjar apply --recipe web-server` runs that recipe's FULL
#            DAG. There is no concept of "apply just this node" — recipes
#            are the atomic apply unit, and the full DAG must pass.
# Terraform: `terraform apply -target=null_resource.web` applies only
#            that resource AND its transitive dependencies (upstream).
#            Downstream dependents and unrelated resources are skipped.
#            The trap: -target lets you ship configs that would never
#            pass a full plan, silently accumulating drift.
#
# Run: terraform init && terraform apply
#
# Targeted variants (surgical fixes):
#   terraform apply -target=null_resource.web      # web + its upstream
#   terraform apply -target=local_file.app_config  # app_config + upstream
#   terraform apply                                # full plan (safe path)

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    null  = { source = "hashicorp/null",  version = "~> 3.2" }
    local = { source = "hashicorp/local", version = "~> 2.5" }
  }
}

# Layer 0 — leaf dependency. -target on anything downstream pulls this in.
resource "null_resource" "base_packages" {
  triggers = { role = "base" }
}

# Layer 1 — depends on base_packages. The example -target call below
# applies base_packages + app_dir + app_config and SKIPS app_service
# and monitoring_config.
resource "null_resource" "app_dir" {
  triggers   = { path = "/var/lib/app" }
  depends_on = [null_resource.base_packages]
}

# Layer 2 — the named target. -target=local_file.app_config pulls in
# base_packages + app_dir transitively.
resource "local_file" "app_config" {
  filename        = "/tmp/forjar-demo/var/lib/app/config.yaml"
  file_permission = "0644"
  content         = "app: targeting-test\nport: 8080\n"
  depends_on      = [null_resource.app_dir]
}

# Layer 3 — DOWNSTREAM dependent. -target=local_file.app_config does
# NOT pull this in (targeting is upstream-only).
resource "null_resource" "web" {
  triggers   = { config = local_file.app_config.content }
  depends_on = [local_file.app_config]
}

# Independent resource — NOT in app_config's dependency chain. Skipped
# by every -target above unless explicitly named.
resource "local_file" "monitoring_config" {
  filename        = "/tmp/forjar-demo/etc/monitoring/config.yaml"
  file_permission = "0644"
  content         = "collector: prometheus\nscrape_interval: 30s\n"
}

output "targeted_apply_example" {
  value       = "terraform apply -target=null_resource.web"
  description = "Apply only web + its upstream deps (forjar parity: forjar apply --recipe web-server, runs full recipe DAG)"
}
