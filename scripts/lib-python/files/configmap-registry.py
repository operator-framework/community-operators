#!/usr/bin/python3

import sys
import os
import getopt
import yaml
import re


def main(argv):
    operator = None
    dir = None
    namespace = None
    version = None
    catalogfilename = None
    packagefile = None
    csvfiles = ''
    crdfiles = ''
    output = None

    try:
        opts, args = getopt.getopt(argv, "o:d:n:v:c:", ["operator=", "dir=", "namespace=", "opversion=", "catalogfilename="])
    except getopt.GetoptError:
        sys.exit(2)
    for opt, arg in opts:
        if opt in ("-o", "--operator"):
            operator = arg
        elif opt in ("-d", "--dir"):
            dir = arg
        elif opt in ("-n", "--namespace"):
            namespace = arg
        elif opt in ("-v", "--opversion"):
            version = arg
        elif opt in ("-c", "--catalogfilename"):
            catalogfilename = arg

    if operator is None or dir is None or namespace is None or version is None or catalogfilename is None:
        print('One of the required parameter missing for creating configmap registry')
        sys.exit(1)

    op_dir = os.path.join(dir, version)
    for filename in os.listdir(op_dir):
        if filename.endswith('.crd.yaml') and os.path.isfile(os.path.join(op_dir, filename)):
            with open(os.path.join(op_dir, filename), 'r') as stream:
                crdfiles += indent(stream.read())

    for filename in os.listdir(dir):
        if filename.endswith('package.yaml'):
            with open(os.path.join(dir, filename), 'r') as stream:
                packagefile = indent(stream.read(), False)

        elif os.path.isdir(os.path.join(dir, filename)):
            version_dir = os.path.join(dir, filename)

            for filename in os.listdir(os.path.join(dir, filename)):
                if filename.endswith('version.yaml'):
                    with open(os.path.join(version_dir, filename), 'r') as stream:
                        csvfiles += indent(stream.read())

    catalogsource = """kind: ConfigMap
apiVersion: v1
metadata:
  name: {}
  namespace: {}
data:
  customResourceDefinitions: |-
{}
  clusterServiceVersions: |-
{}
  packages: |-
{}
---
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: {}-ocs
  namespace: {}
spec:
  configMap: {}
  displayName: {}-ocs
  publisher: Red Hat
  sourceType: internal
    """.format(operator, namespace, crdfiles, csvfiles, packagefile, operator, namespace, operator, operator)

    print(catalogfilename)
    with open(catalogfilename, 'w') as writer:
        writer.write(catalogsource)


def indent(file, add_dashes=True):
    file = file.replace('\n', '\n        ')
    file = list(file)
    file[0] = '      - ' + file[0]
    file = "".join(file)
    file += "\n"
    return file


if __name__ == "__main__":
    main(sys.argv[1:])