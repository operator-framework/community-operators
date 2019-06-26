package konfiguratortemplate

import (
	"fmt"
	"strings"

	"github.com/stakater/Konfigurator/pkg/kube/mounts"

	"github.com/operator-framework/operator-sdk/pkg/sdk"
	"github.com/stakater/Konfigurator/pkg/apis/konfigurator/v1alpha1"
	kContext "github.com/stakater/Konfigurator/pkg/context"
	"github.com/stakater/Konfigurator/pkg/kube"
	"github.com/stakater/Konfigurator/pkg/template"
	"k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
)

const (
	GeneratedByAnnotation = "konfigurator.stakater.com/generated-by"
)

type Controller struct {
	Resource          *v1alpha1.KonfiguratorTemplate
	RenderedTemplates map[string]string
	Namespace         string
	Context           *kContext.Context
}

func NewController(konfiguratorTemplate *v1alpha1.KonfiguratorTemplate, context *kContext.Context) *Controller {
	return &Controller{
		Resource:  konfiguratorTemplate,
		Namespace: konfiguratorTemplate.Namespace,
		Context:   context,
	}
}

func (controller *Controller) getGeneratedResourceName() string {
	return strings.ToLower("konfigurator-" + controller.Resource.Spec.App.Name + "-rendered")
}

func (controller *Controller) RenderTemplates() error {
	templates := controller.Resource.Spec.Templates

	controller.RenderedTemplates = make(map[string]string)

	for fileName, fileData := range templates {
		rendered, err := template.ExecuteString(fileData, controller.Context)
		if err != nil {
			return err
		}
		controller.RenderedTemplates[fileName] = string(rendered)
	}

	return nil
}

func (controller *Controller) CreateResources() error {
	// Generate resource name
	resourceName := controller.getGeneratedResourceName()

	var resourceToCreate metav1.Object

	// Check for render target and create resource
	if controller.Resource.Spec.RenderTarget == v1alpha1.RenderTargetConfigMap {
		resourceToCreate = controller.createConfigMap(resourceName)
	} else {
		resourceToCreate = controller.createSecret(resourceName)
	}

	// Try to create the resource
	if err := sdk.Create(resourceToCreate.(runtime.Object)); err != nil && !errors.IsAlreadyExists(err) {
		return err
	}
	// Update the resource if it already exists
	if err := sdk.Update(resourceToCreate.(runtime.Object)); err != nil {
		return err
	}

	return nil
}

func (controller *Controller) MountVolumes() error {
	return controller.handleVolumes(func(mountManager *mounts.MountManager) error {
		err := mountManager.MountVolumes(controller.Resource.Spec.App.VolumeMounts)
		if err != nil {
			return fmt.Errorf("Failed to assign volume mounts to the specified resource: %v", err)
		}

		return nil
	})
}

func (controller *Controller) UnmountVolumes() error {
	return controller.handleVolumes(func(mountManager *mounts.MountManager) error {
		err := mountManager.UnmountVolumes()
		if err != nil {
			return fmt.Errorf("Failed to unmount volume mounts from the specified resource: %v", err)
		}

		return nil
	})
}

func (controller *Controller) DeleteResources() error {
	switch controller.Resource.Spec.RenderTarget {
	case v1alpha1.RenderTargetConfigMap:
		return controller.deleteConfigMap()
	case v1alpha1.RenderTargetSecret:
		return controller.deleteSecret()
	}
	return fmt.Errorf("Invalid render target in KonfiguratorTemplate %v", controller.Resource.Spec.RenderTarget)
}

func (controller *Controller) handleVolumes(handleVolumesFunc func(*mounts.MountManager) error) error {
	mountManager, err := controller.createMountManager()
	if err != nil {
		return err
	}

	err = handleVolumesFunc(mountManager)
	if err != nil {
		return err
	}

	return sdk.Update(mountManager.Target.(runtime.Object))

}

func (controller *Controller) createMountManager() (*mounts.MountManager, error) {
	app, err := controller.fetchAppObject()
	if err != nil {
		return nil, err
	}

	// Mount volumes to the specified resource
	return mounts.NewManager(
		controller.getGeneratedResourceName(),
		controller.Resource.Spec.RenderTarget,
		app), nil
}

func (controller *Controller) fetchAppObject() (metav1.Object, error) {
	app := kube.CreateObjectFromApp(controller.Resource.Spec.App, controller.Namespace)

	// Check if the app exists
	err := sdk.Get(app.(runtime.Object))
	if err != nil {
		return nil, fmt.Errorf("Failed to get the desired app: %v", err)
	}

	return app, nil
}

func (controller *Controller) createConfigMap(name string) metav1.Object {
	configmap := kube.CreateConfigMap(name)
	controller.prepareResource(configmap)

	// Add rendered data to resource
	configmap.Data = controller.RenderedTemplates

	return configmap
}

func (controller *Controller) createSecret(name string) metav1.Object {
	secret := kube.CreateSecret(name)
	controller.prepareResource(secret)

	// Add rendered data to resource
	secret.Data = kube.ToSecretData(controller.RenderedTemplates)

	return secret
}

func (controller *Controller) deleteConfigMap() error {
	configmap := kube.CreateConfigMap(controller.getGeneratedResourceName())
	controller.prepareResource(configmap)

	return sdk.Delete(configmap)
}

func (controller *Controller) deleteSecret() error {
	secret := kube.CreateSecret(controller.getGeneratedResourceName())
	controller.prepareResource(secret)

	return sdk.Delete(secret)
}

func (controller *Controller) prepareResource(resource metav1.Object) {
	resource.SetNamespace(controller.Namespace)

	resource.SetAnnotations(map[string]string{
		GeneratedByAnnotation: "konfigurator",
	})
}
