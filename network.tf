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
    network_entity_id = oci_core_internet_gateway.main_gateway.id
  }
  manage_default_resource_id = oci_core_vcn.main_vcn.default_route_table_id
}

resource "oci_core_default_security_list" "main_security_list" {
  ingress_security_rules {
    description = "allow tailscale easy-NAT"
    source      = "0.0.0.0/0"
    protocol    = "17" // UDP
    udp_options {
      min = 41641
      max = 41641
    }
  }
  ingress_security_rules {
    description = "allow ICMP type 3, code 4 from everywhere"
    source      = "0.0.0.0/0"
    protocol    = "1" // ICMP
    icmp_options {
      type = 3
      code = 4
    }
  }
  ingress_security_rules {
    description = "allow ICMP type 3 from 10.0.0.0/16"
    source      = "10.0.0.0/16"
    protocol    = "1" // ICMP
    icmp_options {
      type = 3
    }
  }
  egress_security_rules {
    description = "allow all egress"
    destination = "0.0.0.0/0"
    protocol    = "all"
  }
  manage_default_resource_id = oci_core_vcn.main_vcn.default_security_list_id
}

# NAT Gateways are normally free, but not available with Free Accounts:  https://cloud.oracle.com/limits

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