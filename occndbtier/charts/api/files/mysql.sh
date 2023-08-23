#!/usr/bin/env bash

MYSQL_CMD="mysql --binary-as-hex=0 --show-warnings"


# Executs a mysql query and quits. It uses --silence, -s, option, which results
# in nontabular output formant and escaping of special characters. A second -s
# option results in no header.
#
# It requires the following variables to be set:
#   MYSQL_CONNECTIVITY_SERVICE
#   MYSQL_USERNAME
#   MYSQL_PASSWORD
#
# @return  0 if query succeeds; 1 otherwise.
function query_mysql() {
    local query="$@"

    $MYSQL_CMD -h${MYSQL_CONNECTIVITY_SERVICE} -u${MYSQL_USERNAME} -p${MYSQL_PASSWORD} -sse "$query"
}
