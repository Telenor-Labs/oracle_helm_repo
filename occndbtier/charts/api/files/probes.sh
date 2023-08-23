#!/usr/bin/env bash

# These functions depend on probes_gen.sh, which must be sourced before this is sourced.

GREP_CMD="/usr/bin/grep"
NDB_MGM_CMD="/usr/local/bin/ndb_mgm --connect-retries=1"
LOG_DATE_CMD="date -u +%FT%TZ"

function ndb_mgm_show() {
    $NDB_MGM_CMD -c $NDB_MGMD_CONNECTSTRING -e SHOW 2>&1
}

function is_mgm_up() {
    ndb_mgm_show > /dev/null
}

function get_sqld_node_id() {
    local incr=$(echo $HOSTNAME | awk 'BEGIN {FS="-"} {print $NF}')
    if [ "${IS_NODE_FOR_GEO_REPLICATION}" = "1"  ]; then
        local id="${STARTING_SQL_NODEID:-56}"
    else
        local id="${STARTING_SQL_NODEID:-70}"
    fi
    (( id += incr ))

    echo $id
}

function is_node_connected() {
    node_id=$1
    $NDB_MGM_CMD -c $NDB_MGMD_CONNECTSTRING -e "$node_id status" 2>&1 | $GREP_CMD -q -e "Node ${node_id}: connected"
}

function is_ready() {
    node_id=$(get_sqld_node_id)
    is_node_connected $node_id
}
