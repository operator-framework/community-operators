package service

import (
	"fmt"

	kContext "github.com/stakater/Konfigurator/pkg/context"
	"k8s.io/api/core/v1"
)

type Controller struct {
	Resource *v1.Service
	Context  *kContext.Context
}

func NewController(service *v1.Service, context *kContext.Context) *Controller {
	return &Controller{
		Resource: service,
		Context:  context,
	}
}

func (controller *Controller) RemoveFromContext() error {
	for index, service := range controller.Context.Services {
		if service.Name == controller.Resource.Name && service.Namespace == controller.Resource.Namespace {
			// Remove the resource
			controller.Context.Services = append(controller.Context.Services[:index], controller.Context.Services[index+1:]...)
			return nil
		}
	}
	return fmt.Errorf("Could not find pod resource %v in current context", controller.Resource.Name)
}

func (controller *Controller) AddToContext() error {
	for index, service := range controller.Context.Services {
		if service.Name == controller.Resource.Name && service.Namespace == controller.Resource.Namespace {
			// Update the resource
			controller.Context.Services[index] = *controller.Resource
			return nil
		}
	}
	controller.Context.Services = append(controller.Context.Services, *controller.Resource)
	return nil
}
