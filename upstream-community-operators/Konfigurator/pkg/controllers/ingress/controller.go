package ingress

import (
	"fmt"

	kContext "github.com/stakater/Konfigurator/pkg/context"
	"k8s.io/api/extensions/v1beta1"
)

type Controller struct {
	Resource *v1beta1.Ingress
	Context  *kContext.Context
}

func NewController(ingress *v1beta1.Ingress, context *kContext.Context) *Controller {
	return &Controller{
		Resource: ingress,
		Context:  context,
	}
}

func (controller *Controller) RemoveFromContext() error {
	for index, ingress := range controller.Context.Ingresses {
		if ingress.Name == controller.Resource.Name && ingress.Namespace == controller.Resource.Namespace {
			// Remove the resource
			controller.Context.Ingresses = append(controller.Context.Ingresses[:index], controller.Context.Ingresses[index+1:]...)
			return nil
		}
	}
	return fmt.Errorf("Could not find ingress resource %v in current context", controller.Resource.Name)
}

func (controller *Controller) AddToContext() error {
	for index, ingress := range controller.Context.Ingresses {
		if ingress.Name == controller.Resource.Name && ingress.Namespace == controller.Resource.Namespace {
			// Update the resource
			controller.Context.Ingresses[index] = *controller.Resource
			return nil
		}
	}
	controller.Context.Ingresses = append(controller.Context.Ingresses, *controller.Resource)
	return nil
}
