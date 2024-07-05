Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "pcrf-core.fullname" -}}
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

{{- define "pcrf-core-deployment-name" -}}
{{- printf "%s-%s" .Release.Name "pcrf-core" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pcrf-core-headless-label-name" -}}
{{- printf "%s-%s" .Release.Name "pcrf-core-headless" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pcrf-core-hook-name-pre-install" -}}
{{- printf "%s-%s-%s" .Release.Name "pcrf-core" "pre-install" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pcrf-core-hook-name-post-install" -}}
{{- printf "%s-%s-%s" .Release.Name "pcrf-core" "post-install" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pcrf-core-hook-name-pre-upgrade" -}}
{{- printf "%s-%s-%s" .Release.Name "pcrf-core" "pre-upgrade" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pcrf-core-hook-name-post-upgrade" -}}
{{- printf "%s-%s-%s" .Release.Name "pcrf-core" "post-upgrade" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pcrf-core-hook-name-pre-rollback" -}}
{{- printf "%s-%s-%s" .Release.Name "pcrf-core" "pre-rollback" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pcrf-core-hook-name-post-rollback" -}}
{{- printf "%s-%s-%s" .Release.Name "pcrf-core" "post-rollback" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pcrf-core-hook-name-pre-delete" -}}
{{- printf "%s-%s-%s" .Release.Name "pcrf-core" "pre-delete" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pcrf-core-hook-name-post-delete" -}}
{{- printf "%s-%s-%s" .Release.Name "pcrf-core" "post-delete" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*--------------------------Ephemeral Storage-------------------------------------------------------------*/}}
{{- define "pcrf-core-ephemeral-storage-request" -}}
 {{- div (mul (add .Values.global.logStorage .Values.global.crictlStorage) 11) 10 -}}Mi
{{- end -}}

{{- define "pcrf-core-hpa-name" -}}
{{- printf "%s-%s" .Release.Name "pcrf-core-hpa" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

