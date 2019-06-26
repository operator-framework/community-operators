package kube

import (
	"testing"

	"github.com/stakater/Konfigurator/pkg/apis/konfigurator/v1alpha1"
)

func TestCreateConfigMap(t *testing.T) {
	name := "test-configmap"
	configmap := CreateConfigMap(name)

	if configmap.ObjectMeta.Name != name && configmap.TypeMeta.Kind != string(v1alpha1.RenderTargetConfigMap) {
		t.Errorf("Configmap creation failed with name: '%s' and kind: '%s'", name, string(v1alpha1.RenderTargetConfigMap))
	}
}
