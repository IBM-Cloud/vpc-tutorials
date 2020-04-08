provider "ibm" {
  ibmcloud_api_key      = "${var.ibmcloud_api_key}"
  iaas_classic_username = "${var.iaas_classic_username}"
  iaas_classic_api_key  = "${var.iaas_classic_api_key}"
  region                = "${var.region}"
}

resource "ibm_compute_ssh_key" "key" {
  label      = "${var.prefix}-vm-to-migrate"
  public_key = "${file("${var.ssh_public_key_file}")}"
}

resource "ibm_compute_vm_instance" "vm" {
  hostname          = "${var.prefix}-classic-vm"
  domain            = "howto.cloud"
  ssh_key_ids       = ["${ibm_compute_ssh_key.key.id}"]
  os_reference_code = "CENTOS_7_64"
  datacenter        = "${var.classic_datacenter}"
  cores             = 1
  memory            = 1024

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "root"
      private_key = "${file("${var.ssh_private_key_file}")}"
      agent       = false
    }

    # install nginx on the server
    inline = [
      "touch this_file_was_created_in_classic",
      "yum install -y epel-release",
      "yum install -y nginx",
      "systemctl start nginx",
      "chkconfig nginx on",
    ]
  }
}

output "CLASSIC_ID" {
  value = "${ibm_compute_vm_instance.vm.id}"
}

output "CLASSIC_IP_ADDRESS" {
  value = "${ibm_compute_vm_instance.vm.ipv4_address}"
}
