# Konfigurator vs Konfd

Konfigurator and Konfd basically share the same idea but Konfd has its limitations which you can see from the table below:

| Konfigurator | Konfd |
|--------------|-------|
| Konfigurator has a custom resource which you have to use for your templates | Konfd uses a `ConfigMap` with a set of annotations that it needs to identify the templates |
| Konfigurator supports multiple templates in a single resource | Konfd only allows 1 template per ConfigMap. So if you need multiple templated files, you will have to create multiple ConfigMaps |
| Konfigurator watches for changes in Pods, Ingresses and Services and updates the rendered templated whenever there's a change | Konfd has no support for watching over Pods, Ingresses or Services. It can only be used to watch for changes in ConfigMaps and Secrets |
| Supports accessing all kubernetes resources | You can only access ConfigMaps and Secrets by Name |