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
