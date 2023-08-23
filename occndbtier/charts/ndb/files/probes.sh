#!/usr/bin/env bash

GREP_CMD="/usr/bin/grep"
NDB_MGM_CMD="/usr/local/bin/ndb_mgm --connect-retries=1"

function ndb_mgm_show() {
    $NDB_MGM_CMD -c $NDB_MGMD_CONNECTSTRING -e SHOW 2>&1
}

function is_mgm_up() {
    ndb_mgm_show > /dev/null
}

function get_ndbmtd_node_id() {
    node=$(echo $HOSTNAME | awk 'BEGIN {FS="-"} {print $NF}')
    ((id=node+1))
    echo $id
}


function get_group_mate_node_id() {
    node_id=$1
    if [[ $((node_id % 2)) -eq 0 ]]; then
        group_mate_node_id=$((node_id - 1))
    else
        group_mate_node_id=$((node_id + 1))
    fi
    echo $group_mate_node_id
}

function is_node_started() {
    node_id=$1
    $NDB_MGM_CMD -c $NDB_MGMD_CONNECTSTRING -e "$node_id status" 2>&1 | $GREP_CMD -q -e "Node ${node_id}: started"
}

function is_at_least_one_node_started_in_group() {
    group=$1;

    ((nodes_per_group=$NDB_MTD_NO_OF_DATA_NODES/$no_of_groups))
    ((first_node_id=(nodes_per_group*group)+1))
    ((end_node_id=first_node_id+nodes_per_group));   # one plus last node

    id=$first_node_id; while [ $id -lt $end_node_id ]; do
        if is_node_started $id; then
            return 0;
        fi
        ((++id))
    done

    return 1;
}

function is_at_least_a_node_per_group_started() {
    ((no_of_groups=$NDB_MTD_NO_OF_DATA_NODES/$NDB_MTD_NO_OF_REPLICAS))
    group=0; while [ $group -lt $no_of_groups ]; do
        if ! is_at_least_one_node_started_in_group $group; then
            return 1;
        fi
        ((++group))
    done
    return 0;
}

function is_cluster_up() {
    is_at_least_a_node_per_group_started
}

# if there is no comm to mgm nodes; it will set it to ready due to assumed cluster down
function is_ready() {
    node_id=$(get_ndbmtd_node_id)
    group_mate_node_id=$(get_group_mate_node_id $node_id)

    if is_node_started $node_id; then
        return 0;
    elif ! is_node_started $group_mate_node_id; then
        return 0;
    fi
    return 1;
}
