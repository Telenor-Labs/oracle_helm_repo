#!/usr/bin/env bash

RM_CMD="rm"
CAT_CMD="cat"

FILE_READINESS_PROBE_SUCCEEDED="/tmp/readinessProbeHasSucceeded";

function is_regular_file() {
    test -f "$1"
}

# to avoid creating files when running AUTs
function redirect_to_file() {
    echo "$1" > "$2";
}

# this function needs to be redefined for the specific containter
function is_ready() {
    # return false to force this function to be redefined
    return 1;
}

function probe_readiness() {
    local successThreshold=$1;

    local num_of_successes=0;
    if is_regular_file "$FILE_READINESS_PROBE_SUCCEEDED"; then
        num_of_successes=$($CAT_CMD $FILE_READINESS_PROBE_SUCCEEDED)
        if [[ $num_of_successes -ge $successThreshold ]]; then
            return 0;
        fi
    fi

    if is_ready; then
        ((num_of_successes++));
        redirect_to_file $num_of_successes "$FILE_READINESS_PROBE_SUCCEEDED"
    else
        $RM_CMD -f $FILE_READINESS_PROBE_SUCCEEDED;
        return 1;
    fi
}

# this function may need to be redefined for the specific containter
function exec_after_container_is_ready() {
    return 0;
}

function probe_startup() {
    if is_regular_file "$FILE_READINESS_PROBE_SUCCEEDED"; then
        $RM_CMD -f $FILE_READINESS_PROBE_SUCCEEDED;
    fi

    if ! is_mgm_up; then
        return 1;
    fi

    local dummy_successThreshold=1;  # to avoid confusion
    if probe_readiness $dummy_successThreshold; then
        exec_after_container_is_ready;
    else
        return 1;
    fi
}
