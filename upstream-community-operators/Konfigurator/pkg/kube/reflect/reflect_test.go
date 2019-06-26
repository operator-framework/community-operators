package reflect

import (
	"testing"

	"github.com/stakater/Konfigurator/pkg/kube/lists/volumes"
	objectVolume "github.com/stakater/Konfigurator/pkg/kube/objects/volume"
	"github.com/stakater/Konfigurator/pkg/kube/testutil"
)

func TestAssignValueTo(t *testing.T) {
	deploymentName := "test-deployment"
	volumeName := "secret-volume"
	secretName := "test-secret"
	deployment := testutil.GetDeployment(deploymentName)
	volume := objectVolume.CreateFromSecret(volumeName, secretName)
	oldVolumes := volumes.GetFromObject(deployment)
	oldVolumes = append(oldVolumes, *volume)
	err := AssignValueTo(deployment, "Spec.Template.Spec.Volumes", oldVolumes)
	if err != nil {
		t.Errorf("Assigning value to target failed with err %v", err)
	}

	updatedVolumes := volumes.GetFromObject(deployment)

	volumeFound := false
	for _, updatedVolume := range updatedVolumes {
		if updatedVolume.Name == volumeName && updatedVolume.VolumeSource.Secret.SecretName == secretName {
			volumeFound = true
			break
		}
	}

	if !volumeFound {
		t.Errorf("No volume found with name '%s'", volumeName)
	}
}
