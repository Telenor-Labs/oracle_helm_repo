#!/usr/bin/env bash

# These functions depend on mysql.sh, which must be sourced before this is sourced.

LOG_DATE_CMD="date -u +%FT%TZ"

function probe_liveness() {
    MYSQL_CONNECTIVITY_SERVICE=${LOOPBACK_IP:-"127.0.0.1"}
    MYSQL_USERNAME="${MYSQL_USERNAME:-$MYSQL_OCCNE_USER}"
    MYSQL_PASSWORD="${MYSQL_PASSWORD:-$MYSQL_OCCNE_PASSWORD}"

    local query="SELECT 1;"

    echo "INFO: $($LOG_DATE_CMD) - query: $query";

    query_mysql "$query"
}
