// Copyright 2021 The Knative Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package install

import (
	"context"
	"fmt"
	"os"

	"k8s.io/apimachinery/pkg/api/errors"

	"github.com/spf13/cobra"
	"k8s.io/client-go/kubernetes"
	clientset "k8s.io/client-go/kubernetes"
	_ "k8s.io/client-go/plugin/pkg/client/auth/oidc" // from https://github.com/kubernetes/client-go/issues/345
	"k8s.io/client-go/tools/clientcmd"
	"knative.dev/kn-plugin-operator/pkg"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

type installCmdFlags struct {
	Namespace  string
	KubeConfig string
}

var (
	installFlags   installCmdFlags
	selector       []string
	domain         string
	knativeServing = "knative-serving"
	configDomain   = "config-domain"
)

// installCmd represents the install commands for the operation
func NewInstallCommand(p *pkg.OperatorParams) *cobra.Command {
	var installCmd = &cobra.Command{
		Use:   "install",
		Short: "Install Knative Operator or Knative components",
		Example: `
  # Install Knative Serving under the namespace knative-serving
  kn operation install -c serving --namespace knative-serving`,

		Run: func(cmd *cobra.Command, args []string) {
			client, err := p.NewKubeClient()
			if err != nil {
				fmt.Printf("cannot get source cluster kube config, please use --kubeconfig or export environment variable KUBECONFIG to set\n")
				os.Exit(1)
			}

			_, err = client.CoreV1().ConfigMaps("knative-serving").Get(context.TODO(), configDomain, metav1.GetOptions{})
			if err != nil && !errors.IsNotFound(err) {
				fmt.Printf("failed to get ConfigMap %s in namespace %s: %+v", configDomain, knativeServing, err)
			}

			fmt.Printf("The client is OK.")

			if errors.IsNotFound(err) {
				fmt.Printf("The CM is not found.")
			}
		},
	}

	installCmd.Flags().StringVarP(&installFlags.Namespace, "namespace", "n", "", "The namespace of the Knative Operator or the Knative component")
	return installCmd
}

func getClients(kubeConfig, namespace string) (*kubernetes.Clientset, error) {
	cfg, err := clientcmd.BuildConfigFromFlags("", kubeConfig)
	if err != nil {
		return nil, err
	}
	clientSet, err := clientset.NewForConfig(cfg)
	if err != nil {
		return nil, err
	}
	return clientSet, nil
}
