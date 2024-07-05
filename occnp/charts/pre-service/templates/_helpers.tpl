Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "pre-service.fullname" -}}
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

{{- define "ocpm-pre-deployment-name" -}}
{{- printf "%s-%s" .Release.Name "ocpm-pre" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ocpm-pre-test-deployment-name" -}}
{{- printf "%s-%s" .Release.Name "ocpm-pre-test" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pcf-pre-hpa-name" -}}
{{- printf "%s-%s" .Release.Name "pcf-pre-hpa" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pcf-pre-test-hpa-name" -}}
{{- printf "%s-%s" .Release.Name "pcf-test-pre-hpa" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{/*--------------------------Ephemeral Storage-------------------------------------------------------------*/}}
{{- define "policy-runtime-ephemeral-storage-request" -}}
 {{- div (mul (add .Values.global.logStorage .Values.global.crictlStorage) 11) 10 -}}Mi
{{- end -}}

