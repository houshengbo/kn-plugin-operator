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
  kn-op-ke

Examples:
  # Install the Knative Eventing under the namespace knative-Eventing
  kn-op-ke

  # Install the Knative Eventing at a specific version or upgrade to a specific version
  kn-op-ks -v VERSION

  # Install the Knative Eventing under a specified namespace
  kn-op-ke -n NAMESPACE

  # Install the Knative Eventing at a specific version or upgrade to a specific version
  # under a specified namespace
  kn-op-ke -n NAMESPACE -v VERSION

  Flags:
	-n, --namespace string           Specify the namespace to install the Knative Eventing.
	-v, --version string             Specify the version of the Knative Eventing.
"

source "$(dirname "$0")/kn-op-commons.sh"

# Generate the file base.yaml.
function generate_base_yaml_ke_ns() {
  # This function generate the file base.yaml to install knative eventing under a certain namespace.
  rm -rf ${BASE_YAML}
  run_exit "kubectl get knativeeventing ${NAME} -n ${NS}" && kubectl get knativeeventing knative-eventing -n ${NS} -o yaml | yq eval 'del(.metadata.finalizers,
    .metadata.generation, .metadata.resourceVersion, .metadata.uid, .metadata.annotations, .metadata.creationTimestamp,
    .metadata.selfLink, .metadata.managedFields, .status)' - > ${BASE_YAML}

  if [ ! -f "${BASE_YAML}" ]; then
    echo "apiVersion: operator.knative.dev/v1alpha1" >> ${BASE_YAML}
    echo "kind: KnativeEventing" >> ${BASE_YAML}
    echo "metadata:" >> ${BASE_YAML}
    echo "  name: ${NAME}" >> ${BASE_YAML}
    echo "  namespace: ${NS}" >> ${BASE_YAML}
  fi
}

function generate_values_yaml_ke_ns {
  run_exit "rm -rf ${VALUES_YAML}"
  echo "#@data/values" >> ${VALUES_YAML}
  echo "---" >> ${VALUES_YAML}
  echo "name: ${NAME}" >> ${VALUES_YAML}
  echo "namespace: ${NS}" >> ${VALUES_YAML}
  echo "version: \"${VERSION}\"" >> ${VALUES_YAML}
}

# Generate the file overlay.yaml.
function generate_overlay_ke_yaml() {
  # This function generate the file values.yaml to install the operator under a certain namespace.
  path=$(dirname "$0")"/"overlay/ke.yaml
  run_exit "cp ${path} ${OVERLAY_YAML}"
}

mkdir -p $TEMP_DIR
NS=${KE_DEFAULT_NS}
NAME=${KE_DEFAULT_NAME}

while test $# -gt 0; do
  case "$1" in
    -h|--help)
      echo "$USAGE"
      exit 0
      ;;
    --name)
      shift
      if test $# -gt 0; then
        NAME=$1
      else
        echo "No name is specified."
        exit 1
      fi
      shift
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

# Create the namespace, if it does not exist.
run_exit "kubectl get ns ${NS}" || run_exit "kubectl create namespace ${NS}"

generate_base_yaml_ke_ns

# Generate the file values.yaml based on the namespace.
generate_values_yaml_ke_ns

# Generate the file overlay.yaml based on the namespace.
generate_overlay_ke_yaml

# Install the Knative Operator
run_command

# Remove all temporary files and directories
rm -r $TEMP_DIR
