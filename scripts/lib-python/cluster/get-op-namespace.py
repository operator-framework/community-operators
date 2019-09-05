#!/usr/bin/python3

import sys
import random
import getopt
import yaml
import string


def randomString(stringLength=10):
    """Generate a random string of fixed length """
    letters = string.ascii_lowercase
    return ''.join(random.choice(letters) for i in range(stringLength))


def main(argv):
    csv_file = None
    operator = None

    try:
        opts, args = getopt.getopt(argv, "o:c:", ["operator=", "csvfile="])
    except getopt.GetoptError:
        sys.exit(2)

    for opt, arg in opts:
        if opt in ("-o", "--operator"):
            operator = arg
        elif opt in ("-c", "--csvfile"):
            csv_file = arg

    with open(csv_file, 'r') as stream:
        csv_file = yaml.safe_load(stream)

    install_modes = csv_file.get('spec', {}).get('installModes', [])
    namespace = ''
    if len(install_modes) > 0:
        for mode in install_modes:
            if mode.get('supported') and mode.get('type') in ['OwnNamespace', 'SingleNamespace', 'AllNamespaces']:
                namespace = '{}-{}'.format(operator, randomString(5))
                break
    else:
        print('Problem with parsing installModes')
        sys.exit(1)

    print(namespace)


if __name__ == "__main__":
    main(sys.argv[1:])
