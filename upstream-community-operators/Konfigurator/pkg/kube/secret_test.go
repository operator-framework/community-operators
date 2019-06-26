package kube

import (
	"bytes"
	"testing"

	"github.com/stakater/Konfigurator/pkg/apis/konfigurator/v1alpha1"
)

func TestCreateSecret(t *testing.T) {
	name := "test-secret"
	secret := CreateSecret(name)

	if secret.ObjectMeta.Name != name && secret.TypeMeta.Kind != string(v1alpha1.RenderTargetSecret) {
		t.Errorf("Secret creation failed with name: '%s' and kind: '%s'", name, string(v1alpha1.RenderTargetSecret))
	}
}

func TestToSecretData(t *testing.T) {
	key := "test.url"
	value := "www.stakater.com"
	data := map[string]string{key: value}
	byteData := ToSecretData(data)
	byteArray := []byte{100, 51, 100, 51, 76, 110, 78, 48, 89, 87, 116, 104, 100, 71, 86, 121, 76, 109, 78, 118, 98, 81, 61, 61}
	if 0 != bytes.Compare(byteData[key], byteArray) {
		t.Errorf("Conversion to secret data has been failed for key: '%s', value: '%s'", key, value)
	}
}
