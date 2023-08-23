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
MYSQL_CMD=${MYSQL_CMD:-"mysql --binary-as-hex=0 --show-warnings"}
DATE_CMD="date"
LOG_DATE_CMD="date -u +%FT%TZ"
AWK_CMD="awk"
CUT_CMD="cut"
SED_CMD="sed"
HEAD_CMD="head"

DBTIER_MAIN_MGM_POD_CONTAINER=${DBTIER_MAIN_MGM_POD_CONTAINER:-"mysqlndbcluster"}
DBTIER_MAIN_NDB_POD_CONTAINER=${DBTIER_MAIN_NDB_POD_CONTAINER:-"mysqlndbcluster"}

KCTL="$KUBECTL_CMD -n $OCCNE_NAMESPACE"

NDB_MGMD_BASE_DATADIR=${NDB_MGMD_BASE_DATADIR:-"/var/occnedb"}
NDB_CONFIG_FILE_NAME_BEFORE_UPGRADE=${NDB_CONFIG_FILE_NAME_BEFORE_UPGRADE:-"ndb_config_before_upgrade.cnf"}
NDB_CONFIG_FILE_NAME_AFTER_UPGRADE=${NDB_CONFIG_FILE_NAME_AFTER_UPGRADE:-"ndb_config_after_upgrade.cnf"}
NDB_CONFIGS_THAT_NEED_RESTART_TYPE_INITIAL=${NDB_CONFIGS_THAT_NEED_RESTART_TYPE_INITIAL:-"DataDir\\|FileSystemPath\\|BackupDataDir\\|FragmentLogFileSize\\|InitFragmentLogFiles\\|NoOfFragmentLogFiles\\|EncryptedFileSystem\\|NoOfFragmentLogParts\\|FileSystemPathDD\\|FileSystemPathDataFiles\\|FileSystemPathUndoFiles\\|IndexStatSaveSize\\|IndexStatSaveScale\\|IndexStatTriggerPct\\|IndexStatTriggerScale\\|IndexStatUpdateDelay"}




# Returns the number of current replica count for the ndbappmysqld. 
# It returns 0 if the ndbappmysqld is not deployed. 
#
# It requires the following variables to be set:
#   OCCNE_NAMESPACE
#   NDBAPP_STS_NAME
function get_ndbapp_current_replica_count() {
    local ndbappReplicaCurrentCount=$($KUBECTL_CMD get sts -n ${OCCNE_NAMESPACE} | $GREP_CMD ${APP_STS_NAME} | $AWK_CMD '{print $2}' | $AWK_CMD -F '/' '{print $2}')
    if [[ -z "${ndbappReplicaCurrentCount}" ]]; then
        ndbappReplicaCurrentCount=0
    fi
    echo $ndbappReplicaCurrentCount
}

# Gets the ndbappmysqld indexes that needs to be ignored while verifying
# the ndb_mgm -e show output.  
#
# It requires the following variables to be set:
#   NDBAPP_START_NODE_ID
#   NDBAPP_REPLICA_MAX_COUNT
function get_ndbapp_ignore_indexes() {
    local startNodeId=${NDBAPP_START_NODE_ID}
    local ndbappReplicaCurrentCount=$(get_ndbapp_current_replica_count)
    local ndbappReplicaMaxCount=${NDBAPP_REPLICA_MAX_COUNT}

    local ignoreIndexes=""
    local skip_counter=0
    if [[ $ndbappReplicaCurrentCount -ne $ndbappReplicaMaxCount ]]; then
        for index in $(seq 0 $(($ndbappReplicaMaxCount - 1))); do
            if [[ $skip_counter -ge $ndbappReplicaCurrentCount ]]; then
                if [[ -z $ignoreIndexes ]]; then
                    ignoreIndexes+="id=$(($index+$startNodeId))"
                else
                    ignoreIndexes+="\|id=$(($index+$startNodeId))"
                fi
            fi
            skip_counter=$(($skip_counter+1))
        done
    fi
    if [[ -z $ignoreIndexes ]]; then
        echo "NA"
    else
        echo $ignoreIndexes
    fi
}

# Executs a mysql query and quits. It uses --silence, -s, option, which results
# in nontabular output formant and escaping of special characters. A second -s
# option results in no header.
#
# It requires the following variables to be set:
#   MYSQL_CONNECTIVITY_SERVICE
#   MYSQL_USERNAME
#   MYSQL_PASSWORD
function query_mysql() {
    local query="$@"

    $MYSQL_CMD -h${MYSQL_CONNECTIVITY_SERVICE} -u${MYSQL_USERNAME} -p${MYSQL_PASSWORD} -sse "$query"
}

# It executes a command, and it returns "0" (true) if it outputs anything other than "0".
# Otherwise, it returns "1" (false). In other words, if output == "0" return "1" else return "0".
#
# Note: if the command fails, any output is considered invalid and therefore, not zero,
# so 0 (true) is returned.
#
# @param  cmd - command to test.
#
# @return  0 (true) if output is not zero or if command fails; 1 (false) if output is 0
#
function is_output_not_zero() {
    local _cmd="$@";

    if [[ "$($_cmd || echo 0)" != "0" ]]; then
        return 0;
    else
        return 1;
    fi;
}

# Checks if database.table contains the specified column.
#
# @param  $1 database where to check for table
#
# @param  $2 table where to check for column
#
# @param  $3 column to check for
#
# @return  0 (true) if column exists in mysql table; 1 (false) otherwise.
function is_col_in_table() {
    local database="$1"
    local table="$2"
    local col="$3"

    local query="SELECT COUNT(COLUMN_NAME) FROM information_schema.COLUMNS \
        WHERE TABLE_SCHEMA=\"${database}\" AND \
        TABLE_NAME=\"${table}\" AND \
        COLUMN_NAME=\"${col}\";"

    echo "INFO: $($LOG_DATE_CMD) - query: $query";

    is_output_not_zero query_mysql "$query"
}


# Checks if database.table contains the specified key.
#
# @param  $1 database where to check for table
#
# @param  $2 table where to check for column
#
# @param  $3 column to check for
#
# @return  0 (true) if column exists in mysql table; 1 (false) otherwise.
function is_key_in_table() {
    local database="$1"
    local table="$2"
    local col="$3"

    local query="SELECT COUNT(COLUMN_NAME) FROM information_schema.KEY_COLUMN_USAGE \
        WHERE TABLE_SCHEMA=\"${database}\" AND \
        TABLE_NAME=\"${table}\" AND \
        COLUMN_NAME=\"${col}\";"

    echo "INFO: $($LOG_DATE_CMD) - query: $query";

    is_output_not_zero query_mysql "$query"
}

# Checks if database contains the specified table.
#
# @param  $1 database where to check for table
#
# @param  $2 table to check for
#
# @return  0 (true) if table exists in database; 1 (false) otherwise
function is_table_in_database() {
    local database="$1"
    local table="$2"

    local query="SELECT COUNT(*) FROM information_schema.TABLES \
        WHERE TABLE_SCHEMA=\"${database}\" AND \
        TABLE_NAME=\"${table}\";"

    echo "INFO: $($LOG_DATE_CMD) - query: $query";

    is_output_not_zero query_mysql "$query"
}

# Checks if database exists.
#
# @param  $1 database where to check for table
#
# @return  0 (true) if table exists in database; 1 (false) otherwise
function is_database_exists() {
    local database="$1"

    local query="SELECT COUNT(*) FROM information_schema.TABLES \
        WHERE TABLE_SCHEMA=\"${database}\";"

    echo "INFO: $($LOG_DATE_CMD) - query: $query";

    is_output_not_zero query_mysql "$query"
}


# Removes the "logic" from other parts of the code making it easier to test
function query_if_not() {
    local condition=$1
    shift
    local query="$@"

    if ! $condition; then
        echo "INFO: $($LOG_DATE_CMD) - query: $query";
        query_mysql "$query"
    fi
}

# @param is_condition  The condition to wait for. It can't include "&&" or "||"
#                      If you need "&&" or "||", place them on anoter fuction and pass it.
function wait_for() {
    local is_condition="$@";   # condition to wait for
    local max_wait=${max_wait:-300};   # seconds
    local check_freq=${check_freq:-2};   # seconds
    local return_on_timeout=${return_on_timeout:-1}

    local past_time=0;   # seconds
    while ! ( $is_condition ); do
        $SLEEP_CMD $check_freq;
        ((past_time += check_freq))
        if [ $past_time -ge $max_wait ]; then
            return $return_on_timeout
        fi
    done
}

# Outputs DEBUG log message to standard error, stderr, if env variable
# DBTIER_DEBUG is set.
#
# It uses standard error so that its output doesn't interfere with a
# function's stdout if it is piped to another command.
#
# DEPENDS ON
#     DBTIER_DEBUG
#
# @param message  String to output to the stderr.
#
# @return  0.
function debug() {
    if [ ! -z ${DBTIER_DEBUG+x} ]; then
        1>&2 echo -e "$($LOG_DATE_CMD) DEBUG - $@";
    fi
}

function is_command() {
    command -v "$1" >/dev/null
}

function set_use_ndb_mgm() {
    if is_command ndb_mgm && test_ndb_mgm; then
        USE_NDB_MGM_CMD="true"
    else
        USE_NDB_MGM_CMD="false"
    fi
}

function test_ndb_mgm() {
    $NDB_MGM_CMD -c $NDB_MGMD_CONNECTSTRING -e SHOW >/dev/null 2>&1
}

function exec_cmd_in_pod() {
    local pod="$1"
    shift
    local container="$1"
    shift
    local cmd="$@"

    debug "$KCTL exec -c $container $pod -- bash -c \"$cmd\""
    $KCTL exec -c $container $pod -- bash -c "$cmd"
}

# It gets the pod containers.
#
# @param pod  Pod name; it will get its containers.
function get_containers() {
    local pod="$1"

    $KCTL describe pod $pod | \
        $SED_CMD -n -E '/^Containers:/,/^Conditions:/ {/^  [[:alpha:]]/ s/  (.*):.*/\1/p }'
}

function ndb_mgm_show() {
    if [[ "$USE_NDB_MGM_CMD" == "true" ]]; then
        $NDB_MGM_CMD -c $NDB_MGMD_CONNECTSTRING -e SHOW 2>&1
    else
        local pod="$(echo $NDB_MGMD_PODS | awk '{print $1}')"
        local container=$(get_containers "$pod" | $GREP_CMD "$DBTIER_MAIN_MGM_POD_CONTAINER")
        local cmd="$NDB_MGM_CMD -e SHOW"

        exec_cmd_in_pod "$pod" "$container" "$cmd"
    fi
}

function is_mgm_up() {
    ndb_mgm_show > /dev/null
}

function are_all_nodes_connected_and_started() {
    ! ndb_mgm_show | $GREP_CMD -v "${API_EMP_TRY_SLOTS_NODE_IDS}" | $GREP_CMD -v "$(get_ndbapp_ignore_indexes)" | $GREP_CMD -q -e 'not connected' -e 'starting'
}

function is_mgm_up_and_nodes_started() {
    is_mgm_up && are_all_nodes_connected_and_started
}

function wait_for_nodes_to_reconnect_to_mgm() {
    local max_wait=${max_wait:-150};   # seconds
    wait_for is_mgm_up_and_nodes_started
}

# @return  The MGM nodes version of mysql from the output of ndb_mgmd -e SHOW
function mysqlver() {
    ndb_mgm_show | $SED_CMD -n '/\[ndb_mgmd(MGM)\]/,/^$/ { s/^.\+mysql-\([^ ]\+\) .*$/\1/p }' | $HEAD_CMD -1
}

# Converts a MySQL version to a number that can be easily compared to another
# version number.
#
# @arg  mysqlver  Three numbers separated by a period, i.e. 8.0.33
#
# @return  A number made of the version numbers: 'printf("%d%03d%03d\n", $1,$2,$3);'
#          i.e. 8000030
function version_to_num() {
    echo "$@" | $AWK_CMD -F. '{ printf("%d%03d%03d\n", $1,$2,$3); }';
}

# The versions must be 3 numbers separated by a period, and the second and
# third number must not be greater than 999. If the version doesn't follow
# format, this function will NOT delete the PVCs.
# @arg  from_version  MySQL version before the rollback
#
# @arg  to_version  MySQL version after the rollback
#
# @return 0  Always returns 0
function del_mysqld_pvcs_if_rolling_to_older_ver() {
    local from_version="$1"
    local to_version="$2"

    if echo $from_version | grep -v -q "^[[:digit:]]\+.[[:digit:]]\{1,3\}.[[:digit:]]\{1,3\}$"; then
        1>&2 echo "ERROR: $($LOG_DATE_CMD) - wrong format: from_version=${from_version}"
        echo "INFO: $($LOG_DATE_CMD) - skipping PVC deletion..."
        return 0;
    fi

    if echo $to_version | grep -v -q "^[[:digit:]]\+.[[:digit:]]\{1,3\}.[[:digit:]]\{1,3\}$"; then
        1>&2 echo "ERROR: $($LOG_DATE_CMD) - wrong format: to_version=${to_version}"
        echo "INFO: $($LOG_DATE_CMD) - skipping PVC deletion..."
        return 0;
    fi

    if [ $(version_to_num ${from_version}) -gt $(version_to_num ${to_version}) ]; then
        delete_mysqld_pvcs
    fi
}

function add_col_start_ts_to_repl_channel_info() {
    local query="ALTER TABLE ${DBTIER_REPLICATION_SVC_DATABASE}.DBTIER_REPLICATION_CHANNEL_INFO \
        ADD start_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP;"

    query_if_not "is_col_in_table ${DBTIER_REPLICATION_SVC_DATABASE} DBTIER_REPLICATION_CHANNEL_INFO start_ts" "$query"
}

function add_col_creation_ts_to_backup_info() {
    local query="ALTER TABLE ${DBTIER_BACKUP_SVC_DATABASE}.DBTIER_BACKUP_INFO \
        ADD creation_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP; \
        UPDATE ${DBTIER_BACKUP_SVC_DATABASE}.DBTIER_BACKUP_INFO \
        SET creation_ts=STR_TO_DATE(backup_id, '%y%m%d%H%i') \
        WHERE convert(substring(convert((case when length(convert(backup_id, char)) < 10 then \
        concat('0',convert(backup_id, char))else convert(backup_id, char) end), char),1, 2), DECIMAL) > 12;"

    query_if_not "is_col_in_table ${DBTIER_BACKUP_SVC_DATABASE} DBTIER_BACKUP_INFO creation_ts" "$query"
}

function add_col_dr_state_to_replication_site_info() {
    local query="ALTER TABLE ${DBTIER_REPLICATION_SVC_DATABASE}.DBTIER_REPL_SITE_INFO \
        ADD dr_state varchar(64) DEFAULT NULL;"

    query_if_not "is_col_in_table ${DBTIER_REPLICATION_SVC_DATABASE} DBTIER_REPL_SITE_INFO dr_state" "$query"
}

function add_col_stop_replication_mysqlds_to_site_info() {
    local query="ALTER TABLE ${DBTIER_REPLICATION_SVC_DATABASE}.DBTIER_SITE_INFO \
        ADD stop_replication_mysqlds INT NULL; \
        UPDATE ${DBTIER_REPLICATION_SVC_DATABASE}.DBTIER_SITE_INFO SET stop_replication_mysqlds=0 WHERE stop_replication_mysqlds IS NULL;"

    query_if_not "is_col_in_table ${DBTIER_REPLICATION_SVC_DATABASE} DBTIER_SITE_INFO stop_replication_mysqlds" "$query"
}

function add_col_site_name_to_replication_channel_info() {
    local query="ALTER TABLE ${DBTIER_REPLICATION_SVC_DATABASE}.DBTIER_REPLICATION_CHANNEL_INFO \
        ADD site_name VARCHAR(64) NULL; \
        UPDATE ${DBTIER_REPLICATION_SVC_DATABASE}.DBTIER_REPLICATION_CHANNEL_INFO a \
        INNER JOIN ${DBTIER_REPLICATION_SVC_DATABASE}.DBTIER_REPLICATION_CHANNEL_INFO b \
        ON a.channel_id = b.channel_id AND a.remote_site_name != b.remote_site_name \
        SET a.site_name=b.remote_site_name; \
        ALTER TABLE ${DBTIER_REPLICATION_SVC_DATABASE}.DBTIER_REPLICATION_CHANNEL_INFO \
        CHANGE site_name site_name VARCHAR(64) NOT NULL;"

    query_if_not "is_col_in_table ${DBTIER_REPLICATION_SVC_DATABASE} DBTIER_REPLICATION_CHANNEL_INFO site_name" "$query"
}

function add_col_server_id_to_replication_channel_info() {
    local query="ALTER TABLE ${DBTIER_REPLICATION_SVC_DATABASE}.DBTIER_REPLICATION_CHANNEL_INFO \
    ADD server_id int NULL; \
    UPDATE ${DBTIER_REPLICATION_SVC_DATABASE}.DBTIER_REPLICATION_CHANNEL_INFO a \
    INNER JOIN ${DBTIER_REPLICATION_SVC_DATABASE}.DBTIER_REPLICATION_CHANNEL_INFO b \
    ON a.channel_id = b.channel_id AND a.remote_server_id != b.remote_server_id \
    SET a.server_id=b.remote_server_id; \
    ALTER TABLE ${DBTIER_REPLICATION_SVC_DATABASE}.DBTIER_REPLICATION_CHANNEL_INFO \
    CHANGE server_id server_id INT NOT NULL;"

    query_if_not "is_col_in_table ${DBTIER_REPLICATION_SVC_DATABASE} DBTIER_REPLICATION_CHANNEL_INFO server_id" "$query"
}

function update_primary_key_constraint_for_replication_channel_info() {
    local query="ALTER TABLE ${DBTIER_REPLICATION_SVC_DATABASE}.DBTIER_REPLICATION_CHANNEL_INFO \
        DROP PRIMARY KEY, ADD PRIMARY KEY(remote_server_id);"

    query_if_not "is_key_in_table ${DBTIER_REPLICATION_SVC_DATABASE} DBTIER_REPLICATION_CHANNEL_INFO remote_server_id" "$query"
}

function create_table_backup_transfer_info() {
    local query="CREATE TABLE IF NOT EXISTS ${DBTIER_BACKUP_SVC_DATABASE}.DBTIER_BACKUP_TRANSFER_INFO ( \
        site_name VARCHAR(64) NOT NULL, \
        cluster_id INT NOT NULL, \
        backup_id BIGINT(20) NOT NULL, \
        node_id INT NOT NULL, \
        replication_svc_ip VARCHAR(255) NOT NULL, \
        remote_replication_svc_ip VARCHAR(255), \
        transfer_status VARCHAR(100), \
        remote_transfer_status VARCHAR(100), \
        CONSTRAINT DBTIER_BACKUP_TRANSFER_INFO_pk PRIMARY KEY (site_name, backup_id, node_id));"

    query_if_not "is_table_in_database ${DBTIER_BACKUP_SVC_DATABASE} DBTIER_BACKUP_TRANSFER_INFO" "$query"
}

function create_table_site_info() {
    local query="CREATE TABLE IF NOT EXISTS ${DBTIER_REPLICATION_SVC_DATABASE}.DBTIER_SITE_INFO ( \
        site_name VARCHAR(64) NOT NULL, \
        site_id INT NOT NULL, \
        dr_state VARCHAR(64) NOT NULL, \
        dr_backup_site_name VARCHAR(64) DEFAULT NULL, \
        backup_id VARCHAR(64) DEFAULT NULL, \
        CONSTRAINT DBTIER_SITE_INFO_pk PRIMARY KEY (site_name) \
        ) ENGINE=NDBCLUSTER;"

    query_if_not "is_table_in_database ${DBTIER_REPLICATION_SVC_DATABASE} DBTIER_SITE_INFO" "$query"
}

function add_col_replchannel_group_id_to_replication_site_info() {
    local query="ALTER TABLE ${DBTIER_REPLICATION_SVC_DATABASE}.DBTIER_REPL_SITE_INFO \
        ADD COLUMN replchannel_group_id int; \
        UPDATE ${DBTIER_REPLICATION_SVC_DATABASE}.DBTIER_REPL_SITE_INFO \
        SET replchannel_group_id = 1 WHERE replchannel_group_id = 0 \
        OR replchannel_group_id IS NULL;"
    
    query_if_not "is_col_in_table ${DBTIER_REPLICATION_SVC_DATABASE} DBTIER_REPL_SITE_INFO replchannel_group_id" "$query"
}

function update_primary_key_constraint_for_replication_site_info() {
    local query="ALTER TABLE ${DBTIER_REPLICATION_SVC_DATABASE}.DBTIER_REPL_SITE_INFO \
        DROP PRIMARY KEY, ADD PRIMARY KEY(site_name, mate_site_name, replchannel_group_id);"

    query_if_not "is_key_in_table ${DBTIER_REPLICATION_SVC_DATABASE} DBTIER_REPL_SITE_INFO replchannel_group_id" "$query"
}

function add_col_replchannel_group_id_to_replication_channel_info() {
    local query="ALTER TABLE ${DBTIER_REPLICATION_SVC_DATABASE}.DBTIER_REPLICATION_CHANNEL_INFO \
        ADD COLUMN replchannel_group_id int; \
        UPDATE ${DBTIER_REPLICATION_SVC_DATABASE}.DBTIER_REPLICATION_CHANNEL_INFO \
        SET replchannel_group_id = 1 WHERE replchannel_group_id = 0 \
        OR replchannel_group_id IS NULL ; "

    query_if_not "is_col_in_table ${DBTIER_REPLICATION_SVC_DATABASE} DBTIER_REPLICATION_CHANNEL_INFO replchannel_group_id" "$query"
    
}

function add_col_hbfailure_to_hbreplica() {
    DBTIER_HBREPLICAGROUP_DATABASE=${DBTIER_HBREPLICAGROUP_DATABASE};
    GROUPID=1;

    while [ ${GROUPID} -le ${REPLCHANNEL_GROUP_COUNT} ]
    do
        DBTIER_REPLICAGROUP_GROUPID_DATABASE="${DBTIER_HBREPLICAGROUP_DATABASE}${GROUPID}"
        if [ ${GROUPID} -eq 1 ]; then
            DBTIER_REPLICAGROUP_GROUPID_DATABASE="${DBTIER_HBREPLICAGROUP_DATABASE}"
        fi

        local query="ALTER TABLE ${DBTIER_REPLICAGROUP_GROUPID_DATABASE}.DBTIER_HEARTBEAT_INFO \
        ADD COLUMN hbfailure int; \
        UPDATE ${DBTIER_REPLICAGROUP_GROUPID_DATABASE}.DBTIER_HEARTBEAT_INFO \
        SET hbfailure = 0 WHERE hbfailure <> 0 \
        OR hbfailure IS NULL ; "
        
        query_if_not "is_col_in_table ${DBTIER_REPLICAGROUP_GROUPID_DATABASE} DBTIER_HEARTBEAT_INFO hbfailure" "$query"

        GROUPID=`expr $GROUPID + 1`
    done
}

# Checks if all schemas are present for replication service
#
# @return  0 (true) if replication schema exists; 1 (false) otherwise
function create_databases_table_hbreplica() {
    DBTIER_HBREPLICAGROUP_DATABASE=${DBTIER_HBREPLICAGROUP_DATABASE};
    GROUPID=1;

    while [ ${GROUPID} -le ${REPLCHANNEL_GROUP_COUNT} ]
    do
        DBTIER_REPLICAGROUP_GROUPID_DATABASE="${DBTIER_HBREPLICAGROUP_DATABASE}${GROUPID}"
        if [ ${GROUPID} -eq 1 ]; then
            DBTIER_REPLICAGROUP_GROUPID_DATABASE="${DBTIER_HBREPLICAGROUP_DATABASE}"
        fi
        echo "INFO: $($LOG_DATE_CMD) - creating $DBTIER_REPLICAGROUP_GROUPID_DATABASE database for group id: ${GROUPID}";
        
        dbcreateQuery="CREATE DATABASE IF NOT EXISTS ${DBTIER_REPLICAGROUP_GROUPID_DATABASE};"
        query_if_not "is_database_exists ${DBTIER_REPLICAGROUP_GROUPID_DATABASE}" "$dbcreateQuery"

        tablecreateQuery="CREATE TABLE IF NOT EXISTS ${DBTIER_REPLICAGROUP_GROUPID_DATABASE}.DBTIER_HEARTBEAT_INFO ( \
                site_name VARCHAR(64) NOT NULL, \
                mate_site_name VARCHAR(64) NOT NULL, \
                replchannel_group_id INT NOT NULL, \
                updated_timestamp datetime DEFAULT NULL, \
                CONSTRAINT DBTIER_HEARTBEAT_INFO_pk PRIMARY KEY (site_name, mate_site_name, replchannel_group_id) \
                ) ENGINE=NDBCLUSTER;"

        query_if_not "is_table_in_database ${DBTIER_REPLICAGROUP_GROUPID_DATABASE} DBTIER_HEARTBEAT_INFO" "$tablecreateQuery"
		
        GROUPID=`expr $GROUPID + 1`
    done
}


function create_table_repl_error_skip_info() {

    local query="CREATE TABLE IF NOT EXISTS ${DBTIER_REPLICATION_SVC_DATABASE}.DBTIER_REPL_ERROR_SKIP_INFO ( \
        site_name VARCHAR(64) NOT NULL, \
        mate_site_name VARCHAR(64) NOT NULL, \
        replchannel_group_id INT NOT NULL, \
        replication_error_number INT NOT NULL, \
        replication_skiperror_count INT NOT NULL, \
        epochs_lost INT NOT NULL, \
        total_replication_skiperror_count INT NOT NULL, \
        total_epochs_lost INT NOT NULL, \
        skiperror_window_ts datetime DEFAULT CURRENT_TIMESTAMP, \
        CONSTRAINT DBTIER_REPL_ERROR_SKIP_INFO_pk PRIMARY KEY (site_name, mate_site_name, replchannel_group_id, replication_error_number) \
        ) ENGINE=NDBCLUSTER;"

    query_if_not "is_table_in_database ${DBTIER_REPLICATION_SVC_DATABASE} DBTIER_REPL_ERROR_SKIP_INFO" "$query"
}

function create_table_repl_event_info() {

    local query="CREATE TABLE IF NOT EXISTS ${DBTIER_REPLICATION_SVC_DATABASE}.DBTIER_REPL_EVENT_INFO ( \
        site_name VARCHAR(64) NOT NULL, \
        mate_site_name VARCHAR(64) NOT NULL, \
        replchannel_group_id INT, \
        event_id INT NOT NULL AUTO_INCREMENT, \
        event_type INT, \
        event_ts DATETIME, \
        event_description TEXT, \
        CONSTRAINT DBTIER_REPL_EVENT_INFO_pk PRIMARY KEY (site_name, mate_site_name, replchannel_group_id, event_id) \
        ) ENGINE=NDBCLUSTER;"

    query_if_not "is_table_in_database ${DBTIER_REPLICATION_SVC_DATABASE} DBTIER_REPL_EVENT_INFO" "$query"
}

function create_table_ndb_replication() {
    local query="CREATE TABLE IF NOT EXISTS mysql.ndb_replication ( \
                db VARBINARY(63), \
                table_name VARBINARY(63), \
                server_id INT UNSIGNED, \
                binlog_type INT UNSIGNED, \
                conflict_fn VARBINARY(128), \
                PRIMARY KEY USING HASH (db, table_name, server_id) \
                ) ENGINE=NDB \
                PARTITION BY KEY(db,table_name);"
    query_if_not "is_table_in_database mysql ndb_replication" "$query"
}


function upgrade_schema() {
    echo "INFO: $($LOG_DATE_CMD) - MYSQL_CONNECTIVITY_SERVICE: ${MYSQL_CONNECTIVITY_SERVICE}"
    echo "INFO: $($LOG_DATE_CMD) - MYSQL_USERNAME: ${MYSQL_USERNAME}"
    echo "INFO: $($LOG_DATE_CMD) - DBTIER_BACKUP_SVC_DATABASE: ${DBTIER_BACKUP_SVC_DATABASE}"
    echo "INFO: $($LOG_DATE_CMD) - DBTIER_REPLICATION_SVC_DATABASE: ${DBTIER_REPLICATION_SVC_DATABASE}"

    add_col_dr_state_to_replication_site_info
    add_col_site_name_to_replication_channel_info
    add_col_server_id_to_replication_channel_info
    add_col_start_ts_to_repl_channel_info
    update_primary_key_constraint_for_replication_channel_info
    add_col_creation_ts_to_backup_info
    create_table_backup_transfer_info
    create_table_site_info
    add_col_replchannel_group_id_to_replication_channel_info
    add_col_replchannel_group_id_to_replication_site_info
    update_primary_key_constraint_for_replication_site_info
    create_databases_table_hbreplica
    create_table_ndb_replication
    create_table_repl_error_skip_info
    create_table_repl_event_info
    add_col_stop_replication_mysqlds_to_site_info
    add_col_hbfailure_to_hbreplica
}

function set_updateStrategy_to_RollingUpdate() {
    echo "INFO: $($LOG_DATE_CMD) - Patching updateStrategies..."
    $KUBECTL_CMD -n $OCCNE_NAMESPACE patch sts ${NDB_STS_NAME} -p '{"spec":{"updateStrategy":{"type":"RollingUpdate"}}}' || true
    $KUBECTL_CMD -n $OCCNE_NAMESPACE patch sts ${API_STS_NAME} -p '{"spec":{"updateStrategy":{"type":"RollingUpdate"}}}' || true
    $KUBECTL_CMD -n $OCCNE_NAMESPACE patch sts ${APP_STS_NAME} -p '{"spec":{"updateStrategy":{"type":"RollingUpdate"}}}' || true
    echo "INFO: $($LOG_DATE_CMD) - UpdateStrategies patched"
}

function delete_mysqld_pvcs() {
    local pvcs=$($KUBECTL_CMD -n $OCCNE_NAMESPACE get pvc | $GREP_CMD mysqld | $CUT_CMD -d' ' -f1)
    echo "INFO: $($LOG_DATE_CMD) - Deleting PVCs: ${pvcs}..."
    $KUBECTL_CMD -n $OCCNE_NAMESPACE delete pvc $pvcs &
    echo "INFO: $($LOG_DATE_CMD) - mysqld PVCs deleted"
}

function save_ndb_configs_for_initial_restart_to_file() {
    local file_name=$1
    local mgmd_pod="$(echo $NDB_MGMD_PODS | awk '{print $1}')"
    local mgmd_container=$(get_containers "$mgmd_pod" | $GREP_CMD "$DBTIER_MAIN_MGM_POD_CONTAINER")

    $KUBECTL_CMD -n ${OCCNE_NAMESPACE} exec pod/${mgmd_pod} -c ${mgmd_container} -- cat ${NDB_MGMD_BASE_DATADIR}/${file_name} | sort | grep ${NDB_CONFIGS_THAT_NEED_RESTART_TYPE_INITIAL} | uniq > $file_name
}

function is_both_files_content_equal() {
    local file_one=$1
    local file_two=$2

    # Remove empty lines, trim leading and trailing spaces and tabs, and sort the lines of a file in alphabetical order 
    sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/[[:space:]]\+//g' -e '/^$/d' $file_one | sort > temp_file_one_sorted.conf
    sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/[[:space:]]\+//g' -e '/^$/d' $file_two | sort > temp_file_two_sorted.conf

    # Compare the two files
    if cmp -s temp_file_one_sorted.conf temp_file_two_sorted.conf; then
        return 0
    else 
        return 1
    fi
}

function remove_file_from_mgm_pod_zero() {
    local file_path=$1

    local mgmd_pod="$(echo $NDB_MGMD_PODS | awk '{print $1}')"
    local mgmd_container=$(get_containers "$mgmd_pod" | $GREP_CMD "$DBTIER_MAIN_MGM_POD_CONTAINER")

    $KUBECTL_CMD -n ${OCCNE_NAMESPACE} exec pod/${mgmd_pod} -c ${mgmd_container} -- rm -rf $file_path
}


function print_help() {
    cat <<EOF
NAME
    $(basename $0) - description...

SYNOPSIS
    $(basename $0) [-h | --help]

    $(basename $0) --schema-upgrade

    export OCCNE_NAMESPACE="<namespace>"
    export NDB_STS_NAME="<ndbmtd sts>"
    export API_STS_NAME="<ndbmysqld sts>"
    export APP_STS_NAME="<ndbappmysqld sts>"
    $(basename $0) --post-install

    export OCCNE_NAMESPACE="<namespace>"
    export NDB_MGMD_PODS="<ndbmgmd pods separated by a space>"
    $(basename $0) --pre-upgrade

    export OCCNE_NAMESPACE="<namespace>"
    export API_EMP_TRY_SLOTS_NODE_IDS="<empty try node IDs separated by '\|' (i.e. "id=222\|id=223")>"
    export NDB_MGMD_PODS="<ndbmgmd pods separated by a space>"
    export NDB_MTD_PODS="<ndbmtd pods separated by a space>"
    export NDB_STS_NAME="<ndbmtd sts>"
    export API_STS_NAME="<ndbmysqld sts>"
    export APP_STS_NAME="<ndbappmysqld sts>"
    export NDBAPP_START_NODE_ID="<as configured in values.yaml: global.ndbapp.startNodeId>"
    export NDBAPP_REPLICA_MAX_COUNT="<as configured in values.yaml: global.ndbappReplicaMaxCount>"
    $(basename $0) --post-upgrade

    export OCCNE_NAMESPACE="<namespace>"
    export API_EMP_TRY_SLOTS_NODE_IDS="<empty try node IDs separated by '\|' (i.e. "id=222\|id=223")>"
    export NDB_MGMD_PODS="<ndbmgmd pods separated by a space>"
    export NDB_STS_NAME="<ndbmtd sts>"
    export API_STS_NAME="<ndbmysqld sts>"
    export APP_STS_NAME="<ndbappmysqld sts>"
    export NDBAPP_START_NODE_ID="<as configured in values.yaml: global.ndbapp.startNodeId>"
    export NDBAPP_REPLICA_MAX_COUNT="<as configured in values.yaml: global.ndbappReplicaMaxCount>"
    $(basename $0) --post-rollback

OPTIONS
    -h | --help
        Print this help message and exit.

    --schema-upgrade
        Run schema upgrade code.

    --post-install
        Run post-install code. It patches upgradeStrategy.

    --pre-upgrade
        Run pre-upgrade code. It saves the ndb configs before cnDBTier upgrade. 

    --post-upgrade
        Run post-upgrade code. It deletes all MGM pods, waits for them
        to comeup, and patches upgradeStrategy.

    --post-rollback
        Run post-rollback code. It deletes all MGM pods, waits for them
        to comeup, deletes mysqld PVCs if rolling back to an earlier
        mysql version, and patches upgradeStrategy.

ENVIRONMENT VARIABLES
    The following envirionment variables are required by the different options:

    --post-install
        OCCNE_NAMESPACE - namespace
        NDB_STS_NAME - ndbmtd sts
        API_STS_NAME - ndbmysqld sts
        APP_STS_NAME - ndbappmysqld sts

    --pre-upgrade
        OCCNE_NAMESPACE - namespace
        NDB_MGMD_PODS - dbmgmd pods separated by a space

    --post-upgrade
        OCCNE_NAMESPACE - namespace
        API_EMP_TRY_SLOTS_NODE_IDS - empty try node IDs separated by '\|' (i.e. "id=222\|id=223")
        NDB_MGMD_PODS - dbmgmd pods separated by a space
        NDB_MTD_PODS - dbmtd pods separated by a space
        NDB_STS_NAME - ndbmtd sts
        API_STS_NAME - ndbmysqld sts
        APP_STS_NAME - ndbappmysqld sts
        NDBAPP_START_NODE_ID - as configured in values.yaml: global.ndbapp.startNodeId
        NDBAPP_REPLICA_MAX_COUNT - as configured in values.yaml: global.ndbappReplicaMaxCount

    --post-rollback
        OCCNE_NAMESPACE - namespace
        API_EMP_TRY_SLOTS_NODE_IDS - empty try node IDs separated by '\|' (i.e. "id=222\|id=223")
        NDB_MGMD_PODS - dbmgmd pods separated by a space
        NDB_STS_NAME - ndbmtd sts
        API_STS_NAME - ndbmysqld sts
        APP_STS_NAME - ndbappmysqld sts
        NDBAPP_START_NODE_ID - as configured in values.yaml: global.ndbapp.startNodeId
        NDBAPP_REPLICA_MAX_COUNT - as configured in values.yaml: global.ndbappReplicaMaxCount

EXAMPLE

    Print this help message and exit.
        $(basename $0) --help


    Run schema upgrade code.

        $(basename $0) --schema-upgrade


    Run post-install code. It patches upgradeStrategy.

        export OCCNE_NAMESPACE="occne-cndbtier"
        export NDB_STS_NAME="ndbmtd"
        export API_STS_NAME="ndbmysqld"
        export APP_STS_NAME="ndbappmysqld"

        $(basename $0) --post-install

    Run pre-upgrade code. It saves the ndb configuration that has been used before upgrade.

        export OCCNE_NAMESPACE="occne-cndbtier"
        export NDB_MGMD_PODS="ndbmgmd-0 ndbmgmd-1"

        $(basename $0) --pre-upgrade

    Run post-upgrade code. It deletes all MGM pods, waits for them to comeup, and
    patches upgradeStrategy.

        export OCCNE_NAMESPACE="occne-cndbtier"
        export API_EMP_TRY_SLOTS_NODE_IDS="id=222\|id=223"
        export NDB_MGMD_PODS="ndbmgmd-0 ndbmgmd-1"
        export NDB_STS_NAME="ndbmtd"
        export API_STS_NAME="ndbmysqld"
        export APP_STS_NAME="ndbappmysqld"
        export NDBAPP_START_NODE_ID="70"
        export NDBAPP_REPLICA_MAX_COUNT="4"
        export NDB_MTD_PODS="ndbmtd-0 ndbmtd-1"

        $(basename $0) --post-upgrade


    Run post-rollback code. It deletes all MGM pods, waits for them to comeup,
    deletes mysqld PVCs if rolling back to an earlier mysql version, and
    patches upgradeStrategy.

        export OCCNE_NAMESPACE="occne-cndbtier"
        export API_EMP_TRY_SLOTS_NODE_IDS="id=222\|id=223"
        export NDB_MGMD_PODS="ndbmgmd-0 ndbmgmd-1"
        export NDB_MTD_PODS="ndbmtd-0 ndbmtd-1"
        export NDB_STS_NAME="ndbmtd"
        export API_STS_NAME="ndbmysqld"
        export APP_STS_NAME="ndbappmysqld"
        export NDBAPP_START_NODE_ID="70"
        export NDBAPP_REPLICA_MAX_COUNT="4"

        $(basename $0) --post-rollback

EOF
}

function main() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        print_help
        return 0
    fi

    set_use_ndb_mgm

    if [[ "$1" == "--schema-upgrade" ]]; then
        echo "INFO: $($LOG_DATE_CMD) - Schema update inprogress..."
        upgrade_schema
        echo "INFO: $($LOG_DATE_CMD) - Schema updated"
        return 0;
    fi

    if [[ "$1" == "--post-install" ]]; then
        echo "INFO: $($LOG_DATE_CMD) - OCCNE_NAMESPACE=${OCCNE_NAMESPACE}"
        echo "INFO: $($LOG_DATE_CMD) - NDB_STS_NAME=${NDB_STS_NAME}"
        echo "INFO: $($LOG_DATE_CMD) - API_STS_NAME=${API_STS_NAME}"
        echo "INFO: $($LOG_DATE_CMD) - APP_STS_NAME=${APP_STS_NAME}"

        set_updateStrategy_to_RollingUpdate

        return 0
    fi

    if [[ "$1" == "--pre-upgrade" ]]; then
        echo "INFO: $($LOG_DATE_CMD) - OCCNE_NAMESPACE=${OCCNE_NAMESPACE}"
        echo "INFO: $($LOG_DATE_CMD) - NDB_MGMD_PODS=${NDB_MGMD_PODS}"
        echo "INFO: $($LOG_DATE_CMD) - NDBMGMD_CONTAINER_NAME=${NDBMGMD_CONTAINER_NAME}"
        echo "INFO: $($LOG_DATE_CMD) - NDB_MGMD_BASE_DATADIR=${NDB_MGMD_BASE_DATADIR}"
        echo "INFO: $($LOG_DATE_CMD) - NDBMTD_CONTAINER_NAME=${NDBMTD_CONTAINER_NAME}"
        echo "INFO: $($LOG_DATE_CMD) - NDB_CONFIG_FILE_NAME_BEFORE_UPGRADE=${NDB_CONFIG_FILE_NAME_BEFORE_UPGRADE}"

        echo "INFO: $($LOG_DATE_CMD) - Taking backup of the ndb-cluster.cnf file to location ${NDB_MGMD_BASE_DATADIR}/${NDB_CONFIG_FILE_NAME_BEFORE_UPGRADE} before upgrade"

        local mgmd_pod="$(echo $NDB_MGMD_PODS | awk '{print $1}')"
        local mgmd_container=$(get_containers "$mgmd_pod" | $GREP_CMD "$DBTIER_MAIN_MGM_POD_CONTAINER")

        $KUBECTL_CMD -n ${OCCNE_NAMESPACE} exec pod/${mgmd_pod} -c ${mgmd_container} -- cp /etc/ndbconf/ndb-cluster.cnf ${NDB_MGMD_BASE_DATADIR}/${NDB_CONFIG_FILE_NAME_BEFORE_UPGRADE}

        return 0
    fi


    if [[ "$1" == "--post-upgrade" ]]; then
        echo "INFO: $($LOG_DATE_CMD) - OCCNE_NAMESPACE=${OCCNE_NAMESPACE}"
        echo "INFO: $($LOG_DATE_CMD) - API_EMP_TRY_SLOTS_NODE_IDS=${API_EMP_TRY_SLOTS_NODE_IDS}"
        echo "INFO: $($LOG_DATE_CMD) - NDB_MGMD_PODS=${NDB_MGMD_PODS}"
        echo "INFO: $($LOG_DATE_CMD) - NDB_MTD_PODS=${NDB_MTD_PODS}"
        echo "INFO: $($LOG_DATE_CMD) - NDB_STS_NAME=${NDB_STS_NAME}"
        echo "INFO: $($LOG_DATE_CMD) - API_STS_NAME=${API_STS_NAME}"
        echo "INFO: $($LOG_DATE_CMD) - APP_STS_NAME=${APP_STS_NAME}"
        echo "INFO: $($LOG_DATE_CMD) - NDBAPP_START_NODE_ID=${NDBAPP_START_NODE_ID}"
        echo "INFO: $($LOG_DATE_CMD) - NDBAPP_REPLICA_MAX_COUNT=${NDBAPP_REPLICA_MAX_COUNT}"
        echo "INFO: $($LOG_DATE_CMD) - NDBMTD_CONTAINER_NAME=${NDBMTD_CONTAINER_NAME}"
        echo "INFO: $($LOG_DATE_CMD) - NDBMGMD_CONTAINER_NAME=${NDBMGMD_CONTAINER_NAME}"
        echo "INFO: $($LOG_DATE_CMD) - NDB_CONFIGS_THAT_NEED_RESTART_TYPE_INITIAL=${NDB_CONFIGS_THAT_NEED_RESTART_TYPE_INITIAL}"
        echo "INFO: $($LOG_DATE_CMD) - NDB_MGMD_BASE_DATADIR=${NDB_MGMD_BASE_DATADIR}"
        echo "INFO: $($LOG_DATE_CMD) - NDB_CONFIG_FILE_NAME_AFTER_UPGRADE=${NDB_CONFIG_FILE_NAME_AFTER_UPGRADE}"
        echo "INFO: $($LOG_DATE_CMD) - NDB_CONFIG_FILE_NAME_BEFORE_UPGRADE=${NDB_CONFIG_FILE_NAME_BEFORE_UPGRADE}"
        echo "INFO: $($LOG_DATE_CMD) - skip empty api slot ids = ${API_EMP_TRY_SLOTS_NODE_IDS}"

        echo "INFO: $($LOG_DATE_CMD) - Deleting MGM pods..."
        $KUBECTL_CMD -n $OCCNE_NAMESPACE delete pod $NDB_MGMD_PODS
        echo "INFO: $($LOG_DATE_CMD) - MGM pods deleted"

        echo "INFO: $($LOG_DATE_CMD) - Waiting for nodes to reconnect to MGMs..."
        wait_for_nodes_to_reconnect_to_mgm
        echo "INFO: $($LOG_DATE_CMD) - Nodes reconnected"

        echo "INFO: $($LOG_DATE_CMD) - Taking backup of the ndb-cluster.cnf file to location ${NDB_MGMD_BASE_DATADIR}/${NDB_CONFIG_FILE_NAME_AFTER_UPGRADE} after upgrade"

        local mgmd_pod="$(echo $NDB_MGMD_PODS | awk '{print $1}')"
        local mgmd_container=$(get_containers "$mgmd_pod" | $GREP_CMD "$DBTIER_MAIN_MGM_POD_CONTAINER")

        $KUBECTL_CMD -n ${OCCNE_NAMESPACE} exec pod/${mgmd_pod} -c ${mgmd_container} -- cp /etc/ndbconf/ndb-cluster.cnf ${NDB_MGMD_BASE_DATADIR}/${NDB_CONFIG_FILE_NAME_AFTER_UPGRADE}

        save_ndb_configs_for_initial_restart_to_file ${NDB_CONFIG_FILE_NAME_BEFORE_UPGRADE}
        echo "INFO: $($LOG_DATE_CMD) - Saved the ndb configuration in the file ${NDB_CONFIG_FILE_NAME_BEFORE_UPGRADE}"

        save_ndb_configs_for_initial_restart_to_file ${NDB_CONFIG_FILE_NAME_AFTER_UPGRADE}
        echo "INFO: $($LOG_DATE_CMD) - Saved the ndb configuration in the file ${NDB_CONFIG_FILE_NAME_AFTER_UPGRADE}"

        echo "INFO: $($LOG_DATE_CMD) - Compairing ${NDB_CONFIG_FILE_NAME_BEFORE_UPGRADE} and ${NDB_CONFIG_FILE_NAME_AFTER_UPGRADE}"
        is_both_files_content_equal ${NDB_CONFIG_FILE_NAME_BEFORE_UPGRADE} ${NDB_CONFIG_FILE_NAME_AFTER_UPGRADE}
        if [[ "$?" -eq "1"  ]]; then
            # We need to go for --initial node restart
            echo "INFO: $($LOG_DATE_CMD) - ndbmtd pods will be restarted with --initial"
            for ndbmtd_pod_name in ${NDB_MTD_PODS}; do
                local ndbmtd_container=$(get_containers "$ndbmtd_pod_name" | $GREP_CMD "$DBTIER_MAIN_NDB_POD_CONTAINER")
                $KUBECTL_CMD exec pod/$ndbmtd_pod_name --namespace=${OCCNE_NAMESPACE} -c ${ndbmtd_container} -- sh -c  "touch /var/occnedb/useinitial && chmod 777 /var/occnedb/useinitial"
                echo "INFO: $($LOG_DATE_CMD) - $ndbmtd_pod_name has been configured for restart with --initial"
            done
        fi

        # Removing the backup files for ndb compre
        remove_file_from_mgm_pod_zero "${NDB_MGMD_BASE_DATADIR}/${NDB_CONFIG_FILE_NAME_BEFORE_UPGRADE}"
        remove_file_from_mgm_pod_zero "${NDB_MGMD_BASE_DATADIR}/${NDB_CONFIG_FILE_NAME_AFTER_UPGRADE}"

        set_updateStrategy_to_RollingUpdate
        return 0
    fi

    if [[ "$1" == "--post-rollback" ]]; then
        echo "INFO: $($LOG_DATE_CMD) - OCCNE_NAMESPACE=${OCCNE_NAMESPACE}"
        echo "INFO: $($LOG_DATE_CMD) - API_EMP_TRY_SLOTS_NODE_IDS=${API_EMP_TRY_SLOTS_NODE_IDS}"
        echo "INFO: $($LOG_DATE_CMD) - NDB_MGMD_PODS=${NDB_MGMD_PODS}"
        echo "INFO: $($LOG_DATE_CMD) - NDB_STS_NAME=${NDB_STS_NAME}"
        echo "INFO: $($LOG_DATE_CMD) - API_STS_NAME=${API_STS_NAME}"
        echo "INFO: $($LOG_DATE_CMD) - APP_STS_NAME=${APP_STS_NAME}"
        echo "INFO: $($LOG_DATE_CMD) - NDBAPP_START_NODE_ID=${NDBAPP_START_NODE_ID}"
        echo "INFO: $($LOG_DATE_CMD) - NDBAPP_REPLICA_MAX_COUNT=${NDBAPP_REPLICA_MAX_COUNT}"

        echo "INFO: $($LOG_DATE_CMD) - skip empty api slot ids = ${API_EMP_TRY_SLOTS_NODE_IDS}"

        local from_version=$(mysqlver)
        echo "INFO: $($LOG_DATE_CMD) - from_version=${from_version}"

        echo "INFO: $($LOG_DATE_CMD) - Deleting MGM pods..."
        $KUBECTL_CMD -n $OCCNE_NAMESPACE delete pod $NDB_MGMD_PODS
        echo "INFO: $($LOG_DATE_CMD) - MGM pods deleted"

        echo "INFO: $($LOG_DATE_CMD) - Waiting for nodes to reconnect to MGMs..."
        wait_for_nodes_to_reconnect_to_mgm
        echo "INFO: $($LOG_DATE_CMD) - Nodes reconnected"

        local to_version=$(mysqlver)
        echo "INFO: $($LOG_DATE_CMD) - to_version=${to_version}"

        del_mysqld_pvcs_if_rolling_to_older_ver $from_version $to_version

        set_updateStrategy_to_RollingUpdate

        return 0
    fi
}

# don't execute main unless run by bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

