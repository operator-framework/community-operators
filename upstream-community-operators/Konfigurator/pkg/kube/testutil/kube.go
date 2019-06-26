package testutil

import (
	"github.com/stakater/Konfigurator/pkg/apis/konfigurator/v1alpha1"
	appsv1 "k8s.io/api/apps/v1"
	"k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

const (
	//Namespace is a test namespace for unit tests
	Namespace = "test-konfig"
)

// GetDeployment provides deployment for testing
func GetDeployment(deploymentName string) *appsv1.Deployment {
	replicaset := int32(1)
	return &appsv1.Deployment{
		TypeMeta: metav1.TypeMeta{
			Kind:       string(v1alpha1.AppKindDeployment),
			APIVersion: "apps/v1beta1",
		},
		ObjectMeta: metav1.ObjectMeta{
			Name:      deploymentName,
			Namespace: Namespace,
			Labels:    map[string]string{"firstLabel": "temp"},
		},
		Spec: appsv1.DeploymentSpec{
			Replicas: &replicaset,
			Strategy: appsv1.DeploymentStrategy{
				Type: appsv1.RollingUpdateDeploymentStrategyType,
			},
			Template: v1.PodTemplateSpec{
				ObjectMeta: metav1.ObjectMeta{
					Labels: map[string]string{"secondLabel": "temp"},
				},
				Spec: v1.PodSpec{
					Containers: []v1.Container{
						{
							Image: "tutum/hello-world",
							Name:  deploymentName,
							Env: []v1.EnvVar{
								{
									Name:  "BUCKET_NAME",
									Value: "test",
								},
							},
						},
					},
					Volumes: []v1.Volume{
						{
							VolumeSource: v1.VolumeSource{
								ConfigMap: &v1.ConfigMapVolumeSource{
									LocalObjectReference: v1.LocalObjectReference{
										Name: deploymentName,
									},
								},
							},
							Name: deploymentName,
						},
					},
				},
			},
		},
	}
}

// GetDaemonSet provides daemonset for testing
func GetDaemonSet(daemonsetName string) *appsv1.DaemonSet {
	return &appsv1.DaemonSet{
		TypeMeta: metav1.TypeMeta{
			Kind:       string(v1alpha1.AppKindDaemonSet),
			APIVersion: "apps/v1beta1",
		},
		ObjectMeta: metav1.ObjectMeta{
			Name:      daemonsetName,
			Namespace: Namespace,
			Labels:    map[string]string{"firstLabel": "temp"},
		},
		Spec: appsv1.DaemonSetSpec{
			UpdateStrategy: appsv1.DaemonSetUpdateStrategy{
				Type: appsv1.RollingUpdateDaemonSetStrategyType,
			},
			Template: v1.PodTemplateSpec{
				ObjectMeta: metav1.ObjectMeta{
					Labels: map[string]string{"secondLabel": "temp"},
				},
				Spec: v1.PodSpec{
					Containers: []v1.Container{
						{
							Image: "tutum/hello-world",
							Name:  daemonsetName,
							Env: []v1.EnvVar{
								{
									Name:  "BUCKET_NAME",
									Value: "test",
								},
							},
						},
					},
					Volumes: []v1.Volume{
						{
							VolumeSource: v1.VolumeSource{
								ConfigMap: &v1.ConfigMapVolumeSource{
									LocalObjectReference: v1.LocalObjectReference{
										Name: daemonsetName,
									},
								},
							},
							Name: daemonsetName,
						},
					},
				},
			},
		},
	}
}

// GetStatefulSet provides statefulset for testing
func GetStatefulSet(statefulsetName string) *appsv1.StatefulSet {
	return &appsv1.StatefulSet{
		TypeMeta: metav1.TypeMeta{
			Kind:       string(v1alpha1.AppKindStatefulSet),
			APIVersion: "apps/v1beta1",
		},
		ObjectMeta: metav1.ObjectMeta{
			Name:      statefulsetName,
			Namespace: Namespace,
			Labels:    map[string]string{"firstLabel": "temp"},
		},
		Spec: appsv1.StatefulSetSpec{
			UpdateStrategy: appsv1.StatefulSetUpdateStrategy{
				Type: appsv1.RollingUpdateStatefulSetStrategyType,
			},
			Template: v1.PodTemplateSpec{
				ObjectMeta: metav1.ObjectMeta{
					Labels: map[string]string{"secondLabel": "temp"},
				},
				Spec: v1.PodSpec{
					Containers: []v1.Container{
						{
							Image: "tutum/hello-world",
							Name:  statefulsetName,
							Env: []v1.EnvVar{
								{
									Name:  "BUCKET_NAME",
									Value: "test",
								},
							},
						},
					},
					Volumes: []v1.Volume{
						{
							VolumeSource: v1.VolumeSource{
								ConfigMap: &v1.ConfigMapVolumeSource{
									LocalObjectReference: v1.LocalObjectReference{
										Name: statefulsetName,
									},
								},
							},
							Name: statefulsetName,
						},
					},
				},
			},
		},
	}
}

func GetKonfiguratorTemplateStatus() v1alpha1.KonfiguratorTemplateStatus {
	return v1alpha1.KonfiguratorTemplateStatus{
		CurrentPhase: v1alpha1.PhaseInitial,
	}
}

func GetKonfiguratorTemplateSpec() v1alpha1.KonfiguratorTemplateSpec {
	return v1alpha1.KonfiguratorTemplateSpec{
		RenderTarget: "ConfigMap",
		App:          GetApp(v1alpha1.AppKindDeployment),
	}
}

func GetApp(kind v1alpha1.AppKind) v1alpha1.App {
	return v1alpha1.App{
		Name:         "testapp",
		Kind:         kind,
		VolumeMounts: GetVolumeMounts(),
	}
}

func GetVolumeMounts() []v1alpha1.VolumeMount {
	return []v1alpha1.VolumeMount{GetVolumeMount()}
}

func GetVolumeMount() v1alpha1.VolumeMount {
	return v1alpha1.VolumeMount{
		MountPath: "etc/kfg",
		Container: "test",
	}
}
