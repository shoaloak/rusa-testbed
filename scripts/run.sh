#!/usr/bin/env bash

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

# Get absolute script path
readonly SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Load configuration
source "${SCRIPT_PATH}/_config.sh"
# Load CPU functions
source "${SCRIPT_PATH}/_cpu.sh"

# Definitions
readonly DB=petclinic-db-postgresql
readonly TIMESTAMP=$(date "+%Y%m%d_%H%M%S")
readonly RESULT_PATH="${SCRIPT_PATH}/../results/run-${TIMESTAMP}"
readonly CPU=$(get_target_cpu)
readonly TIMEOUT=$((5*60*60)) # 5 hours

# Initialize async logging
mkfifo "${RESULT_PATH}/logpipe"
cat "${RESULT_PATH}/logpipe" >> "${RESULT_PATH}/run.out" &

log() {
    local message="$1"
    #echo "$message" >> "${RESULT_PATH}/run.out"
    echo "$message" > "${RESULT_PATH}/logpipe"
}

# Function to check if the DB is ready
check_postgres() {
    local db_name="$1"
    podman exec "${db_name}" pg_isready -U postgres
    return $?
}

start_database() {
    local db_name="$1"

    echo "Starting database..."
    podman run \
        --rm \
        --replace \
        --detach \
        --name "${db_name}" \
        --network testbed-network \
        -e POSTGRES_DB=petclinic \
        -e POSTGRES_PASSWORD=petclinic \
        -v "${SCRIPT_PATH}/../resources/postgresql":/docker-entrypoint-initdb.d/:Z \
        docker.io/library/postgres:16.0
    sleep 2 # usually takes 2s
    until check_postgres "${db_name}"; do
        echo "Waiting for PostgreSQL to be ready..."
        sleep 1
    done
}

run_test() {
    local vuln_no="$1"
    local target="$2"
    local tool="$3"
    local suffix="$4"
    local ignore_http_feedback="$5"

    print_line
    printf "running 'testbed-%s-%s' for %s\nCPUs=%s\n\n" \
        "$tool" "$vuln_no" "$target" "$CPU"

    #for i in {1..3}; do
    for i in {1..1}; do
        echo "Iteration $i for vulnerability ${vuln_no} (${target})"

        FQDN="${DB}-${tool}-${suffix}-${vuln_no}"
        start_database "${FQDN}"
        # podman doesn't create volumes :'(
        mkdir -p "${RESULT_PATH}/${vuln_no}/${tool}/${i}/${suffix}"
        # Fix: Podman permissions
        sudo chmod -R 777 "${RESULT_PATH}/${vuln_no}/${tool}/${i}/${suffix}"

        echo "Executing container for vulnerability ${vuln_no} (${target})"
        podman run -ti \
            --cpus="${CPU}" --cpuset-cpus=0-$((CPU - 1)) \
	    --memory 224g \
            --network testbed-network \
            --volume "${RESULT_PATH}/${vuln_no}/${tool}/${i}/${suffix}":/host_result_folder:Z \
            -e DB="jdbc:postgresql://${FQDN}:5432/petclinic" \
            -e TIMEOUT_SEC=${TIMEOUT} \
            ${ignore_http_feedback:+-e IGNORE_HTTP_FEEDBACK=true} \
            "testbed-${vuln_no}" "${tool}"

        podman stop "${FQDN}"
    done
}


# Initialize
if ! podman network ls | grep -qw testbed-network; then
    echo "Network does not exist. Creating network..."
    podman network create testbed-network
else
    echo "Network already exists. Skipping creation..."
fi

echo "Create result folder..."
if ! mkdir -p "${RESULT_PATH}"; then
    echo "Error: Unable to create directory at ${RESULT_PATH}"
    exit 1
fi
# Fix: Podman permissions extra
sudo chmod -R 777 "${RESULT_PATH}"

# RESTler
(
    log "RESTler /w HTTP feedback start"
    start_time=$(date +%s)
    for vuln_no in "${TARGET_KEYS[@]}"; do
        target="${TARGETS[$vuln_no]}"
        run_test "$vuln_no" "$target" "restler" "http" false
    done
    stop_time=$(date +%s)
    total=$((stop_time - start_time))
    log "RESTler /w HTTP feedback done, time taken: $total seconds"
) &

# Rusa
(
    log "Rusa /w HTTP feedback start"
    start_time=$(date +%s)
    for vuln_no in "${TARGET_KEYS[@]}"; do
        target="${TARGETS[$vuln_no]}"
        run_test "$vuln_no" "$target" "rusa" "http" false
    done
    stop_time=$(date +%s)
    total=$((stop_time - start_time))
    log "Rusa /w HTTP feedback done, time taken: $total seconds"
) &

# RESTler
(
    log "RESTler /wo HTTP feedback start"
    start_time=$(date +%s)
    for vuln_no in "${TARGET_KEYS[@]}"; do
        target="${TARGETS[$vuln_no]}"
        run_test "$vuln_no" "$target" "restler" "no_http" true
    done
    stop_time=$(date +%s)
    total=$((stop_time - start_time))
    log "RESTler /wo HTTP feedback done, time taken: $total seconds"
) &

# Rusa
(
    log "Rusa /wo HTTP feedback start"
    start_time=$(date +%s)
    for vuln_no in "${TARGET_KEYS[@]}"; do
        target="${TARGETS[$vuln_no]}"
        run_test "$vuln_no" "$target" "rusa" "no_http" true
    done
    stop_time=$(date +%s)
    total=$((stop_time - start_time))
    log "Rusa /wo HTTP feedback done, time taken: $total seconds"
) &

# Wait for all tests to finish
wait

# Remove network
podman network rm testbed-network

echo "Done"
