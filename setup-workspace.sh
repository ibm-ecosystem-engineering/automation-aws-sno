#!/usr/bin/env bash

WORK_DIR="$(pwd)"
INSTALL_DIR="${WORK_DIR}/install"
TERRAFORM_DIR="${WORK_DIR}/terraform"
BIN_DIR="binaries"
BINARY_DIR="${INSTALL_DIR}/${BIN_DIR}"
INTERACT=1
SSH_KEY=""
MAX_PREFIX_LENGTH=5
MAX_TAG_LENGTH=512
AWS_PROFILE="ocp-sno"

DEFAULT_NODE_TYPE="m6i.4xlarge"
DEFAULT_VOL_SIZE="500"
DEFAULT_VOL_IOPS="400"
DEFAULT_VOL_TYPE="io1"
DEFAULT_DOMAIN="ocp-aws.ibm-software-everywhere.dev"
DEFAULT_REGION="ap-southeast-2"
DEFAULT_OCP_VERSION="4.10"
DEFAULT_INGRESS="Y"
DEFAULT_PUBLIC="Y"

# Function to display menu
function menu() {
    local item i=1 numItems=$#

    for item in "$@"; do
        printf '%s %s\n' "$((i++))" "$item"
    done >&2

    while :; do
        printf %s "${PS3-#? }" >&2
        read -r input
        if [[ -z $input ]]; then
            break
        elif (( input < 1 )) || (( input > numItems )); then
          echo "Invalid Selection. Enter number next to item." >&2
          continue
        fi
        break
    done

    if [[ -n $input ]]; then
        printf %s "${@: input:1}"
    fi
}

# Interact for values
if [[ $INTERACT ]]; then
  
  # Get to AWS credentials
  if [[ -z $AWS_ACCESS_KEY_ID ]] || [[ -z $AWS_SECRET_ACCESS_KEY ]]; then
    while [[ -z $ACCESS_KEY ]]; do
        echo
        echo -n -e "Enter AWS Access Key: "
        read -s input

        if [[ -n $input ]]; then
        if [[ $input =~ [a-zA-Z0-9] ]] && (( ${#input} >= 16  )) && (( ${#input} <= 128 )) ; then
            ACCESS_KEY=$input
        else
            echo "Invalid Access Key."
        fi
        fi
    done

    while [[ -z $AWS_SECRET ]]; do
        echo
        echo -n -e "Enter AWS Secret Key: "
        read -s input

        if [[ -n $input ]]; then
        if [[ $input =~ [a-zA-Z0-9] ]] && (( ${#input} >= 16  )) && (( ${#input} <= 128 )) ; then
            AWS_SECRET=$input
        else
            echo "Invalid Secret Key."
        fi
        fi
    done

    export AWS_ACCESS_KEY_ID="$ACCESS_KEY"
    export AWS_SECRET_ACCESS_KEY="$AWS_SECRET"
  fi

  # Get region
  echo
  read -r -d '' -a REGIONS < <(aws ec2 describe-regions | jq -r '.Regions[].RegionName')
  PS3="Select the region [$DEFAULT_REGION]: "
  region=$(menu "${REGIONS[@]}")
  case $region in
    '') REGION="$DEFAULT_REGION"; ;;
     *) REGION=$region;
  esac

  # Configure AWS CLI
  aws configure set region $REGION --profile $AWS_PROFILE
  aws configure set output json --profile $AWS_PROFILE
  export AWS_PROFILE=$AWS_PROFILE

  # Get name prefix
  name=""
  alpha_chars=abcdefghijklmnopqrstuvwxyz
  name=${alpha_chars:RANDOM%${#alpha_chars}:1}
  chars=abcdefghijklmnopqrstuvwxyz0123456789
  for i in {1..4}; do
      name+=${chars:RANDOM%${#chars}:1}
  done

  while [[ -z $INPUT_NAME ]]; do
    echo
    echo -n -e "Enter name prefix [$name]: "
    read input

    if [[ -n $input ]]; then
      if [[ $input =~ [a-zA-Z0-9] ]] && (( ${#input} <= $MAX_PREFIX_LENGTH )) ; then
        INPUT_NAME=$input
      else
        echo "Invalid prefix name. Must be less than $MAX_PREFIX_LENGTH, not contain spaces and be alphanumeric characters only"
      fi
    elif [[ -z $input ]]; then
      INPUT_NAME=$name
    fi
  done

  NAME_PREFIX="${INPUT_NAME}"

  # Get Resource group tag 
  DEFAULT_RG="${NAME_PREFIX}-rg"
  while [[ -z $RG_INPUT ]]; do
    echo
    echo -n -e "Enter Resource Group Tag Name [$DEFAULT_RG]: "
    read input

    if [[ -n $input ]]; then
      if [[ $input =~ [a-zA-Z0-9] ]] && (( ${#input} <= $MAX_TAG_LENGTH )); then
        RG_INPUT=$input
      else
        echo "Invalid resource group name. Must be less than $MAX_TAG_LENGTH, not contain spaces and be alphanumeric charactors only"
      fi
    elif [[ -z $input ]]; then
      RG_INPUT="$DEFAULT_RG"
    fi
  done

  RESOURCE_GROUP="${RG_INPUT}"

  # Get base domain
  echo
  read -r -d '' -a ZONES < <(aws route53 list-hosted-zones | jq -r '.HostedZones[].Name')
  PS3="Select the domain [$DEFAULT_DOMAIN]: "
  zone=$(menu "${ZONES[@]}")
  case $zone in
    '') DOMAIN="$DEFAULT_DOMAIN"; ;;
     *) DOMAIN=$zone
  esac

  # Get SSH Key
  echo 
  while [[ -z $SSH_INPUT ]]; do
    echo
    echo -n -e "Enter Public SSH Key for Node Access. Leave blank to create new key. [\"\"]: "
    read input

    if [[ -n $input ]]; then
      SSH_INPUT=$input
    elif [[ -z $input ]]; then
      SSH_INPUT="DEFAULT"
    fi
  done

  if [[ $SSH_INPUT == "DEFAULT" ]]; then
    SSH_KEY=""
  else
    SSH_KEY="$SSH_INPUT"
  fi

  # Get node type
  echo

  TYPES_LIST=$(aws ec2 describe-instance-types | jq -r '.InstanceTypes[].InstanceType')
  AVAIL_TYPES=()
  while IFS='' read -r type; do
    AVAIL_TYPES+=("$type")
  done <<<$(echo $TYPES_LIST)

  while [[ -z $NODE_TYPE ]]; do
    echo
    echo -n -e "Enter AWS Node Type ["$DEFAULT_NODE_TYPE"]: "
    read input

    if [[ -n $input ]]; then
      if [[ "${AVAIL_TYPES[*]}" =~ $input ]]; then
        NODE_TYPE=$input
      else
        echo "Type $input not available."
      fi
    elif [[ -z $input ]]; then
      NODE_TYPE="$DEFAULT_NODE_TYPE"
    fi
  done

  # Get openshift version
  echo
  while [[ -z $OPENSHIFT_VERSION ]]; do
    echo
    echo -n -e "Enter OpenShift Version ["$DEFAULT_OCP_VERSION"]: "
    read input

    if [[ -n $input ]]; then
      OPENSHIFT_VERSION=$input
    elif [[ -z $input ]]; then
      OPENSHIFT_VERSION="$DEFAULT_OCP_VERSION"
    fi
  done

  # Get pull secret
  if [[ -n $TF_VAR_pull_secret ]]; then
    PULL_SECRET=$TF_VAR_pull_secret
  else
    echo
    while [[ -z $PULL_SECRET ]]; do
        echo
        echo -n -e "Enter Red Hat OpenShift Pull Secret: "
        read -n 4096 -s input

        if [[ -n $input ]]; then
          PULL_SECRET=$input
        elif [[ -z $input ]]; then
          echo "Pull secret is required for cluster creation."
        fi
    done
  fi

  # Get disk volume size
  echo
  while [[ -z $VOL_SIZE ]]; do
    echo
    echo -n -e "Enter Disk Volume Size ["$DEFAULT_VOL_SIZE"]: "
    read input

    if [[ -n $input ]]; then
      VOL_SIZE=$input
    elif [[ -z $input ]]; then
      VOL_SIZE="$DEFAULT_VOL_SIZE"
    fi
  done

  # Get disk volume type
  echo
  while [[ -z $VOL_TYPE ]]; do
    echo
    echo -n -e "Enter Disk Volume Type ["$DEFAULT_VOL_TYPE"]: "
    read input

    if [[ -n $input ]]; then
      VOL_TYPE=$input
    elif [[ -z $input ]]; then
      VOL_TYPE="$DEFAULT_VOL_TYPE"
    fi
  done

  # Get disk volume IOPS
  echo
  while [[ -z $VOL_IOPS ]]; do
    echo
    echo -n -e "Enter Disk Volume IOPS ["$DEFAULT_VOL_IOPS"]: "
    read input

    if [[ -n $input ]]; then
      VOL_IOPS=$input
    elif [[ -z $input ]]; then
      VOL_IOPS="$DEFAULT_VOL_IOPS"
    fi
  done

  # Create ingress certificate (for console access)?
  echo
  while [[ -z $CREATE_INGRESS ]]; do
    echo
    echo -n -e "Create ingress certificates for console access [$DEFAULT_INGRESS]: "
    read input

    if [[ -z $input ]] || [[ "$(echo ${input:0:1} | tr '[:lower:]' '[:upper:]')" == "$DEFAULT_INGRESS" ]]; then
        CREATE_INGRESS="$DEFAULT_INGRESS"
    elif [[ "$(echo ${input:0:1} | tr '[:lower:]' '[:upper:]' )" != "$DEFAULT_INGRESS" ]]; then
        CREATE_INGRESS=$(echo ${input:0:1} | tr '[:lower:]' '[:upper:]')
    else
        echo "Incorrect entry. Please try again."
    fi
  done

  # Get email address for ingress certificates
  if [[ $CREATE_INGRESS == "Y" ]]; then
    echo
    while [[ -z $ACME_EMAIL ]]; do
        echo
        echo -n -e "Enter valid email address for LetsEncrypt certificates: "
        read input

        if [[ -n $input ]] && [[ $input =~ [a-zA-Z0-9@] ]]; then
          ACME_EMAIL=$input
        else
          echo "Please enter a valid email address."
        fi
    done
  fi
    

  # Create public endpoint?
  echo
  while [[ -z $CREATE_PUBLIC ]]; do
    echo
    echo -n -e "Create public internet endpoint for cluster [$DEFAULT_PUBLIC]: "
    read input

    if [[ -z $input ]] || [[ "$(echo ${input:0:1} | tr '[:lower:]' '[:upper:]')" == "$DEFAULT_PUBLIC" ]]; then
        CREATE_PUBLIC="$DEFAULT_PUBLIC"
    elif [[ "$(echo ${input:0:1} | tr '[:lower:]' '[:upper:]' )" != "$DEFAULT_PUBLIC" ]]; then
        CREATE_PUBLIC=$(echo ${input:0:1} | tr '[:lower:]' '[:upper:]')
    else
        echo "Incorrect entry. Please try again."
    fi
  done

  echo 
  echo "Setting up workspace with the following parameters:"
  echo "Name Prefix                  = $NAME_PREFIX"
  echo "Region                       = $REGION"
  echo "ResourceGroup tag            = $RESOURCE_GROUP"
  echo "Base domain name             = $DOMAIN"
  echo "Create ingress certificates? = $CREATE_INGRESS"
  if [[ $CREATE_INGRESS == "Y" ]]; then
    echo "Email address for certificates = $ACME_EMAIL"
  fi
  echo "Create public endpoint?      = $CREATE_PUBLIC"
  if [[ -n $SSH_KEY ]]; then
    echo "Public SSH Key               = Set"
  else
    echo "Public SSH Key               = Will be created"
  fi
  if [[ -n $PULL_SECRET ]]; then
    echo "Pull Secret                  = Set"
  else
    echo "Pull Secret                  = Not set. Build will fail. Please rectify"
    exit 1
  fi
  echo "Node Type                    = $NODE_TYPE"
  echo "Openshift Version            = $OPENSHIFT_VERSION"
  echo "Volume Size                  = $VOL_SIZE"
  echo "Volume Type                  = $VOL_TYPE"
  echo "Volume IOPS                  = $VOL_IOPS"

  echo
  echo -n -e "Configure workspace for these parameters? [Y]: "
  read input

  if [[ -n $input ]] && [[ $(echo ${input:0:1} | tr '[:lower:]' '[:upper:]') != "Y" ]]; then
    echo "Exiting workspace setup."
    exit 0;
  fi
fi

# copy files to install directory
echo -n "Copying terraform files to work directory ...."
mkdir -p $INSTALL_DIR
cp ${TERRAFORM_DIR}/*.tf ${INSTALL_DIR}
echo "Done"

# Setup terraform.tfvars
echo -n "Creating terraform.tfvars in work directory ...."

cat "${TERRAFORM_DIR}/terraform.tfvars-template" | \
  sed "s/NAME_PREFIX/$NAME_PREFIX/g" | \
  sed "s/REGION/$REGION/g" | \
  sed "s/RESOURCE_GROUP/$RESOURCE_GROUP/g" | \
  sed "s/DOMAIN/$DOMAIN/g" | \
  sed "s/NODE_TYPE/$NODE_TYPE/g" | \
  sed "s/OPENSHIFT_VERSION/$OPENSHIFT_VERSION/g" | \
  sed "s/VOLUME_SIZE/$VOL_SIZE/g" | \
  sed "s/VOLUME_TYPE/$VOL_TYPE/g" | \
  sed "s/VOLUME_IOPS/$VOL_IOPS/g" | \
  sed "s/BIN_DIR/$BIN_DIR/g" \
  > "${INSTALL_DIR}/terraform.tfvars"

if [[ -n $SSH_KEY ]]; then
  echo $'\n'"pub_ssh_key=\"${SSH_KEY}\"" >> "$INSTALL_DIR/terraform.tfvars"
fi

if [[ $CREATE_INGRESS == "N" ]]; then
  echo $'\n'"update_ingress_cert=false" >> "$INSTALL_DIR/terraform.tfvars"
fi

if [[ $CREATE_PUBLIC == "N" ]]; then
  echo $'\n'"private=\"true\"" >> "$INSTALL_DIR/terraform.tfvars"
fi

echo "Done"

# Confirm proceed
echo -n -e "Proceed with build? [Y]: "
read input

if [[ -n $input ]] && [[ $(echo ${input:0:1} | tr '[:lower:]' '[:upper:]') != "Y" ]]; then
  echo "Exiting build. To manually build do the following:"
  echo "   $ cd ./${INSTALL_DIR}"
  echo "   $ export TF_VAR_access_key=\"<AWS_Access_Key>\""
  echo "   $ export TF_VAR_secret_key=\"<AWS_Secret_Access_Key>\""
  echo "   $ terraform init"
  echo "   $ terrform apply"
  exit 0;
fi

# Export AWS login credentials for terraform
export TF_VAR_access_key=$ACCESS_KEY
export TF_VAR_secret_key=$AWS_SECRET
export TF_VAR_pull_secret=$PULL_SECRET

# Download OpenShift version
echo "Downloading OpenShift installation binary for version ${OPENSHIFT_VERSION}"
ARCH=$(uname -m)

case $(uname) in 
  Darwin) OCP_FILETYPE="mac" ;;
  alpine) OCP_FILETYPE="linux" ;;
  *) OCP_FILETYPE="linux" ;;
esac 

# For M1 Macbooks, use amd64 binaries
if [[ $ARCH == "arm64" ]] && [[ $OCP_FILETYPE == "mac" ]]; then
    OCP_ARCH="amd64"
else
    OCP_ARCH="$ARCH"
fi

if [[ -z "${OPENSHIFT_VERSION}" ]] || [[ "${OPENSHIFT_VERSION}" == "4" ]]; then
  OCP_URL="https://mirror.openshift.com/pub/openshift-v4/${OCP_ARCH}/clients/ocp/stable/openshift-install-${OCP_FILETYPE}.tar.gz"
elif [[ "${OPENSHIFT_VERSION}" =~ [0-9][.][0-9]+[.][0-9]+ ]]; then
  OCP_URL="https://mirror.openshift.com/pub/openshift-v4/${OCP_ARCH}/clients/ocp/${OPENSHIFT_VERSION}/openshift-install-${OCP_FILETYPE}.tar.gz"
else
  OCP_URL="https://mirror.openshift.com/pub/openshift-v4/${OCP_ARCH}/clients/ocp/stable-${OPENSHIFT_VERSION}/openshift-install-${OCP_FILETYPE}.tar.gz"
fi

TAR_FILE="${BINARY_DIR}/openshift-install-${OPENSHIFT_VERSION}.tgz"
mkdir -p ${BINARY_DIR}
curl -sLo $TAR_FILE $OCP_URL

if ! tar tzf $TAR_FILE 1> /dev/null 2> /dev/null; then
  echo "Tar file for openshift is corrupt: $TAR_FILE from $OCP_URL" >&2
  exit 1
else
  echo "Unpacking ${TAR_FILE}"
  cd $BINARY_DIR
  tar xzf $TAR_FILE openshift-install
  rm $TAR_FILE
fi

# Change to workspace and run installation
cd $INSTALL_DIR
echo "Initializing terraform ..."
terraform init
echo "Done with terraform initialization"

echo "Applying terraform infrastructure as code ..."
#terraform plan
terraform apply -auto-approve
