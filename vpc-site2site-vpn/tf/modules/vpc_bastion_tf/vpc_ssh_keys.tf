
data ibm_is_ssh_key "ssh_key" {
  count = "${length(var.vpc_ssh_keys)}"
  name  = "${var.vpc_ssh_keys[count.index]}"
}
