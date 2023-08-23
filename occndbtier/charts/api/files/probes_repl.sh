#!/usr/bin/env bash

# These functions depend on probes.sh and mysql.sh, which must be sourced before this is sourced.

function get_server_id() {
    local config_file=${config_file:-"/etc/my.cnf"}

    echo $($GREP_CMD "server_id" $config_file | cut -d'=' -f2)
}

function update_start_ts() {
    MYSQL_CONNECTIVITY_SERVICE=${LOOPBACK_IP:-"127.0.0.1"}
    MYSQL_USERNAME="${MYSQL_USERNAME:-$MYSQL_OCCNE_USER}"
    MYSQL_PASSWORD="${MYSQL_PASSWORD:-$MYSQL_OCCNE_PASSWORD}"

    local server_id=$(get_server_id)
    local query="UPDATE replication_info.DBTIER_REPLICATION_CHANNEL_INFO SET start_ts = NOW() \
        WHERE server_id = $server_id;"

    echo "INFO: $($LOG_DATE_CMD) - query: $query";

    query_mysql "$query"
}

function exec_after_container_is_ready() {
    update_start_ts;
}
