{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "mgm.name" -}}
  {{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "mgm.fullname" -}}
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

{{/*--------------------Expand the name of the stateful set pods.-------------------------------------------------------------*/}}
{{- define "mgm.ndbstsname" -}}
{{- $name := include "ndb.ndbstsnamewithoutprefix" . -}}
{{- $prefix := default "" .Values.global.k8sResource.pod.prefix | lower -}}
{{- printf "%s-%s" $prefix $name | trunc 63 | trimPrefix "-" -}}
{{- end -}}

{{- define "mgm.apistsname" -}}
{{- $name := include "api.apistsnamewithoutprefix" . -}}
{{- $prefix := default "" .Values.global.k8sResource.pod.prefix | lower -}}
{{- printf "%s-%s" $prefix $name | trunc 63 | trimPrefix "-" -}}
{{- end -}}

{{- define "mgm.ndbappstsname" -}}
{{- $name := include "ndbapp.ndbappstsnamewithoutprefix" . -}}
{{- $prefix := default "" .Values.global.k8sResource.pod.prefix | lower -}}
{{- printf "%s-%s" $prefix $name | trunc 63 | trimPrefix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "mgm.chart" -}}
  {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "mgm.labels" -}}
helm.sh/chart: {{ include "mgm.chart" . }}
{{ include "mgm.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "mgm.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mgm.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "mgm.serviceAccountName" -}}
  {{- if .Values.serviceAccount.create -}}
    {{ default (include "mgm.fullname" .) .Values.serviceAccount.name }}
  {{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
  {{- end -}}
{{- end -}}
