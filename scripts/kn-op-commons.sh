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
export TEMP_DIR="${TEMP_DIR:-$(mktemp -d -t ci-$(date +%Y-%m-%d-%H-%M-%S)-XXXXXXXXXX)}"
YTT_OUTPUT_DIR="${TEMP_DIR}/output"
BASE_YAML="${TEMP_DIR}/base.yaml"
OVERLAY_YAML="${TEMP_DIR}/overlay.yaml"
VALUES_YAML="${TEMP_DIR}/values.yaml"
KS_DEFAULT_NS="knative-serving"
KE_DEFAULT_NS="knative-eventing"
export ISTIO_NS="istio-system"

# Run the command.
function run_command() {
  ytt -f ${VALUES_YAML} -f ${OVERLAY_YAML} -f ${BASE_YAML} --output-files ${YTT_OUTPUT_DIR}
  kubectl apply -f ${YTT_OUTPUT_DIR}/
}

# Generate the file overlay.yaml.
function generate_overlay_yaml() {
  # This function generate the file values.yaml to install the operator under a certain namespace.
  original_file=$1
  cp ${original_file} ${OVERLAY_YAML}
}
