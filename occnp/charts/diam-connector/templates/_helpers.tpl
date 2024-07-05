{{/*Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "diam-connector.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "service-prefix" -}}
{{- if .Values.global.nfName -}}
{{- printf "%s-%s" .Release.Name .Values.global.nfName | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "diam-connector-deployment-name" -}}
{{- printf "%s-%s" .Release.Name "oc-diam-connector" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "diam-connector-configmap-name" -}}
{{- printf "%s-%s" .Release.Name "oc-diam-connector-config-peers" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*--------------------------Ephemeral Storage-------------------------------------------------------------*/}}
{{- define "diam-connector-ephemeral-storage-request" -}}
 {{- div (mul (add .Values.global.logStorage .Values.global.crictlStorage) 11) 10 -}}Mi
{{- end -}}

{{/*--------------------Common Service Account Name---------------------------------------------------------------*/}}
{{- define "ocnf.serviceaccount" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}-serviceaccount
{{- end -}}

{{- define "diam-connector-hook-name-pre-install" -}}
{{- printf "%s-%s-%s" .Release.Name "oc-diam-connector" "pre-install" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "diam-connector-hook-name-post-install" -}}
{{- printf "%s-%s-%s" .Release.Name "oc-diam-connector" "post-install" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "diam-connector-hook-name-pre-upgrade" -}}
{{- printf "%s-%s-%s" .Release.Name "oc-diam-connector" "pre-upgrade" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "diam-connector-hook-name-post-upgrade" -}}
{{- printf "%s-%s-%s" .Release.Name "oc-diam-connector" "post-upgrade" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "diam-connector-hook-name-pre-rollback" -}}
{{- printf "%s-%s-%s" .Release.Name "oc-diam-connector" "pre-rollback" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "diam-connector-hook-name-post-rollback" -}}
{{- printf "%s-%s-%s" .Release.Name "oc-diam-connector" "post-rollback" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "diam-connector-hook-name-pre-delete" -}}
{{- printf "%s-%s-%s" .Release.Name "oc-diam-connector" "pre-delete" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "diam-connector-hook-name-post-delete" -}}
{{- printf "%s-%s-%s" .Release.Name "oc-diam-connector" "post-delete" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "config-server-container" -}}
{{- printf "%s-%s-%s" .Release.Name .Values.global.configServerFullNameOverride "hook-container" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "diam-connector-hpa-name" -}}
{{- printf "%s-%s" .Release.Name "diam-connector-hpa" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

