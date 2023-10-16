#!/bin/bash

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

# Definitions
readonly TIMEOUT_SEC=30

# Start instrumented server
java \
    -javaagent:rusa-jar-with-dependencies.jar=distanceTree=distance_tree.json,mode=standalone \
    -jar vulnserver.jar &
SERVER_PID=$!

# Wait for server to start (usually ~3s startup time)
sleep 5

# Start Restler
# TODO store starttime: date +%s

# time budget is #hours.
#0.017 about 1 minute
#0.0003 about 1 sec
time_budget=`awk "BEGIN {$TIMEOUT_SEC * 0.0003}"`

#timeout -k $TIMEOUT_SEC $TIMEOUT_SEC
start_time=`date +%s`
python3 ./restler/restler.py \
        --time_budget $time_budget \
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

# Wait for children
wait -n -p job_id $SERVER_PID $FUZZ_PID
return_code="$?"

# Calculate time taken
stop_time=`date +%s`
total=`expr $stop_time - $start_time`

echo "Total time taken: $total seconds"

# Decide if server or fuzzer halted
if [ $job_id -eq $FUZZ_PID ]; then
    echo "fuzzer completed"

    # TODO
    # if [ $return_code ]; then
    # success, store time taken and nodes traversed to storage
    # else
    # failure -> crash
    # fi

    kill $SERVER_PID
else
    echo "server stopped"

    # TODO: check if its a crash or SQLi halt
    # if [ $return_code ]; then
    # success? (depends on return value) -> SQLi
    # else
    # failure -> crash
    # fi

    kill $FUZZ_PID
fi
