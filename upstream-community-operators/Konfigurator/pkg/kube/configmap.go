package kube

import (
	"github.com/stakater/Konfigurator/pkg/apis/konfigurator/v1alpha1"
	"k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

func CreateConfigMap(name string) *v1.ConfigMap {
	return &v1.ConfigMap{
		ObjectMeta: metav1.ObjectMeta{
			Name: name,
		},
		TypeMeta: metav1.TypeMeta{
			Kind:       string(v1alpha1.RenderTargetConfigMap),
			APIVersion: "v1",
		},
	}
}
