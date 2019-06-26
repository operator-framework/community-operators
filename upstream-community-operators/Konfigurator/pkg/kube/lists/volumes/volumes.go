package volumes

import (
	"github.com/stakater/Konfigurator/pkg/apis/konfigurator/v1alpha1"
	"k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
)

type GetVolumesFunc func(interface{}) []corev1.Volume
type VolumeFunc func(int, corev1.Volume)

var objectKindToVolumesMap = map[string]GetVolumesFunc{
	string(v1alpha1.AppKindDeployment):  GetDeploymentVolumes,
	string(v1alpha1.AppKindDaemonSet):   GetDaemonSetVolumes,
	string(v1alpha1.AppKindStatefulSet): GetStatefulSetVolumes,
}

func GetFromObject(target metav1.Object) []corev1.Volume {
	return objectKindToVolumesMap[target.(runtime.Object).GetObjectKind().GroupVersionKind().Kind](target)
}

func GetDeploymentVolumes(target interface{}) []corev1.Volume {
	return target.(*v1.Deployment).Spec.Template.Spec.Volumes
}

func GetDaemonSetVolumes(target interface{}) []corev1.Volume {
	return target.(*v1.DaemonSet).Spec.Template.Spec.Volumes
}

func GetStatefulSetVolumes(target interface{}) []corev1.Volume {
	return target.(*v1.StatefulSet).Spec.Template.Spec.Volumes
}

func ForEach(volumes []corev1.Volume, volumeFunc VolumeFunc) {
	for index, volume := range volumes {
		volumeFunc(index, volume)
	}
}
