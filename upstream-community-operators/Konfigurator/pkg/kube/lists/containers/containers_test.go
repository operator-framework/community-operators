package containers

import (
	"testing"

	"github.com/stakater/Konfigurator/pkg/kube/testutil"
	corev1 "k8s.io/api/core/v1"
)

func TestGetFromObject(t *testing.T) {
	name := "test"
	deployment := testutil.GetDeployment(name)
	containers := GetFromObject(deployment)
	containersExist := verifyContainerExist(containers, name)
	if !containersExist {
		t.Errorf("No container found in deployment by name '%s'", name)
	}
}

func TestGetDeploymentContainers(t *testing.T) {
	name := "test"
	deployment := testutil.GetDeployment(name)
	containers := GetDeploymentContainers(deployment)
	containersExist := verifyContainerExist(containers, name)
	if !containersExist {
		t.Errorf("No container found in deployment by name '%s'", name)
	}
}

func TestGetDaemonSetContainers(t *testing.T) {
	name := "test"
	daemonset := testutil.GetDaemonSet(name)
	containers := GetDaemonSetContainers(daemonset)
	containersExist := verifyContainerExist(containers, name)
	if !containersExist {
		t.Errorf("No container found in daemonset by name '%s'", name)
	}
}

func TestGetStatefulSetContainers(t *testing.T) {
	name := "test"
	statefulset := testutil.GetStatefulSet(name)
	containers := GetStatefulSetContainers(statefulset)
	containersExist := verifyContainerExist(containers, name)
	if !containersExist {
		t.Errorf("No container found in statefulset by name '%s'", name)
	}
}

func verifyContainerExist(containers []corev1.Container, name string) bool {
	for _, container := range containers {
		if container.Name == name {
			return true
		}
	}
	return false
}
