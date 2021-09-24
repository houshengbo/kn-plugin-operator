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
  kn-op-ks

Examples:
  # Install the Knative Serving under the namespace knative-serving
  kn-op-ks

  # Install the Knative Serving at a specific version or upgrade to a specific version
  kn-op-ks -v VERSION

  # Install the Knative Serving under a specified namespace
  kn-op-ks -n NAMESPACE

  # Install the Knative Serving, when Istio is installed under the non-default namespace
  kn-op-ks --istio-namespace ISTIO_NAMESPACE

  # Install the Knative Serving at a specific version or upgrade to a specific version
  # under a specified namespace, when Istio is installed under the non-default namespace
  kn-op-ks -n NAMESPACE -v VERSION --istio-namespace ISTIO_NAMESPACE

  Flags:
	-n, --namespace string           Specify the namespace to install the Knative Serving.
	-v, --version string             Specify the version of the Knative Serving.
	--istio-namespace string         Specify the namespace, under which Istio is installed.
"

source "$(dirname "$0")/kn-op-commons.sh"

# Generate the file base.yaml.
function generate_base_yaml_ks_ns() {
  # This function generate the file base.yaml to install knative serving under a certain namespace.
  ns=$1
  rm -rf ${BASE_YAML}
  result=$(kubectl get knativeserving knative-serving -n ${ns} -o yaml)
  if [[ -z ${result} ]]; then
    echo "apiVersion: operator.knative.dev/v1alpha1" >> ${BASE_YAML}
    echo "kind: KnativeServing" >> ${BASE_YAML}
    echo "metadata:" >> ${BASE_YAML}
    echo "  name: knative-serving" >> ${BASE_YAML}
    echo "  namespace: ${ns}" >> ${BASE_YAML}
  else
    kubectl get knativeserving knative-serving -n ${ns} -o yaml | yq eval 'del(.metadata.finalizers,
      .metadata.generation, .metadata.resourceVersion, .metadata.uid, .metadata.annotations, .metadata.creationTimestamp,
      .metadata.selfLink, .metadata.managedFields, .status)' - > ${BASE_YAML}
  fi
}

function generate_values_yaml_ks_ns {
  ns=$1
  version=$2
  istio_ns=$3
  rm -rf ${VALUES_YAML}
  echo "#@data/values" >> ${VALUES_YAML}
  echo "---" >> ${VALUES_YAML}
  echo "namespace: ${ns}" >> ${VALUES_YAML}
  echo "version: \"${version}\"" >> ${VALUES_YAML}
  if [[ "${istio_ns}" != "istio-system" ]]; then
    echo "local_gateway_value: knative-local-gateway.${istio_ns}.svc.cluster.local" >> ${VALUES_YAML}
  fi
}

# Generate the file overlay.yaml.
function generate_overlay_ks_yaml() {
  # This function generate the file values.yaml to install the operator under a certain namespace.
  ns=$1
  istio_ns=$2
  if [[ "${istio_ns}" != "istio-system" ]]; then
    cp overlay/ks_istio_ns.yaml ${OVERLAY_YAML}
    # Replace the namespace for the local gateway. Still have no idea how ytt replaces partially the string in the key,
    # so replace the substring in the overlay.yaml.
    sed -i.bak "s/<local_gateway_namespace>/${NS}/g" ${OVERLAY_YAML}
  else
    cp overlay/ks.yaml ${OVERLAY_YAML}
  fi
}

mkdir -p $TEMP_DIR

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
    --istio-namespace)
      shift
      if test $# -gt 0; then
        ISTIO_NS=$1
      else
        echo "No namespace is specified."
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
kubectl get ns ${NS} || kubectl create namespace ${NS}

generate_base_yaml_ks_ns ${NS}

# Generate the file values.yaml based on the namespace.
generate_values_yaml_ks_ns ${NS} ${VERSION} ${ISTIO_NS}

# Generate the file overlay.yaml based on the namespace.
generate_overlay_ks_yaml ${NS} ${ISTIO_NS}

# Install the Knative Operator
run_command

# Remove all temporary files and directories
rm -r $TEMP_DIR
