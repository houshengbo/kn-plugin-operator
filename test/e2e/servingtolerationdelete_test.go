//go:build servingtolerationremove
// +build servingtolerationremove

/*
Copyright 2022 The Knative Authors

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package e2e

import (
	"testing"

	"knative.dev/kn-plugin-operator/pkg/command/remove"

	"knative.dev/kn-plugin-operator/test/resources"
	"knative.dev/operator/test"
	"knative.dev/operator/test/client"
)

// TestServingTolerationDeletion verifies whether the operator plugin can delete the toleration configurations for Knative Serving
func TestServingTolerationDeletion(t *testing.T) {
	clients := client.Setup(t)

	names := test.ResourceNames{
		KnativeServing:  "knative-serving",
		KnativeEventing: "knative-eventing",
		Namespace:       resources.ServingOperatorNamespace,
	}

	test.CleanupOnInterrupt(func() { test.TearDown(clients, names) })
	defer test.TearDown(clients, names)

	expectedTolerationsFlags := remove.TolerationsFlags{
		Component:  "serving",
		Key:        resources.TestTolerationKey,
		DeployName: "autoscaler",
		Namespace:  resources.ServingOperatorNamespace,
	}
	resources.VerifyKnativeServingTolerationDeletion(t, clients.Operator.KnativeServings(resources.ServingOperatorNamespace),
		expectedTolerationsFlags)
}