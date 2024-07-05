# Copyright 2019 (C), Oracle and/or its affiliates. All rights reserved.

{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "nsconfig.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "nsconfig.fullname" -}}
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

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "nsconfig.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*-------------------- Persistent configuration --------------------------------------------------------------------*/}}
{{- define "defaultconfig-nsconfig.labels" -}}
logging:
  loglevel: {{ .Values.loglevel }}
{{- end -}}


{{- define "ocnssf-nsconfig-service-hook-name-pre-install" -}}
{{- printf "%s-%s-%s" .Release.Name "nsconfig" "pre-install" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ocnssf-nsconfig-service-hook-name-post-install" -}}
{{- printf "%s-%s-%s" .Release.Name "nsconfig" "post-install" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ocnssf-nsconfig-service-hook-name-pre-upgrade" -}}
{{- printf "%s-%s-%s" .Release.Name "nsconfig" "pre-upgrade" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ocnssf-nsconfig-service-hook-name-post-upgrade" -}}
{{- printf "%s-%s-%s" .Release.Name "nsconfig" "post-upgrade" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ocnssf-nsconfig-service-hook-name-pre-rollback" -}}
{{- printf "%s-%s-%s" .Release.Name "nsconfig" "pre-rollback" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ocnssf-nsconfig-service-hook-name-post-rollback" -}}
{{- printf "%s-%s-%s" .Release.Name "nsconfig" "post-rollback" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ocnssf-nsconfig-service-hook-name-pre-delete" -}}
{{- printf "%s-%s-%s" .Release.Name "nsconfig" "pre-delete" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ocnssf-nsconfig-service-hook-name-post-delete" -}}
{{- printf "%s-%s-%s" .Release.Name "nsconfig" "post-delete" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
