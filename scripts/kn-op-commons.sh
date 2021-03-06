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

# Initialize the variables
export NS="default"
export VERSION="latest"
export ISTIO_NS="istio-system"
export NAME="default"
export TEMP_DIR="${TEMP_DIR:-$(mktemp -d -t ci-$(date +%Y-%m-%d-%H-%M-%S)-XXXXXXXXXX)}"
readonly YTT_OUTPUT_DIR="${TEMP_DIR}/output"
readonly BASE_YAML="${TEMP_DIR}/base.yaml"
readonly OVERLAY_YAML="${TEMP_DIR}/overlay.yaml"
readonly VALUES_YAML="${TEMP_DIR}/values.yaml"
readonly KS_DEFAULT_NS="knative-serving"
readonly KE_DEFAULT_NS="knative-eventing"
readonly KS_DEFAULT_NAME="knative-serving"
readonly KE_DEFAULT_NAME="knative-eventing"

# Run the command.
function run_command() {
  ytt -f ${VALUES_YAML} -f ${OVERLAY_YAML} -f ${BASE_YAML} --output-files ${YTT_OUTPUT_DIR} > /dev/null 2>&1
  kubectl apply -f ${YTT_OUTPUT_DIR}/
}

# Generate the file overlay.yaml.
function generate_overlay_yaml() {
  # This function generate the file values.yaml to install the operator under a certain namespace.
  original_file=$1
  path=$(dirname "$0")"/"${original_file}
  run_exit "cp ${path} ${OVERLAY_YAML}"
}

function run_exit()
{
  $1 > /dev/null 2>&1
}
