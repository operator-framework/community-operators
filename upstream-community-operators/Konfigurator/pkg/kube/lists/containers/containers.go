package containers

import (
	"github.com/stakater/Konfigurator/pkg/apis/konfigurator/v1alpha1"
	"k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
)

type GetContainersFunc func(interface{}) []corev1.Container
type ContainerFunc func(int, corev1.Container)

var objectKindToContainersMap = map[string]GetContainersFunc{
	string(v1alpha1.AppKindDeployment):  GetDeploymentContainers,
	string(v1alpha1.AppKindDaemonSet):   GetDaemonSetContainers,
	string(v1alpha1.AppKindStatefulSet): GetStatefulSetContainers,
}

func GetFromObject(target metav1.Object) []corev1.Container {
	return objectKindToContainersMap[target.(runtime.Object).GetObjectKind().GroupVersionKind().Kind](target)
}

func GetDeploymentContainers(target interface{}) []corev1.Container {
	return target.(*v1.Deployment).Spec.Template.Spec.Containers
}

func GetDaemonSetContainers(target interface{}) []corev1.Container {
	return target.(*v1.DaemonSet).Spec.Template.Spec.Containers
}

func GetStatefulSetContainers(target interface{}) []corev1.Container {
	return target.(*v1.StatefulSet).Spec.Template.Spec.Containers
}

func ForEach(containers []corev1.Container, containerFunc ContainerFunc) {
	for index, container := range containers {
		containerFunc(index, container)
	}
}
