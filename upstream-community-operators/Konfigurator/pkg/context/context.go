package context

import (
	"k8s.io/api/core/v1"
	"k8s.io/api/extensions/v1beta1"
)

type Context struct {
	Pods      []v1.Pod
	Services  []v1.Service
	Ingresses []v1beta1.Ingress
}
