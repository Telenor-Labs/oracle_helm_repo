

{{/*------------------------------------cnDBTier Service Account Name----------------------------------------*/}}
{{- define "cndbtier.serviceaccount" -}}
{{- if .Values.global.serviceAccount.name -}}
{{- .Values.global.serviceAccount.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name "service-reader" | trunc 63 | trimPrefix "-" | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*--------------------ROLE------------------------------------------------------------------*/}}
{{- define "cndbtier.role" -}}
{{- printf "%s-%s" .Release.Name "svc-role" | trunc 63 | trimPrefix "-" | trimSuffix "-" -}}
{{- end -}}

{{/*--------------------ROLE BINDING----------------------------------------------------------*/}}
{{- define "cndbtier.rolebinding" -}}
{{- printf "%s-%s" .Release.Name "svc-role" | trunc 63 | trimPrefix "-" | trimSuffix "-" -}}
{{- end -}}

{{/*------------------------------------cnDBTier Service Account Name----------------------------------------*/}}
{{- define "cndbtier.upgrade.serviceaccount" -}}
{{- if .Values.global.serviceAccountForUpgrade.name -}}
{{- .Values.global.serviceAccountForUpgrade.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name "upgrade-reader" | trunc 63 | trimPrefix "-" | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*--------------------ROLE------------------------------------------------------------------*/}}
{{- define "cndbtier.upgrade.role" -}}
{{- printf "%s-%s" .Release.Name "upgrade-role" | trunc 63 | trimPrefix "-" | trimSuffix "-" -}}
{{- end -}}

{{/*--------------------ROLE BINDING----------------------------------------------------------*/}}
{{- define "cndbtier.upgrade.rolebinding" -}}
{{- printf "%s-%s" .Release.Name "upgrade-role" | trunc 63 | trimPrefix "-" | trimSuffix "-" -}}
{{- end -}}


{{/*------------------------------------cnDBTier Service Account Name for multus-------------------------------*/}}
{{- define "cndbtier.multus.serviceaccount" -}}
{{- if .Values.global.multus.serviceAccount.name -}}
{{- .Values.global.multus.serviceAccount.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name "multus-reader" | trunc 63 | trimPrefix "-" | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*--------------------ROLE------------------------------------------------------------------*/}}
{{- define "cndbtier.multus.role" -}}
{{- printf "%s-%s" .Release.Name "multus-role" | trunc 63 | trimPrefix "-" | trimSuffix "-" -}}
{{- end -}}

{{/*--------------------ROLE BINDING----------------------------------------------------------*/}}
{{- define "cndbtier.multus.rolebinding" -}}
{{- printf "%s-%s" .Release.Name "multus-role" | trunc 63 | trimPrefix "-" | trimSuffix "-" -}}
{{- end -}}


{{/*--------------------API SUBDOMAIN----------------------------------------------------------*/}}
{{- define "api.subdomain" -}}
  {{- printf "%s" "ndbmysqldsvc"  -}}
{{- end -}}

{{/*--------------------NDBAPP SUBDOMAIN----------------------------------------------------------*/}}
{{- define "ndbapp.subdomain" -}}
  {{- printf "%s" "ndbappmysqldsvc"  -}}
{{- end -}}

{{/*--------------------NDBMGMD SUBDOMAIN----------------------------------------------------------*/}}
{{- define "mgm.subdomain" -}}
  {{- printf "%s" "ndbmgmdsvc"  -}}
{{- end -}}

{{/*--------------------NDBMTD SUBDOMAIN----------------------------------------------------------*/}}
{{- define "ndb.subdomain" -}}
  {{- printf "%s" "ndbmtdsvc"  -}}
{{- end -}}

{{/*--------------------NDB STS NAME----------------------------------------------------------*/}}
{{- define "ndb.ndbstsnamewithoutprefix" -}}
  {{- printf "%s" "ndbmtd"  -}}
{{- end -}}

{{/*--------------------MGM STS NAME----------------------------------------------------------*/}}
{{- define "mgm.mgmtstsnamewithoutprefix" -}}
  {{- printf "%s" "ndbmgmd"  -}}
{{- end -}}

{{/*--------------------API STS NAME----------------------------------------------------------*/}}
{{- define "api.apistsnamewithoutprefix" -}}
  {{- printf "%s" "ndbmysqld"  -}}
{{- end -}}

{{/*--------------------NDBAPP STS NAME----------------------------------------------------------*/}}
{{- define "ndbapp.ndbappstsnamewithoutprefix" -}}
  {{- printf "%s" "ndbappmysqld"  -}}
{{- end -}}

{{/*--------------------Expand the name of the stateful set pods.-------------------------------------------------------------*/}}
{{- define "mgm.mgmtstsname" -}}
{{- $name := include "mgm.mgmtstsnamewithoutprefix" . -}}
{{- $prefix := default "" .Values.global.k8sResource.pod.prefix | lower -}}
{{- printf "%s-%s" $prefix $name | trunc 63 | trimPrefix "-" -}}
{{- end -}}



{{- define "dbmonitorsvc-service.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default "db-monitor-svc" .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "dbbackupmanagersvc-service.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default "db-backup-manager-svc" .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}


{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "db-replication-svc.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- if .Values.global.k8sResource.pod.prefix -}}
{{- $name := default .dbReplSvcDeploy.name .Values.nameOverride -}}
{{- $prefix := default "" .Values.global.k8sResource.pod.prefix | lower -}}
{{- printf "%s-%s" $prefix $name | trunc 63 | trimPrefix "-" -}}
{{- else -}}
{{- $name := default .dbReplSvcDeploy.name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- printf "%s" .Release.Name | trunc 63 | trimPrefix "-" -}}
{{- else -}}
{{- $name := default .dbReplSvcDeploy.name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimPrefix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}


{{- define "dbreplicationsvc-service.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .dbReplSvcDeploy.name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "db-replication-svc.localsiteport" -}}
{{- printf "%s" .dbReplSvcDeploy.replication.localsiteport | trunc 63 -}}
{{- end -}}

{{/*
Create global common labels for all containers.
*/}}
{{- define "labels.commonlabels" -}}
  {{- $global_common_labels := .Values.global.commonlabels -}}
  {{- range $key, $value := $global_common_labels }}
    {{- $key | toYaml | nindent 4 }}: {{ $value }}
  {{- end }}
{{- end }}


{{/*------------------------------poddisruptionbudgets----------------------------*/}}
{{- define "api.pdb" -}}
  {{- printf "%s" "ndbmysqldpdb"  -}}
{{- end -}}

{{- define "ndbapp.pdb" -}}
  {{- printf "%s" "ndbappmysqldpdb"  -}}
{{- end -}}

{{- define "ndb.pdb" -}}
  {{- printf "%s" "ndbmtdpdb"  -}}
{{- end -}}

{{- define "mgm.pdb" -}}
  {{- printf "%s" "ndbmgmpdb"  -}}
{{- end -}}


{{- define "dbreplicationsvc-pdb.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .dbReplSvcDeploy.name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "dbmonitorsvc-pdb.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default "db-monitor-svc" .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "dbbackupmanagersvc-pdb.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default "db-backup-manager-svc" .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}


{{/*----------------------------------loopback.ip----------------------------------------------------*/}}
{{- define "loopback.ip" -}}
{{- if .Values.global.useIPv6 -}}
{{- printf "::1" -}}
{{- else -}}
{{- printf "127.0.0.1" -}}
{{- end -}}
{{- end -}}


{{/*----------------------------------multiplereplicationgroups----------------------------------------------------*/}}
{{- define "multiplereplicationgroups.getdefaultsqlnodelist" -}}
  {{- $channelgroupid := .ChannelGroupId }}
  {{- $totalchannels := len .Values.global.multiplereplicationgroups.replicationchannelgroups}}
  {{- $totalapinode := .Values.global.apiReplicaCount }}
  {{- $totalsites := div $totalapinode $totalchannels }}
  {{- $totalsites := (div $totalsites 2 | int) }}
  {{- $groupidminusone := sub $channelgroupid 1 }}
  {{- $start := mul $groupidminusone 2 }}
  {{- $difference := mul $totalchannels 2 }}
  {{- range $key, $e := until $totalsites }}
    {{- if ne $key 0 -}}
      {{ " " }}
    {{- end }}
    {{- $change := mul $difference $key }}
    {{- $primarynodenumber := add $start $change }}
    {{- $secondarynodenumber := add $primarynodenumber 1 }}
    {{- template "api.apistsnamewithoutprefix" }}-{{- $primarynodenumber }}.{{- template "api.subdomain" }}.{{ $.Values.global.namespace }}.svc.{{- $.Values.global.domain }}{{ " " }}
    {{- template "api.apistsnamewithoutprefix" }}-{{- $secondarynodenumber }}.{{- template "api.subdomain" }}.{{ $.Values.global.namespace }}.svc.{{- $.Values.global.domain }}
  {{- end }}
{{- end -}}


{{- define "multiplereplicationgroups.isqlnodesconfigured" -}}
  {{- $issqllistconfigured := "false" }}
  {{- range $key, $channelgroup := .Values.global.multiplereplicationgroups.replicationchannelgroups }}
    {{- if gt ( len $channelgroup.sqllist ) 0 }}
      {{- "true" }}
    {{- end }}
  {{- end }}
  {{- $issqllistconfigured }}
{{- end -}}


{{/*----------------------db-infra-monitor-------------------------------*/}}
{{- define "inframonitorsidecarcontainer.fullname" -}}
{{- $prefix := default "" .Values.global.k8sResource.container.prefix | lower -}}
{{- $imagename := default "db-infra-monitor" .Values.inframonitor.image.name | lower -}}
{{- printf "%s-%s" $prefix $imagename | trunc 63 | trimPrefix "-" -}}
{{- end -}}




{{/*-----------------------ndbmtd container full name-------------------------------*/}}
{{- define "ndb.containerfullname" -}}
{{- $prefix := default "" .Values.global.k8sResource.container.prefix | lower -}}
{{- $imagename := "mysqlndbcluster" | lower -}}
{{- printf "%s-%s" $prefix $imagename | trunc 63 | trimPrefix "-" -}}
{{- end -}}

{{- define "ndb.ndbstsname" -}}
{{- $name := include "ndb.ndbstsnamewithoutprefix" . -}}
{{- $prefix := default "" .Values.global.k8sResource.pod.prefix | lower -}}
{{- printf "%s-%s" $prefix $name | trunc 63 | trimPrefix "-" -}}
{{- end -}}


{{/*--------------------Expand the name of the container for ndbmgmd-----------------*/}}
{{- define "mgm.containerfullname" -}}
{{- $prefix := default "" .Values.global.k8sResource.container.prefix | lower -}}
{{- $imagename := "mysqlndbcluster" | lower -}}
{{- printf "%s-%s" $prefix $imagename | trunc 63 | trimPrefix "-" -}}
{{- end -}}
