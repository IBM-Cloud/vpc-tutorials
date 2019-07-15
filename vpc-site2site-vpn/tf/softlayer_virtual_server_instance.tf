data "ibm_compute_ssh_key" "ssh_key" {
    count = "${length(var.softlayer_ssh_keys)}"
    label =  "${var.softlayer_ssh_keys[count.index]}"
}

# Create a virtual server with the SSH key
resource "ibm_compute_vm_instance" "onprem_vsi" {
  hostname          = "${var.resources_prefix}-onprem-vsi"
  domain            = "solution-tutorial.cloud.ibm"
  ssh_key_ids       = ["${data.ibm_compute_ssh_key.ssh_key.*.id}"]
  os_reference_code = "${var.softlayer_image_name}"
  datacenter        = "${var.softlayer_datacenter}"
  network_speed     = 100
  cores             = 1
  memory            = 1024
}