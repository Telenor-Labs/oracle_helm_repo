Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "audit-service.fullname" -}}
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

{{- define "ocpm-audit-service-deployment-name" -}}
{{- printf "%s-%s" .Release.Name "ocpm-audit-service" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ocpm-audit-service-hpa-name" -}}
{{- printf "%s-%s" .Release.Name "ocpm-audit-service-hpa" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ocpm-audit-service-hook-name-pre-install" -}}
{{- printf "%s-%s-%s" .Release.Name "ocpm-audit-service" "pre-install" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ocpm-audit-service-hook-name-post-install" -}}
{{- printf "%s-%s-%s" .Release.Name "ocpm-audit-service" "post-install" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ocpm-audit-service-hook-name-pre-upgrade" -}}
{{- printf "%s-%s-%s" .Release.Name "ocpm-audit-service" "pre-upgrade" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ocpm-audit-service-hook-name-post-upgrade" -}}
{{- printf "%s-%s-%s" .Release.Name "ocpm-audit-service" "post-upgrade" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ocpm-audit-service-hook-name-pre-rollback" -}}
{{- printf "%s-%s-%s" .Release.Name "ocpm-audit-service" "pre-rollback" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ocpm-audit-service-hook-name-post-rollback" -}}
{{- printf "%s-%s-%s" .Release.Name "ocpm-audit-service" "post-rollback" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ocpm-audit-service-hook-name-pre-delete" -}}
{{- printf "%s-%s-%s" .Release.Name "ocpm-audit-service" "pre-delete" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ocpm-audit-service-hook-name-post-delete" -}}
{{- printf "%s-%s-%s" .Release.Name "ocpm-audit-service" "post-delete" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{/*--------------------------Ephemeral Storage-------------------------------------------------------------*/}}
{{- define "session-state-audit-ephemeral-storage-request" -}}
 {{- div (mul (add .Values.global.logStorage .Values.global.crictlStorage) 11) 10 -}}Mi
{{- end -}}

