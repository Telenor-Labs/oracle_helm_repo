{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "api.name" -}}
  {{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "api.fullname" -}}
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
{{- define "api.mgmtstsname" -}}
{{- $name := include "mgm.mgmtstsnamewithoutprefix" . -}}
{{- $prefix := default "" .Values.global.k8sResource.pod.prefix | lower -}}
{{- printf "%s-%s" $prefix $name | trunc 63 | trimPrefix "-" -}}
{{- end -}}

{{- define "api.ndbstsname" -}}
{{- $name := include "ndb.ndbstsnamewithoutprefix" .  -}}
{{- $prefix := default "" .Values.global.k8sResource.pod.prefix | lower -}}
{{- printf "%s-%s" $prefix $name | trunc 63 | trimPrefix "-" -}}
{{- end -}}

{{- define "api.apistsname" -}}
{{- $name := include "api.apistsnamewithoutprefix" . -}}
{{- $prefix := default "" .Values.global.k8sResource.pod.prefix | lower -}}
{{- printf "%s-%s" $prefix $name | trunc 63 | trimPrefix "-" -}}
{{- end -}}

{{- define "ndbapp.apistsname" -}}
{{- $name := include "ndbapp.ndbappstsnamewithoutprefix" . -}}
{{- $prefix := default "" .Values.global.k8sResource.pod.prefix | lower -}}
{{- printf "%s-%s" $prefix $name | trunc 63 | trimPrefix "-" -}}
{{- end -}}

{{/*--------------------Expand the name of the container.-------------------------------------------------------------*/}}
{{- define "api.containerfullname" -}}
{{- $prefix := default "" .Values.global.k8sResource.container.prefix | lower -}}
{{- $imagename := "mysqlndbcluster" | lower -}}
{{- printf "%s-%s" $prefix $imagename | trunc 63 | trimPrefix "-" -}}
{{- end -}}

{{- define "api.initsidecarfullname" -}}
{{- $prefix := default "" .Values.global.k8sResource.container.prefix | lower -}}
{{- $name := default "init-sidecar" .Values.initsidecar.name | lower -}}
{{- printf "%s-%s" $prefix $name | trunc 63 | trimPrefix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "api.chart" -}}
  {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "api.labels" -}}
helm.sh/chart: {{ include "api.chart" . }}
{{ include "api.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "api.selectorLabels" -}}
app.kubernetes.io/name: {{ include "api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "api.serviceAccountName" -}}
  {{- if .Values.serviceAccount.create -}}
    {{ default (include "api.fullname" .) .Values.serviceAccount.name }}
  {{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
  {{- end -}}
{{- end -}}

{{- define "ndbnodes" -}}
{{- $nodeCount := .Values.global.ndbReplicaCount | int }}
  {{- range $index0 := until $nodeCount -}}
    {{- $index1 := $index0 | add1 -}}
id={{ $index1 }}{{ if ne $index1 $nodeCount }}\|{{ end }}
  {{- end -}}
{{- end -}}

{{- define "apiemptyslots" -}}
{{- $strnoemptyslots := "NOEMPTYSLOTNODEIDS" }}
{{- $nodeCount := .Values.global.api.numOfEmptyApiSlots | int }}
{{- $startingemptyapislotnodeid := .Values.global.api.startEmptyApiSlotNodeId | int }}
{{- if eq 0 $nodeCount -}}
  {{- $strnoemptyslots }}
{{- else -}}
  {{- range $index0 := until $nodeCount -}}
  {{- $index1 := $index0 | add1 -}}
id={{ add $startingemptyapislotnodeid $index0 }}{{ if ne $index1 $nodeCount }}\|{{ end }}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- define "checkannotationsdefinedforservice" -}}
{{- $svcannotationsexist := "false" }}
{{- range $k, $sqlsvc := $.Values.externalService.sqlgeorepsvclabels }}
{{- if $sqlsvc.annotations }}
{{- if eq $sqlsvc.name .ndbmysqldsvcname }}
{{- $svcannotationsexist := "true" }}
{{- end }}
{{- end }}
{{- end }}
{{- printf "%s" $svcannotationsexist }}
{{- end }}
