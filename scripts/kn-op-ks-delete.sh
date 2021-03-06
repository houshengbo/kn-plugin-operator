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
  kn-op-ks-delete

Examples:
  # Delete the Knative Serving under the default namespace
  kn-op-ks-delete

  # Delete the Knative Serving under a specified namespace
  kn-op-ks-delete -n NAMESPACE

  Flags:
	-n, --namespace string           Specify the namespace to delete the Knative Serving.
"

source "$(dirname "$0")/kn-op-commons.sh"

NS="knative-serving"

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
    *)
      echo "$1 is not a recognized flag!"
      break
      ;;
  esac
done

# Remove the deployment of the Knative Serving. We do not remove any other resource, like CRDs, to avoid
# the irreversible damage.
kubectl delete KnativeServing knative-serving -n ${NS}
