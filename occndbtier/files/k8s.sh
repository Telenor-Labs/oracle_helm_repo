#!/usr/bin/env bash

################################################################################
#                                                                              #
# Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.        #
#                                                                              #
################################################################################


GREP_CMD="grep"
NDB_MGM_CMD="ndb_mgm --connect-retries=1"
SLEEP_CMD="sleep"
KUBECTL_CMD="kubectl"
MYSQL_CMD="mysql --binary-as-hex=0 --show-warnings"
DATE_CMD="date"
LOG_DATE_CMD="date -u +%FT%TZ"
AWK_CMD="awk"
CUT_CMD="cut"


# Returns true if all containers in a pod are READY as indicated by kubectl get po.
#
# @param  $1 - regex used by grep -e to identify the pod to test.
#
# @param  $2 - namespace.
#
# @return 0 (true) if all containers in the pod are READY; 1 false if not or error.
#
function is_pod_ready() {
    local pod="$1"
    local namespace="$2"
    echo "INFO: $($LOG_DATE_CMD) - pod regex: $pod";
    echo "INFO: $($LOG_DATE_CMD) - namespace: $namespace";

    local out=$($KUBECTL_CMD -n $namespace get po | $GREP_CMD $pod)
    echo "INFO: $($LOG_DATE_CMD) - out: $out";

    lines=$(echo "$out" | wc -l)
    echo "INFO: $($LOG_DATE_CMD) - lines: $lines";

    if [[ "$out" == "" ]]; then
        >&2 echo "ERROR: $($LOG_DATE_CMD) - no matches for regex: \"$pod\""
        return 1;
    elif [ $lines -ne 1 ]; then
        >&2 echo "ERROR: $($LOG_DATE_CMD) - too many matches for regex: \"$pod\""
        return 1;
    fi

    local ready_status=$(echo $out| $AWK_CMD '{print $2}')
    echo "INFO: $($LOG_DATE_CMD) - ready_status: $ready_status";

    if ! echo "$ready_status" | $GREP_CMD -q -e "^[0-9][0-9]*/[0-9][0-9]*$"; then
        >&2 echo "ERROR: $($LOG_DATE_CMD) - invalid format for READY: \"$ready_status\""
        return 1;
    fi

    local containers_ready=$(echo "$ready_status" | $CUT_CMD -d'/' -f1)
    local number_of_containers=$(echo "$ready_status" | $CUT_CMD -d'/' -f2)
    echo "INFO: $($LOG_DATE_CMD) - containers_ready: $containers_ready";
    echo "INFO: $($LOG_DATE_CMD) - number_of_containers: $number_of_containers";

    test $containers_ready -eq $number_of_containers
}
