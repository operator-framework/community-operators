package main

import (
	"context"
	"os"
	"runtime"

	sdk "github.com/operator-framework/operator-sdk/pkg/sdk"
	sdkVersion "github.com/operator-framework/operator-sdk/version"
	kContext "github.com/stakater/Konfigurator/pkg/context"
	stub "github.com/stakater/Konfigurator/pkg/stub"

	"github.com/sirupsen/logrus"
)

func printVersion() {
	logrus.Infof("Go Version: %s", runtime.Version())
	logrus.Infof("Go OS/Arch: %s/%s", runtime.GOOS, runtime.GOARCH)
	logrus.Infof("operator-sdk Version: %v", sdkVersion.Version)
}

func main() {
	printVersion()

	sdk.ExposeMetricsPort()

	watchKonfiguratorTemplate()
	watchPods()
	watchServices()
	watchIngresses()

	var resourceContext kContext.Context

	sdk.Handle(stub.NewHandler(&resourceContext))
	sdk.Run(context.TODO())
}

func watchKonfiguratorTemplate() {
	namespace := getWatchNamespace()

	watch("konfigurator.stakater.com/v1alpha1", "KonfiguratorTemplate", namespace, 15)
}

func getWatchNamespace() string {
	namespace := os.Getenv("WATCH_NAMESPACE")
	if namespace == "" {
		logrus.Infof("WATCH_NAMESPACE is empty, so looking in all namespaces")
	}
	return namespace
}

func watchPods() {
	watch("v1", "Pod", "", 0)
}

func watchServices() {
	watch("v1", "Service", "", 0)
}

func watchIngresses() {
	watch("extensions/v1beta1", "Ingress", "", 0)
}

func watch(resource string, kind string, namespace string, resyncPeriod int) {
	logrus.Infof("Watching %s, %s, %d in namespace %s", resource, kind, resyncPeriod, namespace)
	sdk.Watch(resource, kind, namespace, resyncPeriod)
}
