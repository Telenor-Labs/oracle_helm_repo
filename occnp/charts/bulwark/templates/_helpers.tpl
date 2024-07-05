{{/*
    Create a default fully qualified app name.
    We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
    If release name contains chart name it will be used as a full name.
*/}}

{{- define "bulwark-service.fullname" -}}
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

{{- define "service-name-bulwark" -}}
{{- include "service-prefix" . }}-bulwark
{{- end -}}

{{/*------------------- get prefix ------------------------------*/}}
{{- define "getprefix" -}}
{{  default "" .Values.global.k8sResource.container.prefix | lower }}
{{- end -}}

{{/*------------------- getsuffix. ---------------------------------*/}}
{{- define "getsuffix" -}}
{{  default "" .Values.global.k8sResource.container.suffix | lower }}
{{- end -}}

{{/*--------------------Expand the name of the container.----------------------*/}}
{{- define "container.fullname" -}}
{{- $prefix := default "" .Values.global.k8sResource.container.prefix | lower -}}
{{- $suffix := default "" .Values.global.k8sResource.container.suffix | lower -}}
{{- printf "%s-%s-%s" $prefix (include "chart.fullname" . ) $suffix | trunc 63 | trimPrefix "-"|trimSuffix "-" -}}
{{- end -}}

{{- define "bulwarkservice-deployment-name" -}}
{{- printf "%s-%s" .Release.Name "bulwark" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "bulwarkservice-hpa-name" -}}
{{- printf "%s-%s" .Release.Name "bulwark-hpa" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*--------------------Coherence-----------------------------*/}}
{{- define "bulwark-service-coherence-headless-service-label" -}}
{{- printf "%s-%s" .Release.Name "bulwark-service" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-bulwark-service-coherence-headless" -}}
{{- printf "%s-%s" (include "service-prefix" .) "bulwark-coherence-headless" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-config-server" -}}
{{- printf "%s-%s" (include "service-prefix" .) "config-server" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "chart.fullname" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "bulwark.serviceaccount" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}-bulwark-serviceaccount
{{- end -}}

{{- define "bulwark.role" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}-bulwark-role
{{- end -}}

{{- define "bulwark.rolebinding" -}}
{{ .Release.Name | trunc 63 | trimSuffix "-" -}}-bulwark-rolebinding
{{- end -}}

{{/*-------------------- annotations deployment ------------------------*/}}
{{- define "annotations.deployments" -}}
  {{- $global_allResources_annotations := .Values.global.customExtension.allResources.annotations -}}
  {{- $global_deployment_annotations := .Values.global.customExtension.nonlbDeployments.annotations -}}
  {{- if .Values.useLbLabelsAndAnnotations }}
    {{- $global_deployment_annotations = .Values.global.customExtension.lbDeployments.annotations -}}
  {{- end -}}
  {{- $deployment_specific_annotations := .Values.deployment.customExtension.annotations -}}
  {{- $result := dict }}
  {{- $result := merge $result $deployment_specific_annotations  }}
  {{- $result := merge $result $global_deployment_annotations }}
  {{- $result := merge $result $global_allResources_annotations }}
  {{- range $key, $value := $result }}
    {{- $key | toYaml | trimSuffix "\n" | nindent 4 }}: {{ $value | trimSuffix "\n" | quote }}
  {{- end }}
  {{- include "engineering.annotations" . | nindent 4 }}
  {{- include "factory.annotations" . }}
{{- end -}}

{{- define "engineering.annotations" -}}
{{- end -}}

{{- define "factory.annotations" -}}
  {{- range $key, $value := $.Values.global.customExtension.factoryAnnotationsTemplates }}
    {{- $key | toYaml | trimSuffix "\n" | nindent 4 }}: {{ tpl $value $ }}
  {{- end }}
{{- end -}}

{{/*-------------------- labels deployment ------------------------*/}}
{{- define "labels.deployments" -}}
  {{- $global_allResources_labels := .Values.global.customExtension.allResources.labels -}}
  {{- $global_deployment_labels := .Values.global.customExtension.nonlbDeployments.labels -}}
  {{- if .Values.useLbLabelsAndAnnotations }}
    {{- $global_deployment_labels = .Values.global.customExtension.lbDeployments.labels }}
  {{- end }}
  {{- $deployment_specific_labels := .Values.deployment.customExtension.labels -}}
  {{- $result := dict }}
  {{- $result := merge $result $deployment_specific_labels }}
  {{- $result := merge $result $global_deployment_labels }}
  {{- $result := merge $result $global_allResources_labels }}
  {{- range $key, $value := $result }}
    {{- $key | toYaml | trimSuffix "\n" | nindent 4 }}: {{ $value | trimSuffix "\n" | quote }}
  {{- end }}
  {{- include "engineering.labels" . | nindent 4 }}
  {{- include "factory.labels" . }}
{{- end -}}

{{- define "engineering.labels" -}}
app.kubernetes.io/name: '{{ template "chart.fullname" . }}'
helm.sh/chart: '{{ template "chart.fullnameandversion" . }}'
app.kubernetes.io/instance: '{{ .Release.Name }}'
app.kubernetes.io/managed-by: '{{ .Release.Service }}'
app.kubernetes.io/version: '{{ .Chart.AppVersion }}'
app.kubernetes.io/part-of: occnp
application: occnp
microservice: {{ .Values.fullnameOverride | default (printf "%s-%s" (default "occnp" .Values.appName) (include "chart.fullname" . )) }}
engVersion: {{ .Chart.Version | quote }}
mktgVersion: {{ .Chart.AppVersion | quote }}
vendor: Oracle
{{- end -}}

{{/*--------------------Create chart name and version as used by the chart label.---------------------------------*/}}
{{- define "chart.fullnameandversion" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "factory.labels" -}}
  {{- range $key, $value := $.Values.global.customExtension.factoryLabelTemplates }}
    {{- $key | toYaml | trimSuffix "\n" | nindent 4 }}: {{ tpl $value $ }}
  {{- end }}
{{- end -}}

{{/*-----------Labels for All kubernetes resources-----------------*/}}
{{- define "labels.allResources" -}}
{{- include "custom.extensions.labels.allResources" . }}
{{- include "engineering.labels" . | nindent 4 }}
{{- end -}}

{{/*----------- annotations for all kubernetes resources-----------------*/}}
{{- define "annotations.allResources" -}}
  {{- include "custom.extensions.annotations.allResources" . }}
  {{- include "engineering.annotations" . | nindent 4 }}
{{- end -}}

{{/*-------------------- annotations service ------------------------*/}}
{{- define "annotations.services" -}}
  {{- $global_allResources_annotations := .Values.global.customExtension.allResources.annotations -}}
  {{- $global_services_annotations := .Values.global.customExtension.nonlbServices.annotations -}}
  {{- if .Values.useLbLabelsAndAnnotations }}
    {{- $global_services_annotations = .Values.global.customExtension.lbServices.annotations -}}
  {{- end -}}
  {{- $service_specific_annotations := .Values.service.customExtension.annotations -}}
  {{- $result := dict }}
  {{- $result := merge $result $service_specific_annotations }}
  {{- $result := merge $result $global_services_annotations }}
  {{- $result := merge $result $global_allResources_annotations }}
  {{- range $key, $value := $result }}
    {{- $key | toYaml | trimSuffix "\n" | nindent 4 }}: {{ $value | trimSuffix "\n" | quote }}
  {{- end }}
  {{- include "engineering.annotations" . | nindent 4 }}
  {{- include "factory.annotations" . }}
{{- end -}}

{{/*-------------------- labels services ------------------------*/}}
{{- define "labels.services" -}}
  {{- $global_allResources_labels := .Values.global.customExtension.allResources.labels -}}
  {{- $global_services_labels := .Values.global.customExtension.nonlbServices.labels -}}
  {{- if .Values.useLbLabelsAndAnnotations -}}
     {{- $global_services_labels = .Values.global.customExtension.lbServices.labels -}}
  {{- end -}}
  {{- $service_specific_labels := .Values.service.customExtension.labels -}}
  {{- $result := dict }}
  {{- $result := merge $result $service_specific_labels }}
  {{- $result := merge $result $global_services_labels }}
  {{- $result := merge $result $global_allResources_labels }}
  {{- range $key, $value := $result }}
    {{- $key | toYaml | trimSuffix "\n" | nindent 4 }}: {{ $value | trimSuffix "\n" | quote }}
  {{- end }}
  {{- include "engineering.labels" . | nindent 4 }}
  {{- include "factory.labels" . }}
{{- end -}}

{{/*--------------------CustomExtension labels for all kubernetes resources-----------------------------------------------------------*/}}
{{- define "custom.extensions.labels.allResources" -}}
  {{- $global_allResources_labels := .Values.global.customExtension.allResources.labels -}}
  {{- range $key, $value := $global_allResources_labels }}
    {{- $key | toYaml | trimSuffix "\n" | nindent 4 }}: {{ $value | trimSuffix "\n" | quote }}
  {{- end }}
{{- end -}}

{{/*--------------------CustomExtension annotations for all kubernetes resources-----------------------------------------------------------*/}}
{{- define "custom.extensions.annotations.allResources" -}}
  {{- $global_allResources_annotations := .Values.global.customExtension.allResources.annotations -}}
  {{- range $key, $value := $global_allResources_annotations }}
    {{- $key | toYaml | trimSuffix "\n" | nindent 4 }}: {{ $value | trimSuffix "\n" | quote }}
  {{- end }}
{{- end -}}

{{/*----------------- Debug Tool Container--------------------------*/}}
{{- define "extraContainers" -}}
  {{- if (eq .Values.extraContainers "ENABLED") -}}
    {{- tpl (default .Values.global.extraContainersTpl .Values.extraContainersTpl) . }}
  {{- else if (eq .Values.extraContainers "USE_GLOBAL_VALUE") -}}
    {{- if (eq .Values.global.extraContainers "ENABLED") -}}
      {{- tpl (default .Values.global.extraContainersTpl .Values.extraContainersTpl) . }}
    {{- end -}}
  {{- end -}}
{{- end -}}



{{/*--------------------------Ephemeral Storage-------------------------------------------------------------*/}}
{{- define "bulwark-service-ephemeral-storage-request" -}}
 {{- div (mul (add .Values.global.logStorage .Values.global.crictlStorage) 11) 10 -}}Mi
{{- end -}}

