locals {
  ibm_vsi1_security_groups = [ibm_is_security_group.sg1.id]
  ibm_vsi1_user_data = <<EOS
#!/bin/sh
EOS
}
