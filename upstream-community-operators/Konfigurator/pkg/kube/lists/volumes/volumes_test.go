package volumes

import (
	"testing"

	"github.com/stakater/Konfigurator/pkg/kube/testutil"
	corev1 "k8s.io/api/core/v1"
)

func TestGetFromObject(t *testing.T) {
	name := "test"
	deployment := testutil.GetDeployment(name)
	volumes := GetFromObject(deployment)
	volumesExist := verifyVolumesExist(volumes, name)
	if !volumesExist {
		t.Errorf("No volume found in deployment by name '%s'", name)
	}
}

func TestGetDeploymentVolumes(t *testing.T) {
	name := "test"
	deployment := testutil.GetDeployment(name)
	volumes := GetDeploymentVolumes(deployment)
	volumesExist := verifyVolumesExist(volumes, name)
	if !volumesExist {
		t.Errorf("No volume found in deployment by name '%s'", name)
	}
}

func TestGetDaemonSetVolumes(t *testing.T) {
	name := "test"
	daemonset := testutil.GetDaemonSet(name)
	volumes := GetDaemonSetVolumes(daemonset)
	volumesExist := verifyVolumesExist(volumes, name)
	if !volumesExist {
		t.Errorf("No volume found in daemonset by name '%s'", name)
	}
}

func TestGetStatefulSetVolumes(t *testing.T) {
	name := "test"
	statefulset := testutil.GetStatefulSet(name)
	volumes := GetStatefulSetVolumes(statefulset)
	volumesExist := verifyVolumesExist(volumes, name)
	if !volumesExist {
		t.Errorf("No volume found in statefulset by name '%s'", name)
	}
}

func verifyVolumesExist(volumes []corev1.Volume, name string) bool {
	for _, volume := range volumes {
		if volume.Name == name {
			return true
		}
	}
	return false
}
