#!/usr/bin/env bash

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

# Get absolute script path
readonly SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Load configuration
source "${SCRIPT_PATH}/_config.sh"

# Definitions
readonly DB=petclinic-db-postgresql
readonly TIMESTAMP=$(date "+%Y%m%d_%H%M%S")
readonly RESULT_PATH="${SCRIPT_PATH}/../results/run-${TIMESTAMP}"

# Initialize
if ! docker network ls | grep -qw testbed-network; then
    echo "Network does not exist. Creating network..."
    docker network create testbed-network
else
    echo "Network already exists. Skipping creation..."
fi

echo "Ensure fresh database..."
docker stop petclinic-db-postgresql > /dev/null 2>&1 || true

echo "Create result folder..."
if ! mkdir -p "${RESULT_PATH}"; then
    echo "Error: Unable to create directory at ${RESULT_PATH}"
    exit 1
fi

for vuln_no in "${TARGET_KEYS[@]}"; do
    # vuln_no="vuln1" # DEBUG
    target="${TARGETS[$vuln_no]}"
    print_line
    printf "running 'testbed-restler-%s' for %s\n\n" "$vuln_no" "$target"

    # Database
    echo "Starting database..."
    docker run \
        --rm \
        --detach \
        --name "${DB}" \
        --network testbed-network \
        -e POSTGRES_DB=petclinic \
        -e POSTGRES_PASSWORD=petclinic \
        -v "$SCRIPT_PATH/resources/postgresql":/docker-entrypoint-initdb.d/ \
        postgres:16.0
    sleep 4 # usually takes 2s, but wait 4s to be safe

    # Server
    echo "Executing container for vulnerability ${vuln_no} (${target})"
    docker run -ti \
        --network testbed-network \
        --volume "${RESULT_PATH}/${vuln_no}":/host_result_folder \
        -e DB="jdbc:postgresql://${DB}:5432/petclinic" \
        "testbed-restler-${vuln_no}"

    # Stop database
    docker stop petclinic-db-postgresql
    # break # DEBUG
done

# Remove network
docker network rm testbed-network

echo "Done"