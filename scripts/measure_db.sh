#!/bin/bash
# Script to check how long DB initialization takes

readonly SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Start the PostgreSQL container
docker run \
    --rm \
    --detach \
    --name my_postgres \
    -e POSTGRES_DB=petclinic \
    -e POSTGRES_PASSWORD=petclinic \
    -v "$SCRIPT_PATH/resources/postgresql":/docker-entrypoint-initdb.d/ \
    postgres:16.0

# Record the start time
start_time=$(date +%s)
# start_time=$(date +%s)

# Function to check if PostgreSQL is ready
check_postgres() {
  docker exec my_postgres pg_isready -U postgres
  return $?
}

# Poll the container until it's ready
until check_postgres; do
  echo "Waiting for PostgreSQL to be ready..."
  sleep 1
done

# Record the end time
end_time=$(date +%s)

# Calculate the total time taken
total_time=$((end_time - start_time))
echo "PostgreSQL is ready! Time taken: ${total_time} seconds."
# results on m2: 2s, 2s, 1s

# Cleanup: Stop and remove the container (optional)
docker stop my_postgres
