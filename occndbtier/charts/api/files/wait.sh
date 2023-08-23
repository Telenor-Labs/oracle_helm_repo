#!/usr/bin/env bash

MYSQL_CMD="mysql --binary-as-hex=0 --show-warnings"

# DBTIER_SITE_INFO.stop_replication_mysqlds = 1 => Dont let the sql pod to start
# DBTIER_SITE_INFO.stop_replication_mysqlds = 0 => Let the sql pod to start
function wait_till_stop_replication_mysqlds_enabled() {
    local query="SELECT stop_replication_mysqlds FROM ${DBTIER_REPLICATION_SVC_DATABASE}.DBTIER_SITE_INFO WHERE site_name='${SITE_NAME}';"
    while true; do
        stop_replication_mysqlds_value=$($MYSQL_CMD -h${CONNECTIVITY_SVC_NAME} -u${MYSQL_OCCNE_USER} -p${MYSQL_OCCNE_PASSWORD} -sse "${query}")
        if [[ "${stop_replication_mysqlds_value}" -eq "0" ]]; then
            echo "[Entrypoint] INFO: $(date) - Starting the mysql servive as stop_replication_mysqlds == 0"
            break
        else
            echo "[Entrypoint] INFO: $(date) - Waiting as stop_replication_mysqlds != 0"
            sleep 5
        fi
    done
}

function wait_till_ndbmtd_online() {
    ndbmtd_process_online=false
    waitCount=0
    while ! ${ndbmtd_process_online} ; do
        {
            sleep 5
            let "waitCount+=5"
            if [ ${waitCount} -gt ${NDB_WAIT_TIMEOUT} ]; then
                if ! ${ndbmtd_process_online} ; then
                    echo "[Entrypoint] ERROR: $(date) - Timeout in waiting for ndbmtd pods to become online."
                fi
                break
            fi
            if ! ndb_mgm ${NDB_MGM_SUBDOMAIN} ${NDB_MGMD_PORT} -e "show" | grep -q "\[ndbd(NDB)\]"; then
                echo "[Entrypoint] ERROR: $(date) - [ndbd(NDB)] group not present"
                continue
            fi
            if ndb_mgm ${NDB_MGM_SUBDOMAIN} ${NDB_MGMD_PORT} -e "show" | grep -w ${ndb_nodes} | grep -q "accepting connect\|not connected"; then
                echo "ERROR: $(date) - Not all ndbmtd nodes are connected"
                ndb_mgm ${NDB_MGM_SUBDOMAIN} ${NDB_MGMD_PORT} -e "show" | grep -w ${ndb_nodes} | grep "accepting connect\|not connected"
                continue
            fi
            ndbmtd_process_online=true
        } || {
            echo "[Entrypoint] ERROR: $(date) - Exception occurred while checking for ndb_mgmd status...retrying..!!"  
        }
    done
}

