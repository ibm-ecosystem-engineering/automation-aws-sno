# automation-aws-snos
Single Node OpenShift deployment on AWS

# Prerequisites

## CLI Tools

- The following cli tools must be installed and available in PATH
    - aws
    - jq
    - terraform

## DNS Zone

- A domain needs to be configured in Route53 for use by the cluster. Instructions [here](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/MigratingDNS.html), or search for instructions for your domain hosting service.

## Quota

- The target region must have quota available for an additional VPC with 1 elastic IP and a NAT Gateway.

# Instructions

1. Run `setup-workspace.sh` and follow the prompts for the required parameters. 

2. Review the list of parameters and accept to setup the workspace

3. Accept to continue to build when prompted

# Destruction

To destroy the created environment.

```shell
$ cd ./install
$ terraform destroy
```

To clean up the workspace, run `rm -rf ./install`

# Options

It is possible to set the environment variables for the following prior to running `setup-workspace.sh`:
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- TF_VAR_pull_secret

# Use of existing VPC

If using an existing VPC, the minimum requirement is one private subnet. The private subnet must be able to route to the internet to retrieve images from Red Hat. For example, via an NAT gateway attached to a public subnet, or another VPC with VPC peering.

If a public endpoint for the cluster is required, an additional public subnet with an internet gateway is required.

If using Network Security Groups or NetworkACLs, ensure that ports are open to allow the build and run of the cluster to occur. Refer to Red Hat documentation for details.
