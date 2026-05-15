# OpenTofu / Terraform equivalent of forjar.yaml (cookbook recipe 34)
#
# Moved blocks — rename a resource without destroy + recreate.
#
# Forjar:    resource IDs are the BLAKE3 hash of the resource's
#            declaration body. A rename that doesn't change the body
#            is a no-op — the hash is stable across the rename.
# Terraform: by default, renaming `null_resource.webserver_pkg` to
#            `null_resource.nginx_web` is treated as "destroy A, create B".
#            The `moved { from = ... to = ... }` block tells Terraform
#            it's a rename, and the state is migrated in place. Moved
#            blocks are one-time migrations; remove them after apply.
#
# Run: terraform init && terraform plan && terraform apply

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    null  = { source = "hashicorp/null",  version = "~> 3.2" }
    local = { source = "hashicorp/local", version = "~> 2.5" }
  }
}

# RENAMED from null_resource.webserver_pkg -> null_resource.nginx_web.
# Without the moved block below, this rename would destroy + recreate.
resource "null_resource" "nginx_web" {
  triggers = { role = "web" }
}

# RENAMED from local_file.db_pkg -> local_file.postgres_primary.
resource "local_file" "postgres_primary" {
  filename        = "/tmp/forjar-demo/etc/db/postgres.conf"
  file_permission = "0644"
  content         = <<-EOT
    # Managed by Terraform — moved blocks demo
    # Was: db-pkg → Now: postgres-primary
    data_directory=/var/lib/postgresql/15/main
  EOT
  depends_on = [null_resource.nginx_web]
}

# Moved blocks — declarative rename instruction. State migrates in place;
# no destroy + create cycle. Forjar parity: hash-stable recipe IDs make
# this automatic — no `moved` directive needed.
moved {
  from = null_resource.webserver_pkg
  to   = null_resource.nginx_web
}

moved {
  from = local_file.db_pkg
  to   = local_file.postgres_primary
}

output "moved_count" {
  value       = "2"
  description = "Number of moved resource entries"
}

output "refactor_safe" {
  value       = "true"
  description = "Declarative rename avoids destroy/create (forjar parity: hash-stable IDs)"
}
