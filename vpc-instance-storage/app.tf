resource "null_resource" "app" {
  connection {
    type = "ssh"
    host = ibm_is_floating_ip.vpc_vsi_app_fip.0.address

    user        = "root"
    private_key = var.ssh_private_key_file != "" ? file(var.ssh_private_key_file) : var.ssh_private_key_content != "" ? var.ssh_private_key_content : tls_private_key.build_key.private_key_pem
  }

  provisioner "file" {
    content = templatefile("${path.module}/scripts/app-config-service.sh", {
      mount = var.boot_volume_auto_delete == true ? "data0.mount" : ""
    })
    destination = "/tmp/app-config-service.sh"
  }

  provisioner "file" {
    content     = templatefile("${path.module}/scripts/app.sh", {})
    destination = "/usr/bin/app.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "chmod +x /tmp/app-config-service.sh",
      "sed -i.bak 's/\r//g' /tmp/app-config-service.sh",
      "/tmp/app-config-service.sh",
      "chmod +x /usr/bin/app.sh",
      "sed -i.bak 's/\r//g' /usr/bin/app.sh",
      "systemctl enable app",
      "sleep 45",
      "systemctl start app",
    ]
  }

  depends_on = [null_resource.instance_storage]
}
