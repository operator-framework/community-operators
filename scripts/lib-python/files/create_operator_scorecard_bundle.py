#!/usr/bin/python3
import sys
import getopt
import yaml
import os
import random
import string

def randomString(stringLength=10):
    """Generate a random string of fixed length """
    letters = string.ascii_lowercase
    return ''.join(random.choice(letters) for i in range(stringLength))

def main(argv):
    """Creates an operator group for the operator CSV if the CSV does not support AllNamespaces."""

    crds_path = None
    csv_path = None
    namespace = None
    bundle_path = None
    proxy_image = None
    deploy_dir = None
    cdrd_path = None

    try:
        opts, args = getopt.getopt(argv, "c:v:n:b:p:d:r:", ["cdrd=", "crds=", "bundle=", "csvfile=", "namespace=", "proxy=", "deploy-dir="])
    except getopt.GetoptError as e:
        print(e)
        sys.exit(2)

    for opt, arg in opts:
        if opt in ("-c", "--cdrd"):
            cdrd_path = arg
        elif opt in ("-r", "--crds"):
            crds_path = arg
        elif opt in ("-v", "--csvfile"):
            csv_path = arg
        elif opt in ("-n", "--namespace"):
            namespace = arg
        elif opt in ("-b", "--bundle"):
            bundle_path = arg
        elif opt in ("-p", "--proxy"):
            proxy_image = arg
        elif opt in ("-d", "--deploy-dir"):
            deploy_dir = arg

    crds = os.listdir(crds_path)
    crds = [os.path.join(crds_path, filename) if filename.endswith("cr.yaml") else None for filename in crds]
    crds = list(filter(lambda x: x is not None, crds))

    for cr in list(crds):
        scorecard_bundle = {
            "scorecard": {
                "output": "text",
                "plugins": [
                    {"basic": {
                        "olm-deployed": True,
                        "namespace": namespace,
                        "crds-dir": cdrd_path,
                        "cr-manifest": [cr],
                        "proxy-image": proxy_image,
                        "bundle": deploy_dir,
                        "proxy-pull-policy": "Never",
                        "csv-path": csv_path,
                        "init-timeout": 180
                    }},
                    {"olm": {
                        "olm-deployed": True,
                        "namespace": namespace,
                        "crds-dir": cdrd_path,
                        "bundle": deploy_dir,
                        "cr-manifest": [cr],
                        "proxy-image": proxy_image,
                        "proxy-pull-policy": "Never",
                        "csv-path": csv_path,
                        "init-timeout": 180
                    }}
                ]
            }
        }
        if scorecard_bundle is not None:
            with open(os.path.join(bundle_path, randomString() + ".bundle.yaml"), 'w') as write_file:
                print(yaml.safe_dump(scorecard_bundle, default_flow_style=False), file=write_file)

    if crds is not None:
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == "__main__":
    main(sys.argv[1:])
