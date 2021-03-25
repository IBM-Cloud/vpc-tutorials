resource "null_resource" "app" {
  connection {
    type = "ssh"
    host = ibm_is_floating_ip.vpc_vsi_app_fip.0.address
    
    user         = "root"
    private_key = var.ssh_private_key_format == "file" ? file(var.ssh_private_key_file) : var.ssh_private_key_format == "content" ? var.ssh_private_key_content : tls_private_key.build_key.0.private_key_pem
  }

  provisioner "file" {
    content = templatefile("${path.module}/scripts/app-config.sh", {})
    destination = "/tmp/app-config.sh"
  }

  provisioner "file" {
    content = templatefile("${path.module}/scripts/app-service.sh", {})
    destination = "/usr/bin/app-service.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/app-config.sh",
      "sed -i.bak 's/\r//g' /tmp/app-config.sh",
      "/tmp/app-config.sh",
      "chmod +x /usr/bin/app-service.sh",
      "sed -i.bak 's/\r//g' /usr/bin/app-service.sh",
      "systemctl enable app",
      # "systemctl start app",
    ]
  }

  depends_on = [null_resource.instance_storage]
}