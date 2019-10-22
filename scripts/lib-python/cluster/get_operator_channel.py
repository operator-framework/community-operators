#!/usr/bin/python3

import sys
import random
import getopt
import yaml
import string


def main(argv):
    csv_name = None
    package_file = None
    package_file_path = None
    channel = None
    testingChannel = "operator-testing"
    
    try:
        opts, args = getopt.getopt(argv, "p:c:", ["packagefile=", "csvname="])
    except getopt.GetoptError:
        sys.exit(2)

    for opt, arg in opts:
        if opt in ("-p", "--packagefile"):
            package_file_path = arg
        elif opt in ("-c", "--csvname"):
            csv_name = arg
    
    
    with open(package_file_path, 'r') as stream:
        package_file = yaml.safe_load(stream)

    channels = package_file.get('channels', {})
    
    for channel in channels:
        if channel["currentCSV"] == csv_name:
            print(channel["name"])
            return


    channel = {
        "currentCSV": csv_name,
        "name": testingChannel
    }

    package_file['channels'].append(channel)

    f= open(package_file_path,"w+")
    f.write(yaml.safe_dump(package_file))
    f.close()
    
    print(testingChannel)

if __name__ == "__main__":
    main(sys.argv[1:])

