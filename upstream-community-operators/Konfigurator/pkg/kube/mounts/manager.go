package mounts

import (
	"fmt"

	"github.com/stakater/Konfigurator/pkg/apis/konfigurator/v1alpha1"
	"github.com/stakater/Konfigurator/pkg/kube/lists/containers"
	"github.com/stakater/Konfigurator/pkg/kube/lists/volumes"
	objectVolume "github.com/stakater/Konfigurator/pkg/kube/objects/volume"
	kubereflect "github.com/stakater/Konfigurator/pkg/kube/reflect"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

const (
	VolumesFieldPath    = "Spec.Template.Spec.Volumes"
	ContainersFieldPath = "Spec.Template.Spec.Containers"
)

type MountManager struct {
	resourceToMount string
	resourceKind    v1alpha1.RenderTarget
	Target          metav1.Object
}

func NewManager(resourceToMount string, resourceKind v1alpha1.RenderTarget, target metav1.Object) *MountManager {
	return &MountManager{
		resourceToMount: resourceToMount,
		resourceKind:    resourceKind,
		Target:          target,
	}
}

func (mm *MountManager) MountVolumes(volumeMountConfigs []v1alpha1.VolumeMount) error {
	// Add volume first so that we can mount it in containers
	err := mm.addVolumeIfNotExists()
	if err != nil {
		return err
	}

	containersToUpdate := make([]corev1.Container, 0, len(volumeMountConfigs))

	for _, volumeMountConfig := range volumeMountConfigs {
		container, err := mm.findContainerWithName(volumeMountConfig.Container)
		if err != nil {
			return err
		}

		mm.addMountToContainer(container, volumeMountConfig.MountPath)
		containersToUpdate = append(containersToUpdate, *container)
	}

	return mm.updateContainersInTarget(containersToUpdate)
}

func (mm *MountManager) UnmountVolumes() error {
	if err := mm.removeVolumeMounts(); err != nil {
		return err
	}

	return mm.removeVolume()

}

func (mm *MountManager) removeVolume() error {
	volumes := volumes.GetFromObject(mm.Target)
	
	if !mm.volumeExists(volumes) {
		return fmt.Errorf("Could not find the desired volume mount on the app resource")
	}

	desiredVolumes := volumes[:0]
	for _, volume := range volumes {
		if volume.Name != mm.resourceToMount {
			desiredVolumes = append(desiredVolumes, volume)
		}
	}

	return kubereflect.AssignValueTo(mm.Target, VolumesFieldPath, desiredVolumes)
}

func (mm *MountManager) removeVolumeMounts() error {
	containers := containers.GetFromObject(mm.Target)
	for i := 0; i < len(containers); i++ {
		desiredVolumeMounts := containers[i].VolumeMounts[:0]

		for _, volumeMount := range containers[i].VolumeMounts {
			if mm.resourceToMount != volumeMount.Name {
				desiredVolumeMounts = append(desiredVolumeMounts, volumeMount)
			}
		}

		containers[i].VolumeMounts = desiredVolumeMounts
	}

	return kubereflect.AssignValueTo(mm.Target, ContainersFieldPath, containers)
}

func (mm *MountManager) updateContainersInTarget(containersToUpdate []corev1.Container) error {
	appContainers := containers.GetFromObject(mm.Target)

	containers.ForEach(containersToUpdate, func(cIndex int, containerToUpdate corev1.Container) {
		containers.ForEach(appContainers, func(aIndex int, appContainer corev1.Container) {
			if containerToUpdate.Name == appContainer.Name {
				appContainers[aIndex] = containersToUpdate[cIndex]
			}
		})
	})

	return kubereflect.AssignValueTo(mm.Target, ContainersFieldPath, appContainers)
}

func (mm *MountManager) addMountToContainer(container *corev1.Container, mountPath string) {
	if container.VolumeMounts == nil {
		container.VolumeMounts = []corev1.VolumeMount{}
	}

	// Add if the mount doesn't exist
	if !mm.volumeMountExists(container.VolumeMounts) {
		volumeMount := corev1.VolumeMount{
			Name:      mm.resourceToMount,
			MountPath: mountPath,
		}
		container.VolumeMounts = append(container.VolumeMounts, volumeMount)
	}
}

func (mm *MountManager) volumeMountExists(volumeMounts []corev1.VolumeMount) bool {
	for _, volumeMount := range volumeMounts {
		if volumeMount.Name == mm.resourceToMount {
			return true
		}
	}
	return false
}

func (mm *MountManager) addVolumeIfNotExists() error {
	volumes := volumes.GetFromObject(mm.Target)

	if !mm.volumeExists(volumes) {
		volume, err := mm.createVolume()
		if err != nil {
			return err
		}
		volumes = append(volumes, *volume)
	}

	return kubereflect.AssignValueTo(mm.Target, VolumesFieldPath, volumes)
}

func (mm *MountManager) volumeExists(volumes []corev1.Volume) bool {
	for _, volume := range volumes {
		if volume.Name == mm.resourceToMount {
			return true
		}
	}
	return false
}

func (mm *MountManager) createVolume() (*corev1.Volume, error) {
	switch mm.resourceKind {
	case v1alpha1.RenderTargetSecret:
		return objectVolume.CreateFromSecret(mm.resourceToMount, mm.resourceToMount), nil
	case v1alpha1.RenderTargetConfigMap:
		return objectVolume.CreateFromConfigMap(mm.resourceToMount, mm.resourceToMount), nil
	}

	return nil, fmt.Errorf("Invalid resource kind: %v", mm.resourceKind)
}

func (mm *MountManager) findContainerWithName(name string) (*corev1.Container, error) {
	for _, container := range containers.GetFromObject(mm.Target) {
		if container.Name == name {
			return &container, nil
		}
	}
	return nil, fmt.Errorf("Cannot find container with name: %s", name)
}
