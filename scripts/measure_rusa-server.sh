#!/bin/bash
# Script to check how long DB initialization takes

readonly SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

readonly ARG_DISTANCE_TREE='distanceTree=resources/distance_tree.json' # seems path fucks shit up
readonly ARG_MODE="mode=standalone"

readonly RUSA_ARGS="$ARG_DISTANCE_TREE,$ARG_MODE,$ARG_RESULTS_PATH"
# experiment 1, server without instrumentation
#java -jar ./resources/vulnserver.jar &
# results on m2: 5s, 3s, 4s

# experiment 2, server with instrumentation
 java \
     -javaagent:./resources/rusa-jar-with-dependencies.jar="${RUSA_ARGS}" \
     -jar ./resources/vulnserver.jar &
pid=$!
# results on m2: 5s, 4s, 4s
# Seems the agent doesn't affect startup that much.

# Record the start time
start_time=$(date +%s)
# start_time=$(date +%s)

# Function to check if spring boot server is ready
check_ready() {
  curl -s http://localhost:9966/petclinic/actuator/health | grep '"status":"UP"'
  return $?
}

# Poll the container until it's ready
until check_ready; do
  echo "Waiting for server to be ready..."
  sleep 1
done

# Record the end time
end_time=$(date +%s)

# Calculate the total time taken
total_time=$((end_time - start_time))
echo "Server is ready! Time taken: ${total_time} seconds."

# Cleanup
kill $pid
