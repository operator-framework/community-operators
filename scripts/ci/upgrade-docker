#!/bin/bash

# Performs any provisioning needed for a clean build.
#
# This script is meant to be used either directly
# as a `before_install` step such that the next step
# in the Travis build have the environment properly
# setup.
#
# The script is also handy for debugging - SSH into
# the machine and then call `./.travis/main.sh` to
# have all dependencies set.

set -o errexit

main() {
  setup_dependencies

  echo "INFO:
  Done! Finished setting up Travis-CI machine.
  "
}

# Takes care of updating any dependencies that the
# machine needs.
setup_dependencies() {
  echo "INFO:
  Setting up dependencies.
  "

  sudo apt update -y
  sudo apt install --only-upgrade docker-ce -y

  docker info
}

main