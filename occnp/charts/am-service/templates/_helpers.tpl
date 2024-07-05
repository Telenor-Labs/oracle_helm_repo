Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "am-service.fullname" -}}
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

{{/*-------------------get prefix.-------------------------------------------------------------*/}}
{{- define "getprefix" -}}
{{  default "" .Values.global.k8sResource.container.prefix | lower }}
{{- end -}}

{{/*-------------------getsuffix.-------------------------------------------------------------*/}}
{{- define "getsuffix" -}}
{{  default "" .Values.global.k8sResource.container.suffix | lower }}
{{- end -}}

{{/*--------------------Expand the name of the container.-------------------------------------------------------------*/}}
{{- define "container.fullname" -}}
{{- $prefix := default "" .Values.global.k8sResource.container.prefix | lower -}}
{{- $suffix := default "" .Values.global.k8sResource.container.suffix | lower -}}
{{- printf "%s-%s-%s" $prefix (include "chart.fullname" . ) $suffix | trunc 63 | trimPrefix "-"|trimSuffix "-" -}}
{{- end -}}

{{- define "pcf-amservice-deployment-name" -}}
{{- printf "%s-%s" .Release.Name "pcf-amservice" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pcf-amservice-hpa-name" -}}
{{- printf "%s-%s" .Release.Name "pcf-amservice-hpa" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pcf-amservice-hook-name-pre-install" -}}
{{- printf "%s-%s-%s" .Release.Name "pcf-amservice" "pre-install" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pcf-amservice-hook-name-post-install" -}}
{{- printf "%s-%s-%s" .Release.Name "pcf-amservice" "post-install" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pcf-amservice-hook-name-pre-upgrade" -}}
{{- printf "%s-%s-%s" .Release.Name "pcf-amservice" "pre-upgrade" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pcf-amservice-hook-name-post-upgrade" -}}
{{- printf "%s-%s-%s" .Release.Name "pcf-amservice" "post-upgrade" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pcf-amservice-hook-name-pre-rollback" -}}
{{- printf "%s-%s-%s" .Release.Name "pcf-amservice" "pre-rollback" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pcf-amservice-hook-name-post-rollback" -}}
{{- printf "%s-%s-%s" .Release.Name "pcf-amservice" "post-rollback" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pcf-amservice-hook-name-pre-delete" -}}
{{- printf "%s-%s-%s" .Release.Name "pcf-amservice" "pre-delete" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pcf-amservice-hook-name-post-delete" -}}
{{- printf "%s-%s-%s" .Release.Name "pcf-amservice" "post-delete" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*--------------------------Ephemeral Storage-------------------------------------------------------------*/}}
{{- define "pcf-amservice-v2-ephemeral-storage-request" -}}
 {{- div (mul (add .Values.global.logStorage .Values.global.crictlStorage) 11) 10 -}}Mi
{{- end -}}

