#!/usr/bin/env bash

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

# Get absolute script path
readonly SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Load configuration
source "${SCRIPT_PATH}/config.sh"

for vuln_no in "${TARGET_KEYS[@]}"; do
    target="${TARGETS[$vuln_no]}"

    print_line
    echo "Executing container for vulnerability ${vuln_no} (${target})"

    # Execute RESTler
    docker run -ti "testbed-restler-${vuln_no}"
done
