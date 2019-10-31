#!/usr/bin/python3
import sys
import os
import getopt
import yaml


def main(argv):
    """Creates an operator group for the operator CSV if the CSV does not support AllNamespaces."""

    csv_file = None
    installmode = None

    try:
        opts, args = getopt.getopt(argv, "c:", ["csvfile="])
    except getopt.GetoptError:
        sys.exit(2)

    for opt, arg in opts:
        if opt in ("-c", "--csvfile"):
            csv_file = arg
        
    with open(csv_file, 'r') as read_file:
        yaml_file = yaml.safe_load(read_file.read())

    install_modes = yaml_file['spec']['installModes']

    for im in install_modes:
        if  im['type'] != 'AllNamespaces' and im['supported']:
            installmode = im['type']
        elif im['type'] == 'AllNamespaces' and im['supported'] and installmode is None:
            installmode = im['type']

    print(installmode)

if __name__ == "__main__":
    main(sys.argv[1:])
