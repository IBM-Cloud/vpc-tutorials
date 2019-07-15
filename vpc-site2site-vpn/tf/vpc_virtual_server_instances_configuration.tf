
data "template_file" "app_deploy" {
  count = "${var.create_compute_resources == "true" ? 3 : 0}"
  template = "${file("./scripts/app-deploy.sh")}"

  vars = {
    vsi_ipv4_address = "${element(ibm_is_instance.vsi_app.*.primary_network_interface.0.primary_ipv4_address, count.index)}"
    floating_ip      = "${ibm_is_floating_ip.vsi_admin_fip.0.address}"
    lb_hostname = "${ibm_is_lb.lb_private.hostname}"
    app_url = "https://github.com/IBM-Cloud/vpc-tutorials.git"
    app_repo= "vpc-tutorials"
    app_directory= "sampleapps/nodejs-graphql"
  }
}

resource "null_resource" "vsi_app" {
  count = "${var.create_compute_resources == "true" ? 3 : 0}"

  connection {
    type         = "ssh"
    host         = "${element(ibm_is_instance.vsi_app.*.primary_network_interface.0.primary_ipv4_address, count.index)}"
    user         = "root"
    private_key  = "${file("${var.ssh_private_key}")}"
    bastion_host = "${ibm_is_floating_ip.vsi_admin_fip.0.address}"
  }

  provisioner "file" {
    content      = "${element(data.template_file.app_deploy.*.rendered, count.index)}"
    destination = "/tmp/app-deploy.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/app-deploy.sh",
      "/tmp/app-deploy.sh",
    ]
  }

  depends_on = ["null_resource.vsi_admin_2"]
}

resource "null_resource" "vsi_app_2" {
  count = "${var.create_compute_resources == "true" ? 3 : 0}"

  connection {
    type         = "ssh"
    host         = "${element(ibm_is_instance.vsi_app.*.primary_network_interface.0.primary_ipv4_address, count.index)}"
    user         = "root"
    private_key  = "${file("${var.ssh_private_key}")}"
    bastion_host = "${ibm_is_floating_ip.vsi_admin_fip.0.address}"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /vpc-tutorials/sampleapps/nodejs-graphql/certs"
    ]
  }

  provisioner "local-exec" {
    command = "scp -F ./scripts/ssh.config -i ${var.ssh_private_key} -o 'ProxyJump root@${ibm_is_floating_ip.vsi_admin_fip.0.address}' config/${var.resources_prefix}-certs/client.maxroach.key root@${element(ibm_is_instance.vsi_app.*.primary_network_interface.0.primary_ipv4_address, count.index)}:/vpc-tutorials/sampleapps/nodejs-graphql/certs/client.maxroach.key"
  }

  provisioner "local-exec" {
    command = "scp -F ./scripts/ssh.config -i ${var.ssh_private_key} -o 'ProxyJump root@${ibm_is_floating_ip.vsi_admin_fip.0.address}' config/${var.resources_prefix}-certs/client.maxroach.crt root@${element(ibm_is_instance.vsi_app.*.primary_network_interface.0.primary_ipv4_address, count.index)}:/vpc-tutorials/sampleapps/nodejs-graphql/certs/client.maxroach.crt"
  }

  provisioner "local-exec" {
    command = "scp -F ./scripts/ssh.config -i ${var.ssh_private_key} -o 'ProxyJump root@${ibm_is_floating_ip.vsi_admin_fip.0.address}' config/${var.resources_prefix}-certs/ca.crt root@${element(ibm_is_instance.vsi_app.*.primary_network_interface.0.primary_ipv4_address, count.index)}:/vpc-tutorials/sampleapps/nodejs-graphql/certs/ca.crt"
  }

  provisioner "remote-exec" {
    inline = [
      "cd /vpc-tutorials/sampleapps/nodejs-graphql/",
      "pm2 start build/index.js",
      "pm2 startup systemd",
      "pm2 save"
    ]
  }
  depends_on = ["null_resource.vsi_app"]
}

data "template_file" "cockroachdb_admin_systemd" {
  count = "${var.create_compute_resources == "true" ? 1 : 0}"
  template = "${file("./scripts/cockroachdb-admin-systemd.sh")}"

  vars = {
    lb_hostname = "${ibm_is_lb.lb_private.hostname}"
    node1_address = "${element(ibm_is_instance.vsi_database.*.primary_network_interface.0.primary_ipv4_address, 0)}"
    node2_address = "${element(ibm_is_instance.vsi_database.*.primary_network_interface.0.primary_ipv4_address, 1)}"
    node3_address = "${element(ibm_is_instance.vsi_database.*.primary_network_interface.0.primary_ipv4_address, 2)}"
    app_url="https://binaries.cockroachdb.com"
    app_binary_archive="cockroach-v2.1.6.linux-amd64.tgz"
    app_binary="cockroach"
    app_user="cockroach"
    app_directory="cockroach-v2.1.6.linux-amd64"
    certs_directory="/certs"
    ca_directory="/cas"
  }
}

resource "null_resource" "vsi_admin" {
  count = "${var.create_compute_resources == "true" ? 1 : 0}"

  connection {
    type        = "ssh"
    host        = "${ibm_is_floating_ip.vsi_admin_fip.0.address}"
    user        = "root"
    private_key = "${file("${var.ssh_private_key}")}"
  }

  provisioner "file" {
    content      = "${element(data.template_file.cockroachdb_admin_systemd.*.rendered, count.index)}"
    destination = "/tmp/cockroachdb-admin-systemd.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/cockroachdb-admin-systemd.sh",
      "/tmp/cockroachdb-admin-systemd.sh",
    ]
  }
}

resource "null_resource" "vsi_admin_2" {
  count = "${var.create_compute_resources == "true" ? 1 : 0}"

  # provisioner "local-exec" {
  #   command = "mkdir \"config/${var.resources_prefix}-certs/\""
  # }
  provisioner "local-exec" {
    command = "scp -F ./scripts/ssh.config -i ${var.ssh_private_key} -r root@${ibm_is_floating_ip.vsi_admin_fip.0.address}:/certs ./config/${var.resources_prefix}-certs/"
  }

  provisioner "local-exec" {
    when = "destroy"
    command = "rm -rf ./config/${var.resources_prefix}-certs"
  }

  depends_on = ["null_resource.vsi_admin"]
}

resource "null_resource" "vsi_admin_3" {
  count = "${var.create_compute_resources == "true" ? 1 : 0}"

  connection {
    type        = "ssh"
    host        = "${ibm_is_floating_ip.vsi_admin_fip.0.address}"
    user        = "root"
    private_key = "${file("${var.ssh_private_key}")}"
  }

  provisioner "remote-exec" {
    inline = [
      "cockroach init --certs-dir=/certs --host=${element(ibm_is_instance.vsi_database.*.primary_network_interface.0.primary_ipv4_address, 0)}"
    ]
  }

  depends_on = ["null_resource.vsi_database_2"]
}
