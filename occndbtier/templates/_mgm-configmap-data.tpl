
{{/*--------------------cnDBTier MGM ConfigMap Data-------------------------------------------*/}}
{{- /*
    This helm template contains the data section for the mgm/template/configmap.yaml.
    It has been extracted here to be able to render it in the ndb/template/sts.yaml,
    and trigger a rollout restart for the data nodes if it has changed with a following
    helm upgrade. Similarly to ndb/template/sts, this is rendered in mgm/template/sts.yaml,
    but this extraction is only necessary to access the data from the ndb chart also.
*/}}

{{- define "mgm.checkNdbParameterConfigured" -}}
{{- $configpresent := false }}
{{- range $key, $value := .global.additionalndbconfigurations.ndb -}}
{{- if eq $key $.ndbparam -}}
{{- $configpresent := true -}}
{{- end -}}
{{- end -}}
{{ $configpresent }}
{{- end -}}

{{- define "mgm.getLcpScanProgressTimeout" -}}
{{- if eq (include "mgm.checkNdbParameterConfigured" (dict "global" .global "ndbparam" "LcpScanProgressTimeout") ) "false" -}}
{{- $hbintervaldbdb := .global.additionalndbconfigurations.ndb.HeartbeatIntervalDbDb | default 500 -}}
{{- $timebetweenglobalcheckpointstimeout := .global.additionalndbconfigurations.ndb.TimeBetweenGlobalCheckpointsTimeout | default 60000 -}}
{{- $noofdatanodes := .global.ndbReplicaCount -}}
{{- $deltamillisecs := .global.deltalcpscanprogresstimeout | default 15000 -}}
{{- $argment1 := mul $hbintervaldbdb 5 $noofdatanodes -}}
{{- $LcpScanProgressinmillisecs := add $argment1 $timebetweenglobalcheckpointstimeout $deltamillisecs -}}
{{- $LcpScanProgressTimeoutvalue := div $LcpScanProgressinmillisecs 1000 -}}
LcpScanProgressTimeout={{- $LcpScanProgressTimeoutvalue -}}
{{- end -}}
{{- end -}}

{{- define "mgm.configmap.data" }}
  ndb-cluster.cnf: |-
    {{- $mgmstsname := (include "mgm.mgmtstsname" .) }}
    {{- $ndbstsname := (include "mgm.ndbstsname" .) }}
    {{- $apistsname := (include "mgm.apistsname" .) }}
    {{- $ndbappstsname := (include "mgm.ndbappstsname" .) }}
    {{- $ndbappreplicamaxcount := .Values.global.ndbappReplicaCount }}
    {{- if and (or (ne .Values.global.serviceAccount.name "") (.Values.global.serviceAccount.create)) (.Values.global.autoscaling.ndbapp.enabled) }}
    {{- $ndbappreplicamaxcount = .Values.global.ndbappReplicaMaxCount }}
    {{- else }}
    {{- $ndbappreplicamaxcount = .Values.global.ndbappReplicaCount }}
    {{- end }}
    {{- $g := .Values.global }}
    {{- $mgmConfig := $g.ndbconfigurations.mgm }}
    {{- range untilStep 0 ($g.mgmReplicaCount|int) 1 }}
    {{- $i := . }}
    [ndb_mgmd]
    {{- with $mgmConfig }}
    HeartbeatIntervalMgmdMgmd={{ .HeartbeatIntervalMgmdMgmd | default 2000 }}
    LogDestination=FILE:filename=ndbmgmd_cluster.log,maxsize=10000000,maxfiles=10
    HostName={{ $mgmstsname }}-{{ $i }}.{{ template "mgm.subdomain" . }}.{{ $g.namespace }}.svc.{{ $g.domain }}
    TotalSendBufferMemory={{ .TotalSendBufferMemory | default "16M" }}
    DataDir={{ .BaseDataDir }}/{{ .MgmDataDir }}
    NodeId={{ add .startNodeId $i }}
    PortNumber={{ $g.mgm.port | default 1186 }}
    {{- range $key, $value := $g.additionalndbconfigurations.mgm }}
    {{ $key }}={{ $value }}
    {{- end }}
    {{ end }}
    {{- end }}

    {{- $ndbConf := $g.ndbconfigurations.ndb }}
    {{- range untilStep 0 ($g.ndbReplicaCount|int) 1 }}
    {{- $i := . }}
    [ndbd]
    {{- with $ndbConf }}
    MaxNoOfAttributes={{ .MaxNoOfAttributes | default 5000 }}
    MaxNoOfOrderedIndexes={{ .MaxNoOfOrderedIndexes | default 256 }}
    NodeId={{ add 1 $i }}
    NoOfFragmentLogParts={{ .NoOfFragmentLogParts | default 4 }}
    StartPartialTimeout={{ .delayPerDataPod | default 60 | mul 1000 | mul $g.ndbReplicaCount }}
    {{- if $g.ndb.use_separate_backup_disk }}
    BackupDataDir={{ $g.ndb.separateBackupDataPath }}/{{ .BackupDataDir }}
    {{- else }}
    BackupDataDir={{ .BaseDataDir }}/{{ .BackupDataDir }}
    {{- end }}
    HostName={{ $ndbstsname }}-{{ $i }}.{{ template "ndb.subdomain" . }}.{{ $g.namespace }}.svc.{{ $g.domain }}
    MaxNoOfExecutionThreads={{ .MaxNoOfExecutionThreads | default 10 }}
    StopOnError={{ .StopOnError }}
    MaxNoOfTables={{ .MaxNoOfTables | default 256 }}
    DataDir={{ .BaseDataDir }}/{{ .DataDir }}
    NoOfFragmentLogFiles={{ .NoOfFragmentLogFiles | default 128 }}
    NoOfReplicas={{ .NoOfReplicas | default 2 }}
    ServerPort={{ $g.ndb.port | default 2202 }}
    DataMemory={{ $g.ndb.datamemory | default "1G" }}
    KeepAliveSendInterval={{ $g.ndb.KeepAliveSendIntervalMs | default 60000 }}
    {{- if $g.backupencryption.enable }}
    RequireEncryptedBackup=1
    {{- else }}
    RequireEncryptedBackup=0
    {{- end }}
    {{- if $g.useasm | or $g.useIPv6 }}
    TcpBind_INADDR_ANY=1
    {{- else }}
    TcpBind_INADDR_ANY={{ .TcpBindInAddrAny | default false }}
    {{- end }}
    {{- end }}
    {{ template "mgm.getLcpScanProgressTimeout" (dict "global" $g) }}
    {{- range $key, $value := $g.additionalndbconfigurations.ndb }}
    {{ $key }}={{ $value }}
    {{- end }}
    {{ end }}

    {{- $sqlnode := $g.api }}
    {{- range untilStep 0 ($g.apiReplicaCount|int) 1 }}
    {{- $i := . }}
    [mysqld]
    HostName={{ $apistsname }}-{{ $i }}.{{ template "api.subdomain" . }}.{{ $g.namespace }}.svc.{{ $g.domain }}
    NodeId={{ add $sqlnode.startNodeId $i }}
    {{- range $key, $value := $g.additionalndbconfigurations.api }}
    {{ $key }}={{ $value }}
    {{- end }}
    {{ end }}

    {{- $sqlnode := $g.ndbapp }}
    {{- range untilStep 0 ($ndbappreplicamaxcount|int) 1 }}
    {{- $i := . }}
    [mysqld]
    HostName={{ $ndbappstsname }}-{{ $i }}.{{ template "ndbapp.subdomain" . }}.{{ $g.namespace }}.svc.{{ $g.domain }}
    NodeId={{ add $sqlnode.startNodeId $i }}
    {{- range $key, $value := $g.additionalndbconfigurations.api }}
    {{ $key }}={{ $value }}
    {{- end }}
    {{- $end := sub $g.ndbapp.ndb_cluster_connection_pool 1 | int }}
    {{- range untilStep 0 $end 1 }}
    {{ $j := . }}
    {{- $baseid := $g.ndbapp.ndb_cluster_connection_pool_base_nodeid }}
    [api]
    NodeID={{ mul $end $i | add $baseid $j }}
    {{- end }}
    {{ end }}
    {{- $sqlnode := $g.api }}
    {{- range untilStep 0 ($sqlnode.numOfEmptyApiSlots|int) 1 }}
    {{- $i := . }}
    [api]
    NodeId={{ add $sqlnode.startEmptyApiSlotNodeId $i }}
    {{ end }}
    [TCP Default]
    AllowUnresolvedHostnames=true
    {{- if $g.useIPv6 }}
    PreferIPVersion=6
    {{- end }}
    {{- range $key, $value := $g.additionalndbconfigurations.tcp }}
    {{ $key }}={{ $value }}
    {{- end }}
{{- end -}}
