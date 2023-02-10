variable "name_prefix" {
  type = string
  description = "Prefix for resources"
}

variable "region" {
  type = string
  description = "AWS Region into which to deploy resources"
}

variable "resource_group_name" {
  type = string
  description = "Name for \"ResourceGroup\" tag on all resources"
}

variable "access_key" {
  type = string
  description = "AWS CLI Access Key"
}

variable "secret_key" {
  type = string
  description = "AWS CLI Secret Key"
}

variable "pull_secret" {
  type = string
  description = "Red Hat OpenShift pull secret"
}

variable "pub_ssh_key" {
  type = string
  description = "Public key for node SSH access. Leave blank to create a new one."
  default = ""
}

variable "base_domain_name" {
  type = string
  description = "Route S3 registered domain name prefix for cluster"
  default = "ocp-aws.ibm-software-everywhere.dev"
}

variable "openshift_version" {
  type = string
  description = "OpenShift version to deploy"
  default = "4.10"
}

variable "private" {
  type = bool
  description = "Flag to indicate whether the cluster should not create a public endpoint."
  default = false
}

variable "staging_certs" {
  type = bool
  description = "Flag to indicate whether to use LetsEncrypt staging certificates (for use with testing)."
  default = false
}

variable "update_ingress_cert" {
  type = bool
  description = "Flag to indicate whether to create LetsEncrypt ingress certificates."
  default = true
}

variable "acme_email" {
  type = string
  description = "Email address for LetsEncrypt certificate. Required if creating ingress certificates"
  default = "me@here.com"
}

variable "node_type" {
  type = string
  description = "AWS Node Type for node"
  default = "m6i.4xlarge"
}

variable "volume_size" {
  type = string
  description = "Size of disk volume for node"
  default = "500"
}

variable "volume_type" {
  type = string
  description = "Type of disk volume for node"
  default = "io1"
}

variable "volume_iops" {
  type = string
  description = "IOPS of disk volume for node"
  default = "400"
}

variable "bin_dir" {
  type = string
  description = "Offset directory to store binaries"
  default = "binaries"
}
