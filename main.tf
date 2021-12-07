provider "oci" {}

variable "oci_compartment_id" {
  type = string
}

variable "tailscale_auth_key" {
  type      = string
  sensitive = true
}

variable "github_user" {
  type = string
}

resource "oci_core_instance" "oracle-arm" {
  display_name   = "oracle-arm"
  compartment_id = var.oci_compartment_id

  shape = "VM.Standard.A1.Flex"
  shape_config {
    memory_in_gbs = "24"
    ocpus         = "4"
  }
  source_details {
    boot_volume_size_in_gbs = "200"
    # Platform Image: Ubuntu 20.04
    source_id   = "ocid1.image.oc1.phx.aaaaaaaa3nsfzlvkvrfug4xby77srfr43iinfkw3clur5izvlnqtxqdyj5sq"
    source_type = "image"
  }

  metadata = {
    "user_data" = base64encode(
      templatefile(
        "userdata.tpl.yaml",
        {
          github_user        = var.github_user,
          tailscale_auth_key = var.tailscale_auth_key,
        }
      )
    )
  }

  create_vnic_details {
    assign_private_dns_record = "true"
    assign_public_ip          = "true" # this instance has a Public IP, locked it down /w ufw
    hostname_label            = "oracle-arm"
    subnet_id                 = oci_core_subnet.subnet_0.id
  }

  availability_config {
    recovery_action = "RESTORE_INSTANCE"
  }
  availability_domain = "WMEB:PHX-AD-3"

  instance_options {
    are_legacy_imds_endpoints_disabled = "false"
  }
  is_pv_encryption_in_transit_enabled = "true"

  agent_config {
    is_management_disabled = "false"
    is_monitoring_disabled = "false"
    plugins_config {
      desired_state = "DISABLED"
      name          = "Vulnerability Scanning"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Compute Instance Monitoring"
    }
  }
}

resource "oci_core_vcn" "main_vcn" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = var.oci_compartment_id
  display_name   = "vcn-main"
  dns_label      = "main"
}

resource "oci_core_subnet" "subnet_0" {
  cidr_block     = "10.0.0.0/24"
  compartment_id = var.oci_compartment_id
  display_name   = "subnet-0"
  dns_label      = "sub0"
  route_table_id = oci_core_vcn.main_vcn.default_route_table_id
  vcn_id         = oci_core_vcn.main_vcn.id
}

resource "oci_core_internet_gateway" "main_gateway" {
  compartment_id = var.oci_compartment_id
  display_name   = "Internet Gateway vcn-main"
  vcn_id         = oci_core_vcn.main_vcn.id
}

resource "oci_core_default_route_table" "main_routes" {
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.main_gateway.id
  }
  manage_default_resource_id = oci_core_vcn.main_vcn.default_route_table_id
}

# NAT Gateways not available with Free Accounts:  https://cloud.oracle.com/limits

# resource "oci_core_public_ip" "main_nat_gateway" {
#   compartment_id = var.oci_compartment_id
#   display_name   = "NAT Gateway vcn-main reserved IP"
#   lifetime       = "RESERVED"
# }

# resource "oci_core_nat_gateway" "main_nat_gateway" {
#   compartment_id = var.oci_compartment_id
#   display_name   = "NAT Gateway vcn-main"
#   vcn_id         = oci_core_vcn.main_vcn.id
#   public_ip_id   = oci_core_public_ip.main_nat_gateway.id
# }
