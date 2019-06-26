package pod

import (
	"fmt"

	kContext "github.com/stakater/Konfigurator/pkg/context"
	"k8s.io/api/core/v1"
)

type Controller struct {
	Resource *v1.Pod
	Context  *kContext.Context
}

func NewController(pod *v1.Pod, context *kContext.Context) *Controller {
	return &Controller{
		Resource: pod,
		Context:  context,
	}
}

func (controller *Controller) RemoveFromContext() error {
	for index, pod := range controller.Context.Pods {
		if pod.Name == controller.Resource.Name && pod.Namespace == controller.Resource.Namespace {
			// Remove the resource
			controller.Context.Pods = append(controller.Context.Pods[:index], controller.Context.Pods[index+1:]...)
			return nil
		}
	}
	return fmt.Errorf("Could not find pod resource %v in current context", controller.Resource.Name)
}

func (controller *Controller) AddToContext() error {
	for index, pod := range controller.Context.Pods {
		if pod.Name == controller.Resource.Name && pod.Namespace == controller.Resource.Namespace {
			// Update the resource
			controller.Context.Pods[index] = *controller.Resource
			return nil
		}
	}
	controller.Context.Pods = append(controller.Context.Pods, *controller.Resource)
	return nil
}
