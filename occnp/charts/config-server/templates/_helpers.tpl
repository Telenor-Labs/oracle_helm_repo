{{/*Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "config-server.fullname" -}}
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

{{- define "config-server-deployment-name" -}}
{{- printf "%s-%s" .Release.Name .Values.global.configServerFullNameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-config-server" -}}
{{- printf "%s-%s" (include "service-prefix" .) "config-server" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "config-server-hook-name-pre-install" -}}
{{- printf "%s-%s-%s" .Release.Name .Values.global.configServerFullNameOverride "pre-install" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "config-server-hook-name-post-install" -}}
{{- printf "%s-%s-%s" .Release.Name .Values.global.configServerFullNameOverride "post-install" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "config-server-hook-name-pre-upgrade" -}}
{{- printf "%s-%s-%s" .Release.Name .Values.global.configServerFullNameOverride "pre-upgrade" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "config-server-hook-name-post-upgrade" -}}
{{- printf "%s-%s-%s" .Release.Name .Values.global.configServerFullNameOverride "post-upgrade" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "config-server-hook-name-pre-rollback" -}}
{{- printf "%s-%s-%s" .Release.Name .Values.global.configServerFullNameOverride "pre-rollback" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "config-server-hook-name-post-rollback" -}}
{{- printf "%s-%s-%s" .Release.Name .Values.global.configServerFullNameOverride "post-rollback" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "config-server-hook-name-pre-delete" -}}
{{- printf "%s-%s-%s" .Release.Name .Values.global.configServerFullNameOverride "pre-delete" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "config-server-hook-name-post-delete" -}}
{{- printf "%s-%s-%s" .Release.Name .Values.global.configServerFullNameOverride "post-delete" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{/*--------------------Common Tolerations----------------------------------------------------------------------*/}}
{{- define "ocnf.tolerations" }}
 {{- $localTolerationsSetting := .Values.tolerationsSetting | default "USE_GLOBAL_VALUE" }}
 {{- $globalTolerationsSetting := .Values.global.tolerationsSetting | default "DISABLED" }}
 {{- $tolerations := "" }}

 {{- if (eq $localTolerationsSetting "ENABLED") }}
   {{- $tolerations =  .Values.tolerations }}
 {{- else if (eq $localTolerationsSetting "USE_GLOBAL_VALUE") }}
   {{- if (eq $globalTolerationsSetting "ENABLED")}}
     {{- $tolerations = .Values.global.tolerations }}
   {{- end }}
 {{- end }}

 {{- if $tolerations }}
{{- toYaml $tolerations }}
 {{- end }}
{{- end }}
{{/*--------------------Common NodeSelector----------------------------------------------------------------------*/}}
{{- define "ocnf.nodeselector" }}
 {{- $localNodeSelection := .Values.nodeSelection | default "USE_GLOBAL_VALUE" }}
 {{- $globalNodeSelection := .Values.global.nodeSelection | default "DISABLED" }}
 {{- $nodeselector := "" }}

 {{- if (eq $localNodeSelection "ENABLED") }}
   {{- $nodeselector =  .Values.nodeSelector }}
 {{- else if (eq $localNodeSelection "USE_GLOBAL_VALUE") }}
   {{- if (eq $globalNodeSelection "ENABLED")}}
     {{- $nodeselector = .Values.global.nodeSelector }}
   {{- end }}
 {{- end }}

 {{- if $nodeselector }}
{{- toYaml $nodeselector }}
 {{- end }}
{{- end }}

{{/*--------------------------Ephemeral Storage-------------------------------------------------------------*/}}
{{- define "config-server-ephemeral-storage-request" -}}
 {{- div (mul (add .Values.global.logStorage .Values.global.crictlStorage) 11) 10 -}}Mi
{{- end -}}


