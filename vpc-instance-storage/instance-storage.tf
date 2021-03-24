resource "null_resource" "instance_storage" {
  connection {
    type = "ssh"
    host = ibm_is_floating_ip.vpc_vsi_app_fip.0.address
    
    user         = "root"
    private_key = var.ssh_private_key_format == "file" ? file(var.ssh_private_key_file) : var.ssh_private_key_format == "content" ? var.ssh_private_key_content : tls_private_key.build_key.0.private_key_pem
  }

  provisioner "file" {
    content = templatefile("${path.module}/scripts/instance-storage-config.sh", {})
    destination = "/tmp/instance-storage-config.sh"
  }

  provisioner "file" {
    content = templatefile("${path.module}/scripts/instance-storage-service.sh", {})
    destination = "/usr/bin/instance-storage-service.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "chmod +x /tmp/instance-storage-config.sh",
      "sed -i.bak 's/\r//g' /tmp/instance-storage-config.sh",
      "/tmp/instance-storage-config.sh",
      "chmod +x /usr/bin/instance-storage-service.sh",
      "sed -i.bak 's/\r//g' /usr/bin/instance-storage-service.sh",
      "systemctl start instance-storage",
      "systemctl enable instance-storage",      
    ]
  }
}