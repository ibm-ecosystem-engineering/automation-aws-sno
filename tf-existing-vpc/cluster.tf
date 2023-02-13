module "cluster" {
  source = "github.com/cloud-native-toolkit/terraform-aws-ocp-sno?ref=v1.0.0"

  private_subnet          = var.private_subnet_id
  public_subnet           = var.public_subnet_id
  vpc_cidr                = var.vpc_cidr

  debug                   = false
  install_offset          = "openshift"
  binary_offset           = var.bin_dir

  region                  = var.region
  resource_group_name     = var.resource_group_name

  access_key              = var.access_key
  secret_key              = var.secret_key
  base_domain_name        = var.base_domain_name
  cluster_name            = "${var.name_prefix}-sno"
  pull_secret             = var.pull_secret
  public_ssh_key          = var.pub_ssh_key
  private                 = var.private
  use_staging_certs       = var.staging_certs
  openshift_version       = var.openshift_version
  node_type               = var.node_type
  volume_type             = var.volume_type
  volume_size             = var.volume_size
  volume_iops             = var.volume_iops
  update_ingress_cert     = var.update_ingress_cert
  acme_registration_email = var.acme_email
}