{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "db-backup-manager-svc.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*--------------------Expand the name of the container.-------------------------------------------------------------*/}}
{{- define "db-backup-manager-svc.containerfullname" -}}
{{- $prefix := default "" .Values.global.k8sResource.container.prefix | lower -}}
{{- printf "%s-%s" $prefix (include "db-backup-manager-svc.name" . ) | trunc 63 | trimPrefix "-"|trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 52 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "db-backup-manager-svc.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- if .Values.global.k8sResource.pod.prefix -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- $prefix := default "" .Values.global.k8sResource.pod.prefix | lower -}}
{{- printf "%s-%s" $prefix $name | trunc 63 | trimPrefix "-" | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- printf "%s-%s" .Release.Name | trunc 63 | trimPrefix "-" | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimPrefix "-" | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}



{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "db-backup-manager-svc.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
