#!/usr/bin/python3
import sys
import getopt
import yaml


def main(argv):
    """Creates an operator group for the operator CSV if the CSV does not support AllNamespaces."""

    op_group_file = None
    op_name = None
    csv_file = None
    namespace = None
    installmode = None

    try:
        opts, args = getopt.getopt(argv, "g:o:v:n:i:", ["opgroupfile=", "opname=", "csvfile=", "namespace=", "installmode="])
    except getopt.GetoptError:
        sys.exit(2)
    for opt, arg in opts:
        if opt in ("-g", "--opgroupfile"):
            op_group_file = arg
        elif opt in ("-o", "--opname"):
            op_name = arg
        elif opt in ("-v", "--csvfile"):
            csv_file = arg
        elif opt in ("-n", "--namespace"):
            namespace = arg
        elif opt in ("-i", "--installmode"):
            installmode = arg
    if op_group_file is None or op_name is None or csv_file is None or namespace is None:
        print('One of the required parameter missing for creating configmap registry')
        sys.exit(1)

    with open(csv_file, 'r') as read_file:
        yaml_file = yaml.safe_load(read_file.read())

    install_modes = yaml_file['spec']['installModes']

    catalogsource = None

    for im in install_modes:

        if im['type'] == 'AllNamespaces' and im['supported'] and installmode == 'AllNamespaces':
            catalogsource = {
                'apiVersion': 'operators.coreos.com/v1alpha2',
                'kind': 'OperatorGroup',
                'metadata': {
                    'name': "{}-og".format(op_name),
                    'labels': {
                       'operator': 'test'
                    },
                    'namespace': namespace,
                }
            }
            break

        elif installmode != 'AllNamespaces':
            catalogsource = {
                'apiVersion': 'operators.coreos.com/v1alpha2',
                'kind': 'OperatorGroup',
                'metadata': {
                    'name': "{}-og".format(op_name),
                    'namespace': namespace,
                    'labels': {
                        'operator': 'test'
                    }
                },
                'spec': {
                    'targetNamespaces': [namespace]
                }
            }

    if catalogsource is not None:
        with open(op_group_file, 'w') as write_file:
            print(yaml.safe_dump(catalogsource, default_flow_style=False), file=write_file)
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == "__main__":
    main(sys.argv[1:])
