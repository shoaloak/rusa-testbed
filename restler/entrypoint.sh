#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Definitions
readonly TIMEOUT_SEC=30 # TODO set appropriate timeout
readonly RESULTS_FILE="traversed.result"
readonly ARG_DISTANCE_TREE="distanceTree=distance_tree.json"
readonly ARG_MODE="mode=standalone"
readonly ARG_RESULTS_PATH="resultsPath=\"${RESULTS_FILE}\""

readonly LOG_TO_FILE="entrypoint.log"
readonly LOG_TO_STDOUT="true"
log() {
    local message="$1"
    local timestamp=$(date '+%T.%3N') # %3N doesn't work on macOS

    # Format the log message
    local formatted_message="[$timestamp] $message"

    if [ -n "$LOG_TO_FILE" ]; then
        echo "$formatted_message" >> "$LOG_TO_FILE"
    fi

    if [ "$LOG_TO_STDOUT" != "false" ]; then
        echo "$formatted_message"
    fi
}

store_results() {
    cp -r RestlerResults /host_result_folder/RestlerResults
    cp "${LOG_TO_FILE}" /host_result_folder/
    cp "${RESULTS_FILE}" /host_result_folder/ # TODO FIX
}

# Start instrumented Spring server
readonly RUSA_ARGS="$ARG_DISTANCE_TREE,$ARG_MODE,$ARG_RESULTS_PATH"
java \
    -javaagent:rusa-jar-with-dependencies.jar="${RUSA_ARGS}" \
    -jar vulnserver.jar \
        --feature.unsafe="${VULN}" \
        --spring.datasource.url="${DB}" &
SERVER_PID=$!

# Wait for server to start (usually ~3s startup time)
sleep 5

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
        --disable_checkers ['namespacerule'] \
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
    echo "Fuzzer finished"

    if [ "$return_code" -eq 0 ]; then
        store_results
        :
    elif [ "$return_code" -eq -1 ]; then
        log "ERROR: RESTler crashed!"
        :
    elif [ "$return_code" -eq 1 ]; then
        log "ERROR: Couldn't connect to ZMQ!"
    fi

    kill $SERVER_PID
else
    # Server halted
    echo "SQLi detected"
    kill $FUZZ_PID

    if [ "$return_code" -eq 0 ]; then
        store_results
    else
        # This is very unlikely
        log "ERROR: Spring server crashed!"
    fi
fi
