{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "db-replication-svc.name" -}}
{{- default .dbReplSvcDeploy.name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*--------------------Expand the name of the container.-------------------------------------------------------------*/}}
{{- define "db-replication-svc.containerfullname" -}}
{{- $prefix := default "" .Values.global.k8sResource.container.prefix | lower -}}
{{- printf "%s-%s" $prefix (include "db-replication-svc.name" . ) | trunc 63 | trimPrefix "-" -}}
{{- end -}}

{{- define "db-replication-svc.containerinitwaitforndbclusterfullname" -}}
{{- $prefix := default "" .Values.global.k8sResource.container.prefix | lower -}}
{{- printf "%s-%s" $prefix "init-wait-for-ndbcluster" | trunc 63 | trimPrefix "-" -}}
{{- end -}}

{{- define "db-replication-svc.containerinitdbreplicationsvcfullname" -}}
{{- $prefix := default "" .Values.global.k8sResource.container.prefix | lower -}}
{{- printf "%s-%s" $prefix "init-db-replication-svc" | trunc 63 | trimPrefix "-" -}}
{{- end -}}

{{- define "db-replication-svc.containerinitdiscoversqlipsfullname" -}}
{{- $prefix := default "" .Values.global.k8sResource.container.prefix | lower -}}
{{- printf "%s-%s" $prefix "init-discover-sql-ips" | trunc 63 | trimPrefix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "db-replication-svc.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "db-replication-svc.primaryhost" -}}
{{- if or (eq .Values.global.k8sResource.pod.prefix "") (hasPrefix .Values.global.k8sResource.pod.prefix .dbReplSvcDeploy.mysql.primaryhost) }}
{{- printf "%s" .dbReplSvcDeploy.mysql.primaryhost | trimPrefix "-"|trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Values.global.k8sResource.pod.prefix .dbReplSvcDeploy.mysql.primaryhost | trimPrefix "-"|trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "db-replication-svc.secondaryhost" -}}
{{- if or (eq .Values.global.k8sResource.pod.prefix "") (hasPrefix .Values.global.k8sResource.pod.prefix .dbReplSvcDeploy.mysql.secondaryhost) }}
{{- printf "%s" .dbReplSvcDeploy.mysql.secondaryhost | trimPrefix "-"|trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Values.global.k8sResource.pod.prefix .dbReplSvcDeploy.mysql.secondaryhost | trimPrefix "-"|trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "db-replication-svc.getskipslaveerrors" -}}
{{- range $key, $value := .Values.global.additionalndbconfigurations.mysqld }}
{{- if eq $key $.configname -}}
{{- $value -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "db-replication-svc.replicaslaveerrors" -}}
{{- if ne (include "db-replication-svc.getskipslaveerrors" (dict "Values" .Values "configname" "replica_skip_errors")) "" -}}
{{- printf "%s" (include "db-replication-svc.getskipslaveerrors" (dict "Values" .Values "configname" "replica_skip_errors")) -}}
{{- else if ne (include "db-replication-svc.getskipslaveerrors" (dict "Values" .Values "configname" "replica-skip-errors")) "" -}}
{{- printf "%s" (include "db-replication-svc.getskipslaveerrors" (dict "Values" .Values "configname" "replica-skip-errors")) -}}
{{- else if ne (include "db-replication-svc.getskipslaveerrors" (dict "Values" .Values "configname" "slave_skip_errors")) "" -}}
{{- printf "%s" (include "db-replication-svc.getskipslaveerrors" (dict "Values" .Values "configname" "slave_skip_errors")) -}}
{{- else if ne (include "db-replication-svc.getskipslaveerrors" (dict "Values" .Values "configname" "slave-skip-errors")) "" -}}
{{- printf "%s" (include "db-replication-svc.getskipslaveerrors" (dict "Values" .Values "configname" "slave-skip-errors")) -}}
{{- else -}}
{{- printf "" -}}
{{- end -}}
{{- end -}}

