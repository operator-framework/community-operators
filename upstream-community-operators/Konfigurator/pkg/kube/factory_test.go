package kube

import (
	"testing"

	"github.com/stakater/Konfigurator/pkg/apis/konfigurator/v1alpha1"
	"github.com/stakater/Konfigurator/pkg/kube/testutil"
	"k8s.io/api/apps/v1"
)

func TestCreateDeploymentFromApp(t *testing.T) {
	deployment := CreateObjectFromApp(testutil.GetApp(v1alpha1.AppKindDeployment), testutil.Namespace)
	name := "testapp"

	if deployment.(*v1.Deployment).TypeMeta.Kind != string(v1alpha1.AppKindDeployment) &&
		deployment.GetName() != name &&
		deployment.GetNamespace() != testutil.Namespace {
		t.Errorf("Deployment creation failed with name: '%s' in namespace: '%s'", name, testutil.Namespace)
	}
}

func TestCreateDaemonSetFromApp(t *testing.T) {
	daemonset := CreateObjectFromApp(testutil.GetApp(v1alpha1.AppKindDaemonSet), testutil.Namespace)
	name := "testapp"

	if daemonset.(*v1.DaemonSet).TypeMeta.Kind != string(v1alpha1.AppKindDaemonSet) &&
		daemonset.GetName() != name &&
		daemonset.GetNamespace() != testutil.Namespace {
		t.Errorf("DaemonSet creation failed with name: '%s' in namespace: '%s'", name, testutil.Namespace)
	}
}

func TestCreateStatefulSetFromApp(t *testing.T) {
	statefulset := CreateObjectFromApp(testutil.GetApp(v1alpha1.AppKindStatefulSet), testutil.Namespace)
	name := "testapp"

	if statefulset.(*v1.StatefulSet).TypeMeta.Kind != string(v1alpha1.AppKindStatefulSet) &&
		statefulset.GetName() != name &&
		statefulset.GetNamespace() != testutil.Namespace {
		t.Errorf("StatefulSet creation failed with name: '%s' in namespace: '%s'", name, testutil.Namespace)
	}
}
