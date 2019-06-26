package v1alpha1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

type Phase string

const (
	PhaseInitial           Phase = ""
	PhaseRendering         Phase = "Rendering"
	PhaseCreatingConfigMap Phase = "CreatingConfigMap"
	PhaseRendered          Phase = "Rendered"
)

type RenderTarget string

const (
	RenderTargetConfigMap RenderTarget = "ConfigMap"
	RenderTargetSecret    RenderTarget = "Secret"
)

type AppKind string

const (
	AppKindDeployment  AppKind = "Deployment"
	AppKindDaemonSet   AppKind = "DaemonSet"
	AppKindStatefulSet AppKind = "StatefulSet"
)

// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

type KonfiguratorTemplateList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata"`
	Items           []KonfiguratorTemplate `json:"items"`
}

// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

type KonfiguratorTemplate struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata"`
	Spec              KonfiguratorTemplateSpec   `json:"spec"`
	Status            KonfiguratorTemplateStatus `json:"status,omitempty"`
}

type KonfiguratorTemplateSpec struct {
	RenderTarget RenderTarget      `json:"renderTarget"`
	Templates    map[string]string `json:"templates"`
	App          App               `json:"app"`
}

type App struct {
	Name         string        `json:"name"`
	Kind         AppKind       `json:"kind"`
	VolumeMounts []VolumeMount `json:"volumeMounts"`
}

type VolumeMount struct {
	MountPath string `json:"mountPath"`
	Container string `json:"container"`
}

type KonfiguratorTemplateStatus struct {
	CurrentPhase Phase `json:"currentPhase"`
}
