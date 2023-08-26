#!/bin/sh

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

# Start instrumented server
java \
    -javaagent:rusa-jar-with-dependencies.jar=distanceTree=distance_tree.json,mode=standalone \
    -jar vulnserver.jar &

# Erik: modify vulnserver to halt when SQLi is detected
# store the PID

# Wait for server to start
sleep 5

# Start Restler
# TODO store starttime: date +%s
python3 ./restler/restler.py \
    --time_budget 0.0024 \
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

# TODO: watch pid if halted
# time

# Wait for any process to exit
#wait -n
# TODO replace with a countdown and kill