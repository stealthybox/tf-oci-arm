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
          github_user = var.github_user,
          tailscale_auth_key = var.tailscale_auth_key,
        }
      )
    )
  }

  create_vnic_details {
    assign_private_dns_record = "true"
    assign_public_ip          = "true" # this instance has a Public IP
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