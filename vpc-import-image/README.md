# Layout
# Notes
debian9 does not have cloud init.  I was able to log in using the serial console.  Added this to user_data (terraform).
Login as root on the serial console is possible.
```
resource "ibm_is_instance" "instance" {
  user_data = <<-EOS
    password: password
    chpasswd:
      expire: False

  EOS
}
```
