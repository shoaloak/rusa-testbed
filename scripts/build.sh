#!/usr/bin/env bash

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

# Get absolute script path
readonly SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Load configuration
source "${SCRIPT_PATH}/_config.sh"

for vuln_no in "${TARGET_KEYS[@]}"; do
    # vuln_no="vuln1" # DEBUG
    target="${TARGETS[$vuln_no]}"

    print_line
    echo "Building image 'testbed-${vuln_no}' for ${target}"

    buildah build \
        --build-arg PREFIX="${TARGET_PREFIX}" \
        --build-arg TARGET="${target}" \
        --build-arg VULN="${vuln_no}" \
        --file "${SCRIPT_PATH}/../Dockerfile.restler-mod" \
        --tag "testbed-${vuln_no}" \
        "${SCRIPT_PATH}/../"
done
