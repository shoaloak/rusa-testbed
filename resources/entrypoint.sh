#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Check the first argument to determine which entrypoint to use
if [ "$1" = "restler" ]; then
    shift  # Remove the first argument
    echo "Running Restler entrypoint"
    exec ./entrypoint-restler.sh
elif [ "$1" = "rusa" ]; then
    shift  # Remove the first argument
    echo "Running Rusa entrypoint"
    exec ./entrypoint-rusa.sh
else
    echo "Invalid entrypoint flag. Use 'restler' or 'rusa'."
    exit 1
fi
