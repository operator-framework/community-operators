## OKD/OpenShift Catalogs criteria and options

To distribute on OpenShift Catalogs, you will need to comply with the same standard criteria defined for `OperatorHub.io`, and then, additionally, you have some requirements and options.

**IMPORTANT** Kubernetes has been deprecating API(s), which will be removed and no longer available in `1.22` and the Openshift version `4.9`. Note that your project will be unable to use them on `OCP 4.9/K8s 1.22`. Then, it's required to ensure that your users will have a version of your operator installed on `4.8`, which is not using the deprecated and no longer supported API(s) before they upgrade the OCP cluster from `4.8` to `4.9.`. See [Deprecated API Migration Guide from v1.22](https://kubernetes.io/docs/reference/using-api/deprecation-guide/#v1-22).

### Configure the max OpenShift Version compatible

Use the `olm.openShiftMaxVersion` annotation in the CSV to prevent the user from upgrading their OCP cluster before upgrading the installed operator version to any distribution which is compatible with:

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: ClusterServiceVersion
metadata:
  annotations:
    # Prevent cluster upgrades to OpenShift Version 4.9 when this 
    # bundle is installed on the cluster
    "olm.properties": '[{"type": "olm.maxOpenShiftVersion", "value": "4.8"}]'
```

This option is useful when you know that the current version of your project will not work well on some specific Openshift version. 

Notice that if you are distributing a solution that contains deprecated API(s) that will no longer be available in upper versions, you must use this annotation.

### Configure the Openshift distribution 

Use the annotation `com.redhat.openshift.versions` in `bundle/metadata/annotations.yaml` to ensure that the index image will be generated with its OCP Label, to prevent the bundle from being distributed on to 4.9:
 
```
com.redhat.openshift.versions: "v4.6-v4.8"
```

#### Semantics

1. We use a single version to mean a minimum of this version but will be automatically opted-in
   to the next version
1. ‘=’ means a particular version ONLY
1. A range to be used with deprecation to stop shipping updates to (in the case below) 4.8.

|                      |          |             |             |             | 
|---                   |---       |---          |---          |---          |
|                      |"v4.6"    |"v4.7"       |"=v4.8"      |"v4.6-v4.8"  |
|4.6 Index Catalog     |Included  |Not Included |Not Included |Included     |
|4.7 Index Catalog     |Included⁴ |Included     |Included     |Included     |
|4.8 Index Catalog     |Included⁴ |Included⁴    |Not included |included     |
|4.9 Index Catalog     |Included⁴ |Included⁴    |Not Included |Not Included |

This option is also useful when you know that the current version of your project will not work well on some specific OpenShift version. You must use it if you are distributing a solution which, for example, contains deprecated API(s) which will no longer be available in upper versions.
