#!/usr/bin/env bash

KUBECTL_CMD="kubectl"
TRUE="true"
FALSE="false"


function get_own_multus_ip() {
    local ip=$(${KUBECTL_CMD} -n ${OCCNE_NAMESPACE} get pods ${POD_NAME} -o=json |  jq ".metadata.annotations.\"${NETWORK_ATTACHMENT_DEFINATION_API_NAME}/network-status\"" | sed 's/\\n//g'| sed 's/\\//g' |sed 's/    //g' | cut -c2- | jq ".[] |  select(.name==\"${OCCNE_NAMESPACE}/${NETWORK_ATTACHMENT_DEFINATION_API_TAG_NAME}\") | .ips" | sed 's/\[//g' | sed 's/\]//g' | sed 's/\"//g' | sed 's/ //g' | tr -d "\n" | tr -d "\r" )
    echo "$ip"
}

function get_index() {
    local ip=$1
    local index=$(${KUBECTL_CMD} -n ${OCCNE_NAMESPACE} get Endpoints ${CONNECTIVITY_SVC_NAME} -o json  | jq ".subsets[0].addresses | map(.ip== \"$ip\")|index(true)")
    echo "$index"
}

function get_pod_state() {
    local state=$(${KUBECTL_CMD} -n ${OCCNE_NAMESPACE} get pods ${POD_NAME} | grep -v STATUS | awk '{print $3}')
    echo $state
}

# Return 0 if ip exists in the ep 
# Return 1 if the ip does not exists in the ep
function is_ip_exists_in_ep() {
    local ip=$1
    local index=$(get_index $ip)
    if [[ "$index" != "null" ]]; then
        echo $TRUE
    else
        echo $FALSE
    fi
}

# Return 0 if the ep is empty 
# Return 1 if the ep is not empty
function is_ep_empty() {
    if [[ -z $(${KUBECTL_CMD} -n ${OCCNE_NAMESPACE} get ep ${CONNECTIVITY_SVC_NAME} -o=jsonpath="{.subsets[0].addresses[*]['ip']}") ]]; then
        echo $TRUE
    else
        echo $FALSE
    fi
}

function get_ip_count_in_ep() {
    local total_no_of_ips=$(${KUBECTL_CMD} -n ${OCCNE_NAMESPACE} get ep ${CONNECTIVITY_SVC_NAME} -o=jsonpath="{.subsets[0].addresses[*]['ip']}" | wc -w)
    echo $total_no_of_ips
}

function inject_endpoint() {
    local readiness_probe_return_code=$1
    local pod_state=$(get_pod_state)
    if [[ "$pod_state" == "Running" ]]; then
        local multus_ip=$(get_own_multus_ip)
        if [[ "$(is_ep_empty)" == "$TRUE" ]]; then
            ${KUBECTL_CMD} -n ${OCCNE_NAMESPACE} patch Endpoints ${CONNECTIVITY_SVC_NAME} -p "{\"subsets\": [{\"addresses\": [{\"ip\": \"$multus_ip\"}],\"ports\": [{\"port\": ${CONNECTIVITY_SVC_PORT_NO},\"name\": \"tcp\",\"protocol\": \"TCP\"}]}]}"
        elif [[ $(is_ip_exists_in_ep "$multus_ip") == $FALSE ]]; then
            ${KUBECTL_CMD} -n ${OCCNE_NAMESPACE} patch Endpoints ${CONNECTIVITY_SVC_NAME} --type json -p="[{\"op\": \"add\",\"path\": \"/subsets/0/addresses/-\",\"value\":{\"ip\": \"$multus_ip\"}}]"
        fi
    fi
    if [[ ! -z "$readiness_probe_return_code" ]]; then
        return $readiness_probe_return_code
    fi
}

function remove_endpoint() {
    local readiness_probe_return_code=$1
    local multus_ip=$(get_own_multus_ip)

    if [[ $(is_ip_exists_in_ep "$multus_ip") == $TRUE ]]; then
        local index=$(get_index $multus_ip)

        if [[ "$(get_ip_count_in_ep)" == "1" ]]; then
            ${KUBECTL_CMD} -n ${OCCNE_NAMESPACE} patch Endpoints ${CONNECTIVITY_SVC_NAME} --type json -p="[{\"op\": \"remove\",\"path\": \"/subsets\"}]"
        else
            ${KUBECTL_CMD} -n ${OCCNE_NAMESPACE} patch Endpoints ${CONNECTIVITY_SVC_NAME} --type json -p="[{\"op\": \"remove\",\"path\": \"/subsets/0/addresses/$index\"}]"
        fi
    fi
    if [[ ! -z "$readiness_probe_return_code" ]]; then
        return $readiness_probe_return_code
    fi
}
