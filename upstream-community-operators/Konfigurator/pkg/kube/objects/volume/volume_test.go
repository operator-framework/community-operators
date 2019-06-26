package volume

import (
	"testing"
)

func TestCreateFromConfigMap(t *testing.T) {
	volumeName := "test-volume"
	configmapName := "test-configmap"
	volume := CreateFromConfigMap(volumeName, configmapName)

	if volume.Name != volumeName && volume.VolumeSource.ConfigMap.Name != configmapName {
		t.Errorf("Volume from configmap creation failed, volume name: '%s', configmap name: '%s'", volumeName, configmapName)
	}
}

func TestCreateFromSecret(t *testing.T) {
	volumeName := "test-volume"
	secretName := "test-secret"
	volume := CreateFromSecret(volumeName, secretName)

	if volume.Name != volumeName && volume.VolumeSource.ConfigMap.Name != secretName {
		t.Errorf("Volume from secret creation failed, volume name: '%s',  secret name: '%s'", volumeName, secretName)
	}
}
