package kube

import (
	"github.com/stakater/Konfigurator/pkg/apis/konfigurator/v1alpha1"
	"k8s.io/api/apps/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

var appKindToObjectMap = map[v1alpha1.AppKind]metav1.Object{
	v1alpha1.AppKindDeployment: &v1.Deployment{
		TypeMeta: metav1.TypeMeta{
			Kind:       string(v1alpha1.AppKindDeployment),
			APIVersion: "apps/v1beta1",
		},
	},
	v1alpha1.AppKindDaemonSet: &v1.DaemonSet{
		TypeMeta: metav1.TypeMeta{
			Kind:       string(v1alpha1.AppKindDaemonSet),
			APIVersion: "extensions/v1beta1",
		},
	},
	v1alpha1.AppKindStatefulSet: &v1.StatefulSet{
		TypeMeta: metav1.TypeMeta{
			Kind:       string(v1alpha1.AppKindStatefulSet),
			APIVersion: "apps/v1beta1",
		},
	},
}

func CreateObjectFromApp(appConfig v1alpha1.App, namespace string) metav1.Object {
	appObject := appKindToObjectMap[appConfig.Kind]

	appObject.SetName(appConfig.Name)
	appObject.SetNamespace(namespace)

	return appObject
}
