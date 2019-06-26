package volume

import corev1 "k8s.io/api/core/v1"

func CreateFromConfigMap(volumeName string, configMapName string) *corev1.Volume {
	return &corev1.Volume{
		VolumeSource: corev1.VolumeSource{
			ConfigMap: &corev1.ConfigMapVolumeSource{
				LocalObjectReference: corev1.LocalObjectReference{
					Name: configMapName,
				},
			},
		},
		Name: volumeName,
	}
}

func CreateFromSecret(volumeName string, secretName string) *corev1.Volume {
	return &corev1.Volume{
		VolumeSource: corev1.VolumeSource{
			Secret: &corev1.SecretVolumeSource{
				SecretName: secretName,
			},
		},
		Name: volumeName,
	}
}
