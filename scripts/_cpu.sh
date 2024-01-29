#!/usr/bin/env bash

# Functions to get CPU info and suggest Docker arguments for macOS
calculate_linux_threads_per_core() {
    # Get the number of physical cores
    local physical_cores=$(lscpu | grep "^Core(s) per socket:" | awk '{print $4}')

    # Get the number of logical cores (threads)
    local logical_cores=$(lscpu | grep "^CPU(s):" | awk '{print $2}')

    # Get the number of sockets
    local sockets=$(lscpu | grep "^Socket(s):" | awk '{print $2}')

    # Calculate total physical cores
    local total_physical_cores=$((physical_cores * sockets))

    # Calculate threads per physical core
    local threads_per_core=$((logical_cores / total_physical_cores))

    # Return the number of threads per core
    echo $threads_per_core
}

get_target_cpu() {
    local cpu
    case "$(uname)" in
        "Linux")
            local smt=$(cat /sys/devices/system/cpu/smt/active)
            
            # Check if hyperthreading (SMT) is detected
            if [ "$smt" -eq 1 ]; then
                # SMT detected                
                cpu=$(calculate_linux_threads_per_core)
            else
                cpu=1
            fi
            ;;
        "Darwin")
            # use perflevel0 to only use "Performance" cores
            local cores=$(sysctl -n hw.perflevel0.physicalcpu)
            local threads=$(sysctl -n hw.perflevel0.logicalcpu)
            
            if [ "$cores" -lt "$threads" ]; then
                # SMT detected
                cpu=$((threads / cores))
            else
                cpu=1
            fi
            ;;
        *)
            echo "Unsupported operating system."
            exit 1
            ;;
    esac
    echo "$cpu"
}

# use
#cpu=$(get_target_cpu)
#docker run --cpus="$(cpus)" --cpuset-cpus=0-$((cpu - 1)) my_image