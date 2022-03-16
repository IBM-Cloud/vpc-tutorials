variable "ibmcloud_api_key" {
  description = "You IAM based API key."
  default     = ""
}

variable "vpc_region" {
  description = "The VPC region to deploy the resources under."
  default     = ""
}

variable "vpc_ssh_key" {
  description = "The names of SSH key used to access virtual server instances after creation."
  default     = ""
}

variable "resource_group" {
  description = "The resource group for all the resources created (VPC and non VPC)."
  default     = ""
}

variable "ssh_private_key_format" {
  description = "Values can be file: requires for `ssh_private_key_file` to be set , content: requires for `ssh_private_key_content` to be set or build: will create an SSH key for use during the build."
  default     = "build"
}

variable "ssh_private_key_file" {
  description = "The file system location of private ssh key for virtual server instances access. Only use if the ssh_private_key_format value is set to `file`, tt needs to be a local file."
  default     = "~/.ssh/id_rsa"
}

variable "ssh_private_key_content" {
  description = "The content of the private ssh key for virtual server instances access. Only use if the ssh_private_key_format value is set to `content`."
  default     = ""
}

variable "resources_prefix" {
  description = "Prefix is added to all resources that are created by this template."
  default     = "cockroach"
}

variable "vpc_database_image_profile" {
  description = "The profile for the database instance, increase the size based on environment need."
  default     = "cx2-2x4"
}

variable "vpc_app_image_profile" {
  description = "The profile for the application instance, increase the size based on environment need"
  default     = "cx2-2x4"
}

variable "vpc_admin_image_profile" {
  description = "The profile for admin instance, it does not require a lot of system resources."
  default     = "cx2-2x4"
}

variable "vpc_admin_image_name" {
  description = "The scripts required for this configuration have only been validated on Ubuntu."
  default     = "ibm-ubuntu-20-04-minimal-amd64-2"
}

variable "vpc_app_image_name" {
  description = "The scripts required for this configuration have only been validated on Ubuntu."
  default     = "ibm-ubuntu-20-04-minimal-amd64-2"
}

variable "vpc_database_image_name" {
  description = "The scripts required for this configuration have only been validated on Ubuntu."
  default     = "ibm-ubuntu-20-04-minimal-amd64-2"
}

variable "cockroachdb_binary_url" {
  description = "The url for the cockroacdb download."
  default     = "https://binaries.cockroachdb.com"
}

variable "cockroachdb_binary_archive" {
  description = "The archive filename for the cockroacdb download."
  default     = "cockroach-v20.2.4.linux-amd64.tgz"
}

variable "cockroachdb_binary_directory" {
  description = "The directory for the cockroacdb archive when extracted."
  default     = "cockroach-v20.2.4.linux-amd64"
}

variable "create_secrets_manager_instance" {
  description = "Indicates whether or not to create a Secrets Manager instance, values can be true or false, default to false."
  default     = false
}

variable "secrets_manager_instance_name" {
  description = "The name of an existing Secrets Manager instance, used when create_secrets_manager_instance is set to false."
  default     = "sm-instance-name"
}
