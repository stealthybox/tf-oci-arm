data "oci_identity_availability_domains" "ads" {
  compartment_id = var.oci_compartment_id
}

data "oci_core_images" "ampere-ubuntu-images" {
  compartment_id           = var.oci_compartment_id
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_instance" "oracle-arm" {
  display_name   = "oracle-arm"
  compartment_id = var.oci_compartment_id

  shape = data.oci_core_images.ampere-ubuntu-images.shape
  shape_config {
    memory_in_gbs = "24"
    ocpus         = "4"
  }
  source_details {
    boot_volume_size_in_gbs = "200"
    source_id   = data.oci_core_images.ampere-ubuntu-images.images[0].id
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
    assign_public_ip          = "true" # this instance has a Public IP
    hostname_label            = "oracle-arm"
    subnet_id                 = oci_core_subnet.subnet_0.id
  }

  availability_config {
    recovery_action = "RESTORE_INSTANCE"
  }
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name

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
