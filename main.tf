provider "oci" {}

variable github_user {
  type = string
}

variable oci_compartment_id {
  type = string
}

variable "tailscale_auth_key" {
  type      = string
  sensitive = true
}
