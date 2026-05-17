# OpenTofu / Terraform equivalent of forjar.yaml (cookbook recipe 01)
#
# Forjar:    one Rust binary (~17 crate deps), no plugin model, YAML
#            config you can paste into a tweet.
# Terraform: requires the `hashicorp/local` provider plugin (~200 Go
#            modules pulled in transitively); `terraform init` must run
#            before plan/apply to download the plugin.
#
# Run: terraform init && terraform plan && terraform apply

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    # forjar bundles file + package + user resource types into one binary.
    # Terraform splits them across provider plugins downloaded at init.
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# forjar params: -> Terraform variables. Same idea, different syntax.
variable "user" {
  type    = string
  default = "dev"
}

variable "home" {
  type    = string
  default = "/tmp/forjar-demo/home/dev"
}

variable "editor" {
  type    = string
  default = "vim"
}

# Equivalent of forjar's `home-dir` (state: directory) resource.
# Terraform has no first-class "directory" resource — we hand-roll it
# with null_resource + local-exec, exactly the kind of imperative
# shellout that forjar's package/user/file types abstract away.
resource "null_resource" "home_dir" {
  triggers = { home = var.home }
  provisioner "local-exec" {
    command = "mkdir -p ${var.home}"
  }
}

# Equivalent of forjar's `gitconfig` file resource — managed dotfile.
resource "local_file" "gitconfig" {
  filename        = "${var.home}/.gitconfig"
  file_permission = "0644"
  content         = <<-EOT
    # Managed by Terraform — equivalent of forjar gitconfig resource
    [core]
      editor = ${var.editor}
    [init]
      defaultBranch = main
    [pull]
      rebase = true
  EOT
  depends_on      = [null_resource.home_dir]
}

# Equivalent of forjar's `vimrc` file resource.
resource "local_file" "vimrc" {
  filename        = "${var.home}/.vimrc"
  file_permission = "0644"
  content         = <<-EOT
    " Managed by Terraform — equivalent of forjar vimrc resource
    set nocompatible
    set number
    set expandtab
    set tabstop=4
    syntax on
  EOT
  depends_on      = [null_resource.home_dir]
}

# Equivalent of forjar's outputs: block.
output "home_directory" {
  value       = var.home
  description = "Home directory path (forjar parity: outputs.home_directory)"
}

output "configured_user" {
  value       = var.user
  description = "Unix username (forjar parity: outputs.configured_user)"
}
