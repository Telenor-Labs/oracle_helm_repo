#!/usr/bin/env bash

GREP_CMD="/usr/bin/grep"
NDB_MGM_CMD="/usr/local/bin/ndb_mgm --connect-retries=1"

function rm_me_from_connect_string() {
    echo $NDB_MGMD_CONNECTSTRING | sed 's/,/\n/g' | grep -v $HOSTNAME | while read mgm; do
        echo -n "$mgm,";
    done | sed 's/,$//';
}

function is_other_mgm_up() {
    conn_str=$(rm_me_from_connect_string)
    $NDB_MGM_CMD -c $conn_str -e SHOW 2>&1 | $GREP_CMD -q -e '\[ndb_mgmd(MGM)\]'
}

function get_ndbmgmd_node_id() {
    node=$(echo $HOSTNAME | awk 'BEGIN {FS="-"} {print $NF}')
    start_id=49
    ((id=node+start_id))
    echo $id
}

function is_node_connected() {
    node_id=$1
    conn_str="localhost:1186"
    $NDB_MGM_CMD -c $conn_str -e "$node_id status" 2>&1 | $GREP_CMD -q -e "Node ${node_id}: connected"
}

function is_ready() {
    node_id=$(get_ndbmgmd_node_id)

    if is_node_connected $node_id; then
        return 0;
    elif ! is_other_mgm_up; then
        return 0;
    fi
    return 1;
}

function ignore() {
    return 0;
}

function is_mgm_up() {
    ignore;
}
