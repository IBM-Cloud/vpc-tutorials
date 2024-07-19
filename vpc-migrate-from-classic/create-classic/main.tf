provider "ibm" {
  ibmcloud_api_key      = var.ibmcloud_api_key
  iaas_classic_username = var.iaas_classic_username
  iaas_classic_api_key  = var.iaas_classic_api_key
  region                = var.region
}

# Generate an SSH key/pair to be used to provision the classic VSI
resource tls_private_key ssh {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "local_file" "ssh-private-key" {
  content = tls_private_key.ssh.private_key_pem
  filename = "generated_key_rsa"
  file_permission = "0600"
}

resource "local_file" "ssh-public-key" {
  content = tls_private_key.ssh.public_key_openssh
  filename = "generated_key_rsa.pub"
  file_permission = "0600"
}

resource "ibm_compute_ssh_key" "key" {
  label      = "${var.prefix}-vm-to-migrate"
  public_key = tls_private_key.ssh.public_key_openssh
  notes = "created by terraform"
}

resource "ibm_compute_vm_instance" "vm" {
  hostname          = "${var.prefix}-classic-vm"
  domain            = "howto.cloud"
  ssh_key_ids       = ["${ibm_compute_ssh_key.key.id}"]
  os_reference_code = "CENTOSSTREAM_9_64"
  datacenter        = var.classic_datacenter
  cores             = 1
  memory            = 1024

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "root"
      private_key = tls_private_key.ssh.private_key_pem
      agent       = false
      host        = ibm_compute_vm_instance.vm.ipv4_address
    }

    # install nginx on the server
    inline = [
      "touch this_file_was_created_in_classic",
      "yum install -y epel-release",
      "yum install -y nginx",
      "systemctl start nginx",
      "systemctl enable nginx" # enable on boot
    ]
  }
}

output "CLASSIC_ID" {
  value = ibm_compute_vm_instance.vm.id
}

output "CLASSIC_IP_ADDRESS" {
  value = ibm_compute_vm_instance.vm.ipv4_address
}
