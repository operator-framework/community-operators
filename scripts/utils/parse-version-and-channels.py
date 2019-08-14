#!/usr/bin/python3

import sys
import os
import getopt
import yaml
import re


def main(argv):
    packagefile = ''
    channel = ''
    version = None

    try:
        opts, args = getopt.getopt(argv, "p:v:c:", ["pfile=", "channel="])
    except getopt.GetoptError:
        sys.exit(2)
    for opt, arg in opts:
        if opt in ("-p", "--pfile"):
            packagefile = arg
        elif opt in ("-c", "--channel"):
            channel = arg

    if os.path.isfile(packagefile):
        with open(packagefile, 'r') as stream:
            try:
                package = yaml.safe_load(stream)
                if package.get('channels', False):
                    if channel == '' and package.get('defaultChannel', False):
                        channel = package['defaultChannel']
                    elif len(package['channels']) == 1:
                        channel = package['channels'][0].get('name', '')

                    for package_channel in package['channels']:
                        if (package_channel['name'] == channel and package_channel != '') or channel == '':
                            version = re.search("(\d\.)+(\d).+$", package_channel['currentCSV'])
                if version is not None:
                    os.environ['OP_VER'] = str(version.group())
                    print(os.environ['OP_VER'])
            except yaml.YAMLError as exc:
                print(exc)
    else:
        print("package file not found")
        sys.exit(1)


if __name__ == "__main__":
    main(sys.argv[1:])
