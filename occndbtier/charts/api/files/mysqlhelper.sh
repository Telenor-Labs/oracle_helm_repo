#!/usr/bin/env bash

GREP_CMD="/usr/bin/grep"
NDB_MGM_CMD="/usr/local/bin/ndb_mgm --connect-retries=1"
LOG_DATE_CMD="date -u +%FT%TZ"

function ndb_mgm_show() {
    $NDB_MGM_CMD ${mgm_subdomain} ${mgm_port} -e SHOW 2>&1
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
    $NDB_MGM_CMD ${mgm_subdomain} ${mgm_port} -e "$node_id status" 2>&1 | $GREP_CMD -q -e "Node ${node_id}: connected"
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

    echo "INFO: $(date) - query: $query";

    local table_exists=$(mysql -h${LOOPBACK_IP} -uroot -p${MYSQL_ROOT_PASSWORD} -sse "$query")

    if [[ $table_exists -gt 0 ]]; then
        echo "INFO: $(date) - $table exists in $database";
        return 0
    else 
        echo "ERROR: $(date) - $table does not exists in $database";
        return 1
    fi
}


# Checks if user exists in db.
#
# @param  $1 db username
#
# @return  0 (true) if user exists; 1 (false) otherwise
function is_user_exists() {
    local username="$1"

    local query="SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = \"${username}\");"

    echo "INFO: $(date) - query: $query";

    local user_exists=$(mysql -h${LOOPBACK_IP} -uroot -p${MYSQL_ROOT_PASSWORD} -sse "$query")

    if [[ $user_exists -eq 1 ]]; then
        echo "INFO: $(date) - $username exists in db";
        return 0
    else 
        echo "ERROR: $(date) - $username does not exists in db";
        return 1
    fi
}

# Checks if monitor and replication user present
#
# @return  0 (true) if both user exists; 1 (false) otherwise
function is_all_db_user_present() {
    is_user_exists "${MYSQL_OCCNE_USER}"
    local monitor_user_present=$?

    is_user_exists "${MYSQL_OCCNE_REPLICATION_USER}"
    local replication_user_present=$?

    if [[ ( $monitor_user_present -eq 0 ) && ( $replication_user_present -eq 0 ) ]]; then
        return 0
    else 
        return 1
    fi
}

# Checks if all schemas are present for backup service
#
# @return  0 (true) if backup schema exists; 1 (false) otherwise
function is_backup_schema_present() {
    is_table_in_database "${DBTIER_BACKUP_SVC_DATABASE}" "DBTIER_BACKUP_INFO"
    is_backup_info_tbl_present=$?

    is_table_in_database "${DBTIER_BACKUP_SVC_DATABASE}" "DBTIER_BACKUP_COMMAND_QUEUE"
    is_backup_command_queue_tbl_present=$?

    is_table_in_database "${DBTIER_BACKUP_SVC_DATABASE}" "DBTIER_BACKUP_TRANSFER_INFO"
    is_backup_transfer_info_tbl_present=$?


    if [[ ( ${is_backup_info_tbl_present} -eq 0 ) && ( ${is_backup_command_queue_tbl_present} -eq 0 ) && ( ${is_backup_transfer_info_tbl_present} -eq 0 ) ]]; then 
        return 0
    else
        return 1
    fi
}

# Checks if all schemas are present for replication service
#
# @return  0 (true) if replication schema exists; 1 (false) otherwise
function is_replication_schema_present() {
    is_table_in_database "${DBTIER_REPLICATION_SVC_DATABASE}" "DBTIER_SITE_INFO"
    is_site_info_tbl_present=$?

    is_table_in_database "${DBTIER_REPLICATION_SVC_DATABASE}" "DBTIER_REPL_SITE_INFO"
    is_repl_site_info_tbl_present=$?

    is_table_in_database "${DBTIER_REPLICATION_SVC_DATABASE}" "DBTIER_REPLICATION_CHANNEL_INFO"
    is_repl_channel_info_tbl_present=$?

    is_table_in_database "${DBTIER_REPLICATION_SVC_DATABASE}" "DBTIER_INITIAL_BINLOG_POSTION"
    is_repl_initial_binlog_pos_tbl_present=$?

    is_table_in_database "${DBTIER_REPLICATION_SVC_DATABASE}" "DBTIER_REPL_ERROR_SKIP_INFO"
    is_repl_error_skip_info_tbl_present=$?

    is_table_in_database "${DBTIER_REPLICATION_SVC_DATABASE}" "DBTIER_REPL_EVENT_INFO"
    is_repl_event_info_tbl_present=$?

    if [[ ( ${is_site_info_tbl_present} -eq 0 ) && ( ${is_repl_site_info_tbl_present} -eq 0 ) && ( ${is_repl_channel_info_tbl_present} -eq 0 ) && ( ${is_repl_initial_binlog_pos_tbl_present} -eq 0 ) && ( ${is_repl_error_skip_info_tbl_present} -eq 0 ) && ( ${is_repl_event_info_tbl_present} -eq 0 ) ]]; then 
        return 0
    else
        return 1
    fi
}


# Checks if all schemas are present for replication service
#
# @return  0 (true) if replication schema exists; 1 (false) otherwise
function create_hbreplicagroups_schemas() {
    DBTIER_HBREPLICAGROUP_DATABASE=${DBTIER_HBREPLICAGROUP_DATABASE};
    GROUPID=1;

    while [ ${GROUPID} -le ${REPLCHANNEL_GROUP_COUNT} ]
    do
        echo "INFO: $(date) - creating mysql database for group id: ${GROUPID}";

        DBTIER_REPLICAGROUP_GROUPID_DATABASE="${DBTIER_HBREPLICAGROUP_DATABASE}${GROUPID}"
        if [ ${GROUPID} -eq 1 ]; then
            DBTIER_REPLICAGROUP_GROUPID_DATABASE="${DBTIER_HBREPLICAGROUP_DATABASE}"
        fi

        echo "INFO: $(date) - creating mysql database for dbtier heartbeat info...";
        mysql -h${LOOPBACK_IP} -uroot -p${MYSQL_ROOT_PASSWORD} \
            -e "CREATE DATABASE IF NOT EXISTS ${DBTIER_REPLICAGROUP_GROUPID_DATABASE}; \
                CREATE TABLE IF NOT EXISTS ${DBTIER_REPLICAGROUP_GROUPID_DATABASE}.DBTIER_HEARTBEAT_INFO ( \
                site_name VARCHAR(64) NOT NULL, \
                mate_site_name VARCHAR(64) NOT NULL, \
                replchannel_group_id INT NOT NULL, \
                updated_timestamp datetime DEFAULT NULL, \
                hbfailure INT DEFAULT NULL, \
                CONSTRAINT DBTIER_HEARTBEAT_INFO_pk PRIMARY KEY (site_name, mate_site_name, replchannel_group_id) \
                ) ENGINE=NDBCLUSTER;"
        GROUPID=`expr $GROUPID + 1`
    done
}


# Checks if all schemas are present for replication service
#
# @return  0 (true) if replication schema exists; 1 (false) otherwise
function is_hbreplicagroups_schema_present() {
    DBTIER_HBREPLICAGROUP_DATABASE=${DBTIER_HBREPLICAGROUP_DATABASE};
    GROUPID=1;
    while [ ${GROUPID} -le ${REPLCHANNEL_GROUP_COUNT} ]
    do
        DBTIER_REPLICAGROUP_GROUPID_DATABASE="${DBTIER_HBREPLICAGROUP_DATABASE}${GROUPID}"
        if [ ${GROUPID} -eq 1 ]; then
            DBTIER_REPLICAGROUP_GROUPID_DATABASE="${DBTIER_HBREPLICAGROUP_DATABASE}"
        fi

        is_table_in_database "${DBTIER_REPLICAGROUP_GROUPID_DATABASE}" "DBTIER_HEARTBEAT_INFO"
        is_heartbeat_tbl_present=$?
		
        if [[ ${is_heartbeat_tbl_present} -eq 1 ]]; then
            echo "INFO: $(date) - table does not exists in ${DBTIER_REPLICAGROUP_GROUPID_DATABASE} db"
            return 1
        fi

        GROUPID=`expr $GROUPID + 1`
    done

    return 0
}


# Checks if mysql.ndb_replication table present
#
# @return  0 (true) if table exists; 1 (false) otherwise
function is_mysql_ndb_replication_table_present() {
    is_table_in_database "mysql" "ndb_replication"
    is_ndb_replication_present=$?

    if [[ ( ${is_ndb_replication_present} -eq 0 ) ]]; then 
        return 0
    else
        return 1
    fi
}

# Rotates the mysqld.log file
log_file_rotate_current_counter=$(ls ${ndbconfigurations_api_BaseDataDir}/${ndbconfigurations_api_datadir} | grep ${ndbconfigurations_api_log_error}.old | cut -d "." -f4 | awk 'BEGIN{x=0};$0>x{x=$0};END{print x}')
log_file_rotate_max_counter=${logrotate_maxRotateCounter}
purge_mysqld_log() {
    max_allowed_log_file_size=${logrotate_rotateSize}
    log_file_name=${ndbconfigurations_api_BaseDataDir}/${ndbconfigurations_api_datadir}/${ndbconfigurations_api_log_error}
    mysqld_log_file_size=$(ls -l --block-size=1M ${log_file_name} | awk '{print $5}')

    if [ ${mysqld_log_file_size} -gt ${max_allowed_log_file_size} ]; then
        echo "INFO: $(date) - ${log_file_name} having size ${mysqld_log_file_size} exceeds ${max_allowed_log_file_size} max log record size limit"
        echo "INFO: $(date) - Initiated Purge...!!"

        if [ ${log_file_rotate_current_counter} -ge ${log_file_rotate_max_counter} ]; then
            log_file_rotate_current_counter=1
        else
            log_file_rotate_current_counter=`expr ${log_file_rotate_current_counter} + 1`
        fi

        cp ${log_file_name} ${log_file_name}.old.${log_file_rotate_current_counter}
        truncate -s 0 ${log_file_name}
        mysqladmin -h${LOOPBACK_IP} -u${MYSQL_OCCNE_USER} -p${MYSQL_OCCNE_PASSWORD} --socket /tmp/mysql.sock flush-logs
        echo "INFO: $(date) - Purge completed...!!"
    fi
}

# Rotates the query log file
query_log_file_cut_position=${query_log_file_cut_position:=4}
query_log_file_rotate_current_counter=$(ls ${ndbconfigurations_api_BaseDataDir}/${ndbconfigurations_api_datadir} | grep ${general_log_file}.old | cut -d "." -f"${query_log_file_cut_position}" | awk 'BEGIN{x=0};$0>x{x=$0};END{print x}')
purge_mysqld_query_log() {
    max_allowed_query_log_file_size=${query_logrotate_rotateSize}
    query_log_file_rotate_max_counter=${query_logrotate_maxRotateCounter}
    query_log_file_full_path=${ndbconfigurations_api_BaseDataDir}/${ndbconfigurations_api_datadir}/${general_log_file}
	# Checking if the $general_log_file exists if not then not doing the purge operation
	if [ ! -e "${query_log_file_full_path}" ]; then 
		# If the query log file does not exists then return from the method
		return
	fi

    if [[ -z "${query_log_file_rotate_current_counter}" ]]; then
        query_log_file_rotate_current_counter=0
    fi

    query_log_file_size=$(ls -l --block-size=1M ${query_log_file_full_path} | awk '{print $5}')

    if [ ${query_log_file_size} -gt ${max_allowed_query_log_file_size} ]; then
        echo "INFO: $(date) - ${query_log_file_full_path} having size ${query_log_file_size} exceeds ${max_allowed_query_log_file_size} max log record size limit"
        echo "INFO: $(date) - Initiated Query Log Purge...!!"

        if [ ${query_log_file_rotate_current_counter} -ge ${query_log_file_rotate_max_counter} ]; then
            query_log_file_rotate_current_counter=1
        else
            query_log_file_rotate_current_counter=`expr ${query_log_file_rotate_current_counter} + 1`
        fi

        cp ${query_log_file_full_path} ${query_log_file_full_path}.old.${query_log_file_rotate_current_counter}
        tar -zcvf ${query_log_file_full_path}.old.${query_log_file_rotate_current_counter}.tar.gz ${query_log_file_full_path}.old.${query_log_file_rotate_current_counter}
        rm -rf ${query_log_file_full_path}.old.${query_log_file_rotate_current_counter}
        truncate -s 0 ${query_log_file_full_path}
        mysqladmin -h${LOOPBACK_IP} -u${MYSQL_OCCNE_USER} -p${MYSQL_OCCNE_PASSWORD} --socket /tmp/mysql.sock flush-logs
        echo "INFO: $(date) - Query Log Purge completed...!!"
    fi
}

waitForClusterToStart() {
    waitCount=0;
    secsToWait=${secsToWaitBetweenChecks}
    maxSecsToWait=${secsToWaitForClusterTimeout}

    echo "INFO: $(date) - verifing MGM nodes are up and waiting for connections";
    while ! is_mgm_up; do
        if [ ${waitCount} -gt $maxSecsToWait ]; then
            ndb_mgm ${mgm_subdomain} ${mgm_port} -e "SHOW" || true;
            echo "ERROR: $(date) - some pods in NDB Cluster failed to start; Still continue monitoring";
            waitCount=0;
        fi;
        echo "INFO: $(date) - not all MGM nodes are up and waiting for connections yet; waiting...";
        sleep ${secsToWait};
        let "waitCount+=${secsToWait}";
    done;

    if [ -z "${apiemptryslotsnodeids}" ]; then
        apiemptryslotsnodeids="NOEMPTYSLOTNODEIDS"
    fi

    echo "INFO: $(date) - verifing mysql cluster connection is up";
    node_id=$(get_sqld_node_id)
    while ! is_node_connected $node_id; do
        if [ ${waitCount} -gt $maxSecsToWait ]; then
            ndb_mgm ${mgm_subdomain} ${mgm_port} -e "SHOW" || true;
            echo "ERROR: $(date) - NDB Cluster failed to start; not all nodes are connected";
            echo "ERROR: $(date) - some pods in NDB Cluster failed to start; not all nodes are connected, Still continue monitoring";
            waitCount=0;
        fi;
        echo "INFO: $(date) - not all mysql cluster connections are up yet; waiting...";
        sleep ${secsToWait};
        let "waitCount+=${secsToWait}";
    done;
}

waitForMysqlCreateSchema() {
    waitCount=0;
    secsToWait=${secsToWaitBetweenChecks}
    maxSecsToWait=${secsToWaitForClusterTimeout}
    MYSQLD_POD_INITIALIZED_FILE=${ndbconfigurations_api_BaseDataDir}/init-sidecar-done

    if [[ ! -f "${MYSQLD_POD_INITIALIZED_FILE}" ]]; then
        echo "INFO: $(date) - First time running... Going to create necessary Schema ...";
        echo "INFO: $(date) - Verifing if the MySQL process is UP";
    else
        echo "INFO: $(date) - Not first time running... Skipping Schema creation...";
    fi

    while [[ ! -f "${MYSQLD_POD_INITIALIZED_FILE}" ]]; do
        if [ ${waitCount} -gt $maxSecsToWait ]; then
            echo "ERROR: $(date) - Timeout in waiting for the MySQL process";
            break
        fi
        {
            # Before proceeding further we will be checking if connection to database is there or not
            is_mysql_process_ip=$(mysql -h${LOOPBACK_IP} -uroot -p${MYSQL_ROOT_PASSWORD} -sse "SELECT 1")

            if [[ ${is_mysql_process_ip} -eq 1 ]]; then

                echo "INFO: $(date) - Verifying if schema already present ... ";
                is_all_db_user_present
                users_exists=$?
                if [[ ${users_exists} -eq 0 ]]; then
                    echo "INFO: $(date) - ${MYSQL_OCCNE_USER} and ${MYSQL_OCCNE_REPLICATION_USER} already exist. Skipping creating schema...";
                    echo "INFO: $(date) - Creating ${MYSQLD_POD_INITIALIZED_FILE} file..."
                    echo "1" > ${MYSQLD_POD_INITIALIZED_FILE}
                    break
                else
                    # If not the index 0 then wait sometime here so that the index pod 0 completes the user creation
                    # First check if non geo repl sql pods are there
                    if [[ ${ndbapp_replica_count} -ne 0 ]]; then
                        # If yes that means you need to wait for all the pods except ndbappmysqld-0
                        if [[ ${IS_NODE_FOR_GEO_REPLICATION} -eq 0 ]]; then
                            # Here waiting for non geo repl sql pod index > 0
                            if [[ ${HOSTNAME##*-} -ne 0 ]]; then
                                echo "INFO: $(date) - ${HOSTNAME} waiting for schema creation to complete...";
                                sleep ${secsToWait};
                                let "waitCount+=${secsToWait}";
                                continue
                            fi
                        else
                            # here waiting for geo repl all pods
                            echo "INFO: $(date) - ${HOSTNAME} waiting for schema creation to complete...";
                            sleep ${secsToWait};
                            let "waitCount+=${secsToWait}";
                            continue
                        fi
                    else
                        # Here only geo repl sql pods are there so waiting for index > 0
                        if [[ ${HOSTNAME##*-} -ne 0 ]]; then
                            echo "INFO: $(date) - ${HOSTNAME} waiting for schema creation to complete....";
                            sleep ${secsToWait};
                            let "waitCount+=${secsToWait}";
                            continue
                        fi
                    fi

                    echo "INFO: $(date) - creating mysql database for backup service...";
                    mysql -h${LOOPBACK_IP} -uroot -p${MYSQL_ROOT_PASSWORD} \
                        -e "CREATE DATABASE IF NOT EXISTS ${DBTIER_BACKUP_SVC_DATABASE}; \
                            CREATE TABLE IF NOT EXISTS ${DBTIER_BACKUP_SVC_DATABASE}.DBTIER_BACKUP_INFO ( \
                                site_name VARCHAR(64) NOT NULL, \
                                cluster_id INT NOT NULL, \
                                backup_id BIGINT(20) NOT NULL, \
                                backup_status VARCHAR(100) NOT NULL, \
                                node_id INT NOT NULL, \
                                backup_size BIGINT(20) DEFAULT NULL, \
                                creation_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP, \
                                CONSTRAINT DBTIER_BACKUP_INFO_pk PRIMARY KEY (cluster_id, backup_id, node_id)); \
                            CREATE TABLE IF NOT EXISTS ${DBTIER_BACKUP_SVC_DATABASE}.DBTIER_BACKUP_COMMAND_QUEUE ( \
                                site_name VARCHAR(64) NOT NULL, \
                                cluster_id INT NOT NULL, \
                                node_id INT NOT NULL, \
                                manager_command VARCHAR(255) DEFAULT NULL, \
                                backup_id BIGINT(20) DEFAULT NULL, \
                                executor_status TEXT DEFAULT NULL, \
                                CONSTRAINT DBTIER_BACKUP_COMMAND_QUEUE_pk PRIMARY KEY (cluster_id, node_id)); \
                            CREATE TABLE IF NOT EXISTS ${DBTIER_BACKUP_SVC_DATABASE}.DBTIER_BACKUP_TRANSFER_INFO ( \
                                site_name VARCHAR(64) NOT NULL, \
                                cluster_id INT NOT NULL, \
                                backup_id BIGINT(20) NOT NULL, \
                                node_id INT NOT NULL, \
                                replication_svc_ip VARCHAR(255) NOT NULL, \
                                remote_replication_svc_ip VARCHAR(255), \
                                transfer_status VARCHAR(100), \
                                remote_transfer_status VARCHAR(100), \
                                CONSTRAINT DBTIER_BACKUP_TRANSFER_INFO_pk PRIMARY KEY (site_name, backup_id, node_id));"
                    
                    is_backup_schema_present
                    backup_schema_exists=$?
                    if [[ ( ${backup_schema_exists} -eq 0 ) ]]; then 
                        echo "INFO: $(date) - Schema creation complete for backup service"
                    else
                        echo "ERROR: $(date) - Schema creation not complete for backup service..retrying"
                        continue
                    fi

                    # Creation of mysql.ndb_replication table
                    echo "INFO: $(date) - creating mysql.ndb_replication table...";
                    mysql -h${LOOPBACK_IP} -uroot -p${MYSQL_ROOT_PASSWORD} \
                        -e "CREATE TABLE IF NOT EXISTS mysql.ndb_replication ( \
                                db VARBINARY(63), \
                                table_name VARBINARY(63), \
                                server_id INT UNSIGNED, \
                                binlog_type INT UNSIGNED, \
                                conflict_fn VARBINARY(128), \
                                PRIMARY KEY USING HASH (db, table_name, server_id) \
                                ) ENGINE=NDB \
                                PARTITION BY KEY(db,table_name);"

                    
                    is_mysql_ndb_replication_table_present
                    mysql_ndb_replication_table_exists=$?
                    if [[ ( ${mysql_ndb_replication_schema_exists} -eq 0 ) ]]; then 
                        echo "INFO: $(date) - Schema creation complete for mysql ndb replication table"
                    else
                        echo "ERROR: $(date) - Schema creation not complete for mysql ndb replication table..retrying"
                        continue
                    fi

                    create_hbreplicagroups_schemas
                    is_hbreplicagroups_schema_present
                    hbreplicagroups_tables_exists=$?
                    if [[ ( ${hbreplicagroups_tables_exists} -eq 0 ) ]]; then 
                        echo "INFO: $(date) - Schema creation complete for heartbeat replica table"
                    else
                        echo "ERROR: $(date) - Schema creation not complete for heartbeat replica table..retrying"
                        continue
                    fi


                    echo "INFO: $(date) - creating mysql database for dbtier replication service...";
                    mysql -h${LOOPBACK_IP} -uroot -p${MYSQL_ROOT_PASSWORD} \
                        -e "CREATE DATABASE IF NOT EXISTS ${DBTIER_REPLICATION_SVC_DATABASE}; \
                            CREATE TABLE IF NOT EXISTS ${DBTIER_REPLICATION_SVC_DATABASE}.DBTIER_SITE_INFO ( \
                                site_name VARCHAR(64) NOT NULL, \
                                site_id INT NOT NULL, \
                                dr_state VARCHAR(64) NOT NULL, \
                                dr_backup_site_name VARCHAR(64) DEFAULT NULL, \
                                backup_id VARCHAR(64) DEFAULT NULL, \
                                stop_replication_mysqlds INT DEFAULT NULL, \
                                CONSTRAINT DBTIER_SITE_INFO_pk PRIMARY KEY (site_name) \
                                ) ENGINE=NDBCLUSTER; \
                            CREATE TABLE IF NOT EXISTS ${DBTIER_REPLICATION_SVC_DATABASE}.DBTIER_REPL_SITE_INFO ( \
                                site_name VARCHAR(64) NOT NULL, \
                                mate_site_name VARCHAR(64) NOT NULL, \
                                mate_db_replication_svc_ip VARCHAR(100), \
                                mate_db_replication_svc_port VARCHAR(100), \
                                mate_db_username VARCHAR(100), \
                                mate_db_password VARCHAR(100), \
                                dr_state VARCHAR(64), \
                                replchannel_group_id INT NOT NULL, \
                                CONSTRAINT DBTIER_REPL_SITE_INFO_pk PRIMARY KEY (site_name, mate_site_name, replchannel_group_id)
                                ) ENGINE=NDBCLUSTER; \
                            CREATE TABLE IF NOT EXISTS ${DBTIER_REPLICATION_SVC_DATABASE}.DBTIER_REPLICATION_CHANNEL_INFO ( \
                                remote_site_name VARCHAR(64) NOT NULL, \
                                remote_server_id int NOT NULL, \
                                channel_id INT NOT NULL, \
                                remote_signaling_ip VARCHAR(100) NOT NULL, \
                                role VARCHAR(100) NOT NULL, \
                                start_epoch BIGINT(20) DEFAULT NULL, \
                                site_name VARCHAR(64) NOT NULL, \
                                server_id INT NOT NULL, \
                                start_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP, \
                                replchannel_group_id INT NOT NULL, \
                                CONSTRAINT DBTIER_REPLICATION_CHANNEL_INFO PRIMARY KEY (remote_server_id) \
                                ) ENGINE=NDBCLUSTER; \
                            CREATE TABLE IF NOT EXISTS ${DBTIER_REPLICATION_SVC_DATABASE}.DBTIER_INITIAL_BINLOG_POSTION ( \
                                site_name VARCHAR(64) NOT NULL, \
                                sql_node_ip VARCHAR(256) NOT NULL, \
                                bin_log_filename VARCHAR(64), \
                                bin_log_position INT NOT NULL, \
                                CONSTRAINT DBTIER_INITIAL_BINLOG_POSTION_pk PRIMARY KEY (site_name, sql_node_ip) \
                                ) ENGINE=NDBCLUSTER; \
                            CREATE TABLE IF NOT EXISTS ${DBTIER_REPLICATION_SVC_DATABASE}.DBTIER_REPL_ERROR_SKIP_INFO ( \
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
                                ) ENGINE=NDBCLUSTER; \
                            CREATE TABLE IF NOT EXISTS ${DBTIER_REPLICATION_SVC_DATABASE}.DBTIER_REPL_EVENT_INFO ( \
                                site_name VARCHAR(64) NOT NULL, \
                                mate_site_name VARCHAR(64) NOT NULL, \
                                replchannel_group_id INT, \
                                event_id INT NOT NULL AUTO_INCREMENT, \
                                event_type INT, \
                                event_ts DATETIME, \
                                event_description TEXT, \
                                CONSTRAINT DBTIER_REPL_EVENT_INFO_pk PRIMARY KEY (site_name, mate_site_name, replchannel_group_id, event_id) \
                                ) ENGINE=NDBCLUSTER;"

                    is_replication_schema_present
                    repl_schema_exists=$?
                    if [[ ( ${repl_schema_exists} -eq 0 ) ]]; then 
                        echo "INFO: $(date) - Schema creation complete for replication service"
                    else
                        echo "ERROR: $(date) - Schema creation not complete for replication service..retrying"
                        continue
                    fi


                    echo "INFO: $(date) - creating mysql user for monitor service...";
                    mysql -h${LOOPBACK_IP} -uroot -p${MYSQL_ROOT_PASSWORD} \
                        -e "CREATE USER IF NOT EXISTS '${MYSQL_OCCNE_USER}'@'%' IDENTIFIED BY '${MYSQL_OCCNE_PASSWORD}'; \
                            GRANT ALL PRIVILEGES ON *.* TO  '${MYSQL_OCCNE_USER}'@'%'; \
                            FLUSH PRIVILEGES;"

                    echo "INFO: $(date) - creating mysql user for replication service...";
                    mysql -h${LOOPBACK_IP} -uroot -p${MYSQL_ROOT_PASSWORD} \
                        -e "CREATE USER IF NOT EXISTS '${MYSQL_OCCNE_REPLICATION_USER}'@'%' IDENTIFIED BY '${MYSQL_OCCNE_REPLICATION_PASSWORD}'; \
                            GRANT ALL PRIVILEGES ON *.* TO  '${MYSQL_OCCNE_REPLICATION_USER}'@'%'; \
                            FLUSH PRIVILEGES;"
                    
                    is_all_db_user_present
                    users_exists=$?
                    if [[ ${users_exists} -eq 0 ]]; then
                        echo "INFO: $(date) - Creating ${MYSQLD_POD_INITIALIZED_FILE} file..."
                        echo "1" > ${MYSQLD_POD_INITIALIZED_FILE}
                    else
                        echo "ERROR: $(date) - Monitor and replication users not created..retrying"
                    fi
                fi
            else
                echo "ERROR: $(date) - Not able to connect to the mysql process... retrying ...";
            fi
        } || {
            echo "ERROR: $(date) - Error in creating necessary scema in mysql ... retrying ...";
        }
        sleep ${secsToWait};
        let "waitCount+=${secsToWait}";
    done;
}

LOOPBACK_IP=${LOOPBACK_IP:-"127.0.0.1"}

container=${api_initsidecarfullname}
echo "INFO: $(date) - $container started";
waitForClusterToStart;
# sometimes the cluster comes up for a bit and goes down again
secsToWaitForClusterToReachSteadyState=10;
sleep $secsToWaitForClusterToReachSteadyState;
waitForClusterToStart;

echo "INFO: $(date) - mysql cluster is up ... Creating Required Schema ...";
waitForMysqlCreateSchema

echo "INFO: $(date) - $container successfully finished; Log Rotation for API pod started... !!";
trap 'echo "INFO: $(date) - signal received; exiting..."; exit 1' 1 2 15
waitCount=0
secsToWait=1
while true; do
    if [ ${waitCount} -ge $logrotate_checkInterval ]; then
        waitCount=0

        # We are committed; disable trap while the purge is in progress
        # since exiting in the middle may leave it in a bad state.
        trap '' 1 2 15

        purge_mysqld_log

        # enable query log rotation only if it is ndbmysqld
        if [[ "${IS_NODE_FOR_GEO_REPLICATION}" -eq "1" ]]; then

            # if general logging is not enabled then dont do rotation
            if [[ ! -z "${general_log_enabled}" ]]; then
                if [[ "${general_log_enabled}" -eq "ON" ]]; then
                    purge_mysqld_query_log
                fi
            fi
        fi

        # done with purge; enable the trap again
        trap 'echo "INFO: $(date) - signal received; exiting..."; exit 1' 1 2 15
        continue
    fi
    let "waitCount+=${secsToWait}";
    sleep $secsToWait
done;
