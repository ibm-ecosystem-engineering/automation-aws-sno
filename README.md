# automation-aws-snos
Single Node OpenShift deployment on AWS

# Prerequisites

- The following cli tools must be installed and available in PATH
    - aws
    - jq
    - terraform

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
