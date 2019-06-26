package mounts

import (
	"strings"
	"testing"

	"github.com/stakater/Konfigurator/pkg/apis/konfigurator/v1alpha1"
	"github.com/stakater/Konfigurator/pkg/kube/lists/containers"
	"github.com/stakater/Konfigurator/pkg/kube/lists/volumes"
	"github.com/stakater/Konfigurator/pkg/kube/testutil"
)

func TestMountVolumes(t *testing.T) {
	mountManager := getNewManager()
	err := mountManager.MountVolumes(testutil.GetVolumeMounts())
	if err != nil {
		t.Errorf("Volume mounting failed with error: %v", err)
	}

	volumeFound := verifyVolumeExist(mountManager)
	if !volumeFound {
		t.Errorf("No volume found in deployment by name '%s'", mountManager.resourceToMount)
	}

	volumeMounted := verifyVolumeMounted(mountManager)

	if !volumeMounted {
		t.Errorf("Volume '%s' mounting failed in deployment", mountManager.resourceToMount)
	}

}

func TestUnMountVolumes(t *testing.T) {
	mountManager := getNewManager()
	err := mountManager.MountVolumes(testutil.GetVolumeMounts())
	if err != nil {
		t.Errorf("Volume mounting failed with error: %v", err)
	}

	volumeFound := verifyVolumeExist(mountManager)
	if !volumeFound {
		t.Errorf("No volume found in deployment by name '%s'", mountManager.resourceToMount)
	}

	volumeMounted := verifyVolumeMounted(mountManager)

	if !volumeMounted {
		t.Errorf("Volume '%s' mounting failed in deployment", mountManager.resourceToMount)
	}

	err = mountManager.UnmountVolumes()
	if err != nil {
		t.Errorf("Volume unmounting failed with error: %v", err)
	}

	volumeFound = verifyVolumeFound(mountManager)
	if volumeFound {
		t.Errorf("Volume did not remove in deployment by name '%s'", mountManager.resourceToMount)
	}

	volumeMounted = verifyVolumeMounted(mountManager)

	if volumeMounted {
		t.Errorf("Volume '%s' unmounting failed in deployment", mountManager.resourceToMount)
	}

}

func TestRemoveVolume(t *testing.T) {
	mountManager := getNewManager()
	err := mountManager.MountVolumes(testutil.GetVolumeMounts())
	if err != nil {
		t.Errorf("Volume mounting failed with error: %v", err)
	}

	volumeFound := verifyVolumeExist(mountManager)
	if !volumeFound {
		t.Errorf("No volume found in deployment by name '%s'", mountManager.resourceToMount)
	}

	err = mountManager.removeVolume()
	if err != nil {
		t.Errorf("Volume mounting failed with error: %v", err)
	}

	volumeFound = verifyVolumeFound(mountManager)
	if volumeFound {
		t.Errorf("Volume did not remove in deployment by name '%s'", mountManager.resourceToMount)
	}
}

func TestRemoveVolumeMounts(t *testing.T) {
	mountManager := getNewManager()
	err := mountManager.MountVolumes(testutil.GetVolumeMounts())
	if err != nil {
		t.Errorf("Volume mounting failed with error: %v", err)
	}

	volumeMounted := verifyVolumeMounted(mountManager)

	if !volumeMounted {
		t.Errorf("Volume '%s' mounting failed in deployment", mountManager.resourceToMount)
	}

	err = mountManager.removeVolumeMounts()
	if err != nil {
		t.Errorf("Removing Volume mounts failed with error: %v", err)
	}

	volumeMounted = verifyVolumeMounted(mountManager)

	if volumeMounted {
		t.Errorf("Volume '%s' unmounting failed in deployment", mountManager.resourceToMount)
	}
}

func getNewManager() *MountManager {
	app := testutil.GetDeployment("test")
	name := strings.ToLower("konfigurator-" + testutil.GetApp(v1alpha1.AppKindDeployment).Name + "-rendered")
	return NewManager(
		name,
		testutil.GetKonfiguratorTemplateSpec().RenderTarget,
		app)
}

func verifyVolumeExist(mountManager *MountManager) bool {
	volumes := volumes.GetFromObject(mountManager.Target)

	if !mountManager.volumeExists(volumes) {
		return false
	}

	return verifyVolumeFound(mountManager)
}

func verifyVolumeMounted(mountManager *MountManager) bool {
	containers := containers.GetFromObject(mountManager.Target)
	for i := 0; i < len(containers); i++ {
		for _, volumeMount := range containers[i].VolumeMounts {
			if mountManager.resourceToMount == volumeMount.Name {
				return true
			}
		}
	}
	return false
}

func verifyVolumeFound(mountManager *MountManager) bool {
	volumes := volumes.GetFromObject(mountManager.Target)

	volumeFound := false
	for _, volume := range volumes {
		if volume.Name == mountManager.resourceToMount {
			volumeFound = true
		}
	}

	return volumeFound
}
