Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}

{{- define "udr-connector.fullname" -}}
{{- if .Values.udrConnectorFullnameOverride -}}
{{- .Values.udrConnectorFullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}


{{- define "chf-connector.fullname" -}}
{{- if .Values.chfConnectorFullnameOverride -}}
{{- .Values.chfConnectorFullnameOverride | trunc 63 | trimSuffix "-" -}}
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

{{- define "occnp-udr-connector-deployment-name" -}}
{{- printf "%s-%s" .Release.Name "occnp-udr-connector" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "occnp-udr-connector-hpa-name" -}}
{{- printf "%s-%s" .Release.Name "occnp-udr-connector-hpa" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "occnp-chf-connector-deployment-name" -}}
{{- printf "%s-%s" .Release.Name "occnp-chf-connector" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "occnp-chf-connector-hpa-name" -}}
{{- printf "%s-%s" .Release.Name "occnp-chf-connector-hpa" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*--------------------Common Service Account Name---------------------------------------------------------------*/}}
{{- define "ocnf.serviceaccount" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}-serviceaccount
{{- end -}}
{{/*--------------------------Ephemeral Storage-------------------------------------------------------------*/}}
{{- define "pcf-userservice-ephemeral-storage-request" -}}
 {{- div (mul (add .Values.global.logStorage .Values.global.crictlStorage) 11) 10 -}}Mi
{{- end -}}

