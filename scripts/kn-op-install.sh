#!/bin/bash

# Copyright © 2021 The Knative Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

USAGE=$"Usage:
  kn-op-install

Examples:
  # Install the Knative Operator under the default namespace
  kn-op-install

  # Install the Knative Operator at a specific version
  kn-op-install -v VERSION

  # Install the Knative Operator under a specified namespace
  kn-op-install -n NAMESPACE

  # Install the Knative Operator at a specific version under a specified namespace
  kn-op-install -n NAMESPACE -v VERSION

  Flags:
	-n, --namespace string           Specify the namespace to install the Knative Operator.
	-v, --version string             Specify the version of the Knative Operator.
"

# Initialize the variables
NS="default"
VERSION="latest"
LINK="https://github.com/knative/operator/releases/latest/download/operator.yaml"
TEMP_DIR="${TEMP_DIR:-$(mktemp -d -t ci-$(date +%Y-%m-%d-%H-%M-%S)-XXXXXXXXXX)}"
YAML_FILE="knative-operator.yaml"

while test $# -gt 0; do
  case "$1" in
    -h|--help)
      echo "$USAGE"
      exit 0
      ;;
    -n|--namespace)
      shift
      if test $# -gt 0; then
        NS=$1
      else
        echo "No namespace is specified."
        exit 1
      fi
      shift
      ;;
    -v|--version)
      shift
      if test $# -gt 0; then
        VERSION=$1
      else
        echo "No version is specified."
        exit 1
      fi
      shift
      ;;
    *)
      echo "$1 is not a recognized flag!"
      break
      ;;
  esac
done

mkdir -p $TEMP_DIR

if [ "$VERSION" != "latest" ]; then
  LINK="https://github.com/knative/operator/releases/download/v$VERSION/operator.yaml"
fi

# Download the YAML file
wget ${LINK} -O $TEMP_DIR/${YAML_FILE}

if [ "$NS" != "default" ]; then
  # Replace the default namespace
  sed -i.bak "s/namespace: default/namespace: ${NS}/g" $TEMP_DIR/${YAML_FILE}

  # Create the namespace, if it does not exist.
  kubectl get ns ${NS} || kubectl create namespace ${NS}
  kubectl label namespace ${NS} istio-injection=enabled --overwrite
fi

# Install the Knative Operator
kubectl apply -f $TEMP_DIR/${YAML_FILE}

# Remove all temporary files and directories
rm -r $TEMP_DIR
