#!/bin/bash

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

# Get absolute script path
#readonly SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

docker build --file Dockerfile.restler --tag testbed-restler .
#docker build --file Dockerfile.rusa --tag testbed-rusa .