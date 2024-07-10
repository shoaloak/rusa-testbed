#!/bin/bash

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

# Environment variable sanity check
if [ -z "${VULN}" ] || [ -z "${DB}" ] || [ -z "${TIMEOUT_SEC}" ]; then
  echo "Error: Required environment variable(s) not defined."
  exit 1
fi

# Definitions
readonly me=$(basename "$0")

readonly RESULTS_FILE="traversed.result"
readonly ARG_DISTANCE_TREE="distanceTree=distance_tree.json"
readonly ARG_MODE="mode=synergy"
readonly ARG_RESULTS_PATH="resultsPath=${RESULTS_FILE}"
readonly BACKEND_OUT="java.log"

readonly LOG_TO_FILE="entrypoint.log"
readonly LOG_TO_STDOUT="true"
log() {
    local message="$1"

    # Format the log message
    local formatted_message="[${me}] ${message}"

    if [ -n "$LOG_TO_FILE" ]; then
        echo "$formatted_message" >> "$LOG_TO_FILE"
    fi

    if [ "$LOG_TO_STDOUT" != "false" ]; then
        echo "$formatted_message"
    fi
}

store_results() {
    # Check if results file exists and copy if it does
    if [ -f "$RESULTS_FILE" ]; then
        cp "${RESULTS_FILE}" /host_result_folder/
    else
        log "ERROR: results file not found!"
    fi 

    if [ -d "RestlerResults" ]; then
        cp -r RestlerResults /host_result_folder/RestlerResults
    else
        log "ERROR: RestlerResults folder not found!"
    fi

    if [ -f "${BACKEND_OUT}" ]; then
        cp "${BACKEND_OUT}" /host_result_folder/
    else
        log "ERROR: backend log file not found!"
    fi

    if [ -f "${LOG_TO_FILE}" ]; then
        cp "${LOG_TO_FILE}" /host_result_folder/
    else
        # there is no log, printf instead
        printf "ERROR: log file not found!"
    fi
}

# Check if the server is ready by polling the health endpoint
check_server_ready() {
  curl -s http://localhost:9966/petclinic/actuator/health | grep '"status":"UP"' > /dev/null
  return $?
}

# Start instrumented Spring server
readonly RUSA_ARGS="$ARG_DISTANCE_TREE,$ARG_MODE,$ARG_RESULTS_PATH"
(java \
    -javaagent:rusa-jar-with-dependencies.jar="${RUSA_ARGS}" \
    -jar vulnserver.jar \
        --feature.unsafe="${VULN}" \
        --spring.datasource.url="${DB}" 2>&1 | tee "${BACKEND_OUT}") &
SERVER_PID=$!

# Wait for server to start
#sleep 10 # usually takes 5s, but wait 10s to be safe
until check_server_ready; do
  echo "Waiting for server to be ready..."
  sleep 1
done

# time_budget 1 == 1 hour
# BUDGET_HOUR=1
# BUDGET_MIN=0.017
BUDGET_SEC=0.0003
time_budget=$(awk "BEGIN {print $TIMEOUT_SEC * $BUDGET_SEC}")

start_time=$(date +%s)
# timeout is probably not necessary as Restler provides time_budget
#timeout -k $TIMEOUT_SEC \
python3 ./restler/restler.py \
        --time_budget "$time_budget" \
        --fuzzing_mode bfs-fast \
        --restler_grammar Compile/grammar.py \
        --custom_mutations Compile/dict.json \
        --settings Compile/engine_settings.json \
        --no_tokens_in_logs NO_TOKENS_IN_LOGS \
        --no_ssl \
        --include_user_agent \
        --enable_checkers ['*'] \
        --dynamic \
        --disable_checkers ['namespacerule'] \
        --ignore_feedback "$IGNORE_HTTP_FEEDBACK" \
        --set_version 9.1.1 &
FUZZ_PID=$!

# Wait for asynchronous commands, i.e., server and fuzzer
wait -n -p first_finished_pid $SERVER_PID $FUZZ_PID # assign $first_finished_pid
return_code="$?"

# Sanity check if the return code is set
if [ -z "$return_code" ]; then
    log "ERROR: no return code set!"
    exit 1
fi

# Calculate time taken
stop_time=$(date +%s)
total=$((stop_time - start_time))

log "total time taken: $total seconds"

# Check which process finished first
if [ "$first_finished_pid" -eq "$FUZZ_PID" ]; then
    log "Fuzzer finished"
    kill $SERVER_PID

    if [ "$return_code" -eq -1 ]; then
        log "ERROR: RESTler crashed!"
        :
    elif [ "$return_code" -eq 1 ]; then
        log "ERROR: Couldn't connect to ZMQ!"
    fi
else
    # Server halted
    log "Server halted, likely SQLi"
    kill $FUZZ_PID

    if [ "$return_code" -ne 0 ]; then
        # This is very unlikely, if it ever happens, PM me :)
        log "ERROR: Spring server crashed!"
    fi
fi

sleep 1 # Sleep a bit to ensure traversed.result is written
store_results
