# Konfigurator vs Kubegen

Konfigurator took inspiration from Kubegen but both vary a bit. The table below shows how kubegen and konfigurator differ in comparison:

| Konfigurator | Kubegen |
|--------------|---------|
|Konfigurator runs as a pod and watches its own CRD templates and renders them whenever kubernetes resources change | Kubegen is an executable that receives a template file as an input and renders it when kubernetes resources change |
| It supports any number of files as templates inside `KonfiguratorTemplate` CRD | It only allows 1 template file as an input |
| Konfigurator renders the templates in kubernetes resources i.e., ConfigMap or Secret which means that a tool like Reloader can automatically restart the app for which the config has been rendered | Unlike Konfigurator, Kubegen renders the template in a file and it becomes the responsibility of the app container to restart the app itself when the file changes |
| Konfigurator does not require you to modify the app container image but allows you to replace your ConfigMap or Secret with its own resource known as `KonfiguratorTemplate` | You have to modify the app container image |
| It works on kubernetes level | Kubegen's binary has to be inside the app container image and some scripts need to written for restart logic in order for it to work properly with the app |
| It supports both ConfigMap and Secrets as the render target | There is no support for rendering the templates in a kubernetes resource |