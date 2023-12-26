#!/usr/bin/env bash

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

# Get absolute script path
readonly SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Load configuration
source "${SCRIPT_PATH}/config.sh"

# Create network
docker network create testbed-network

for vuln_no in "${TARGET_KEYS[@]}"; do
    target="${TARGETS[$vuln_no]}"
    print_line

    echo "Starting database..."
    docker run \
        --rm \
        --detach \
        --name petclinic-db-postgresql \
        --network testbed-network \
        -e POSTGRES_DB=petclinic \
        -e POSTGRES_PASSWORD=petclinic \
        -v "$SCRIPT_PATH/resources/postgresql":/docker-entrypoint-initdb.d/ \
        postgres:16.0

    echo "Executing container for vulnerability ${vuln_no} (${target})"

    # Execute RESTler
    docker run -ti --network testbed-network "testbed-restler-${vuln_no}"

    # Stop database
    docker stop petclinic-db-postgresql
done
