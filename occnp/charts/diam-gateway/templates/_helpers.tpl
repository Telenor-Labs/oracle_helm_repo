Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "diam-gateway.fullname" -}}
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

{{/*----------diam-gateway Service Account Name----------*/}}
{{- define "diamGateway.serviceaccount" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}-diam-gateway-serviceaccount-hook-created
{{- end -}}


{{/*----------diam-gateway ROLE----------*/}}
{{- define "diamGateway.role" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}-diam-gateway-role
{{- end -}}

{{/*----------diam-gateway ROLE BINDING----------*/}}
{{- define "diamGateway.rolebinding" -}}
{{ .Release.Name | trunc 63 | trimSuffix "-" -}}-diam-gateway-rolebinding
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

{{- define "diam-gateway-deployment-name" -}}
{{- printf "%s-%s" .Release.Name "oc-diam-gateway" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "diam-gateway-headless-service-label" -}}
{{- printf "%s-%s" .Release.Name "oc-diam-gateway-headless" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*--------------------Coherence-----------------------------*/}}
{{- define "diam-gateway-coherence-headless-service-label" -}}
{{- printf "%s-%s" .Release.Name "oc-diam-gateway-coherence-headless" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "diam-gateway-configmap-name" -}}
{{- printf "%s-%s" .Release.Name "oc-diam-gateway-config-peers" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "diam-gateway-annotations.nonlbService" -}}
  {{- $global_allResources_annotations := .Values.global.customExtension.allResources.annotations -}}
  {{- $global_services_annotations := .Values.global.customExtension.nonlbServices.annotations -}}
  {{- $service_nonlbServices_annotations := .Values.nonlbService.customExtension.annotations -}}
  {{- $service_specific_annotations := .Values.service.customExtension.annotations -}}
  {{- $result := dict }}
  {{- $result := merge $result $service_specific_annotations }}
  {{- $result := merge $result $service_nonlbServices_annotations }}
  {{- $result := merge $result $global_services_annotations }}
  {{- $result := merge $result $global_allResources_annotations }}
  {{- range $key, $value := $result }}
    {{- $key | toYaml | trimSuffix "\n" | nindent 4 }}: {{ $value | trimSuffix "\n" | quote }}
  {{- end }}
{{- end -}}

{{- define "diam-gateway-annotations.lbService" -}}
  {{- $global_allResources_annotations := .Values.global.customExtension.allResources.annotations -}}
  {{- $global_services_annotations := .Values.global.customExtension.nonlbServices.annotations -}}
  {{- if .Values.useLbLabelsAndAnnotations }}
    {{- $global_services_annotations = .Values.global.customExtension.lbServices.annotations -}}
  {{- end -}}
  {{- $service_lbServices_annotations := .Values.lbService.customExtension.annotations -}}
  {{- $service_specific_annotations := .Values.service.customExtension.annotations -}}
  {{- $result := dict }}
  {{- $result := merge $result $service_specific_annotations }}
  {{- $result := merge $result $service_lbServices_annotations }}
  {{- $result := merge $result $global_services_annotations }}
  {{- $result := merge $result $global_allResources_annotations }}
  {{- range $key, $value := $result }}
    {{- $key | toYaml | trimSuffix "\n" | nindent 4 }}: {{ $value | trimSuffix "\n" | quote }}
  {{- end }}
{{- end -}}

{{- define "diam-gateway-labels.lbService" -}}
  {{- $global_allResources_labels := .Values.global.customExtension.allResources.labels -}}
  {{- $global_services_labels := .Values.global.customExtension.nonlbServices.labels -}}
  {{- if .Values.useLbLabelsAndAnnotations -}}
    {{- $global_services_labels = .Values.global.customExtension.lbServices.labels -}}
  {{- end -}}
  {{- $service_lbServices_labels := .Values.lbService.customExtension.labels -}}
  {{- $service_specific_labels := .Values.service.customExtension.labels -}}
  {{- $result := dict }}
  {{- $result := merge $result $service_specific_labels }}
  {{- $result := merge $result $service_lbServices_labels }}
  {{- $result := merge $result $global_services_labels }}
  {{- $result := merge $result $global_allResources_labels }}
  {{- range $key, $value := $result }}
    {{- $key | toYaml | trimSuffix "\n" | nindent 4 }}: {{ $value | trimSuffix "\n" | quote }}
  {{- end }}
{{- end -}}

{{- define "diam-gateway-labels.nonlbService" -}}
  {{- $global_allResources_labels := .Values.global.customExtension.allResources.labels -}}
  {{- $global_services_labels := .Values.global.customExtension.nonlbServices.labels -}}
  {{- $service_nonlbServices_labels := .Values.nonlbService.customExtension.labels -}}
  {{- $service_specific_labels := .Values.service.customExtension.labels -}}
  {{- $result := dict }}
  {{- $result := merge $result $service_specific_labels }}
  {{- $result := merge $result $service_nonlbServices_labels }}
  {{- $result := merge $result $global_services_labels }}
  {{- $result := merge $result $global_allResources_labels }}
  {{- range $key, $value := $result }}
    {{- $key | toYaml | trimSuffix "\n" | nindent 4 }}: {{ $value | trimSuffix "\n" | quote }}
  {{- end }}
{{- end -}}


{{- define "diam-gateway-hook-name-pre-install" -}}
{{- printf "%s-%s-%s" .Release.Name "oc-diam-gateway" "pre-install" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "diam-gateway-hook-name-post-install" -}}
{{- printf "%s-%s-%s" .Release.Name "oc-diam-gateway" "post-install" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "diam-gateway-hook-name-pre-upgrade" -}}
{{- printf "%s-%s-%s" .Release.Name "oc-diam-gateway" "pre-upgrade" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "diam-gateway-hook-name-post-upgrade" -}}
{{- printf "%s-%s-%s" .Release.Name "oc-diam-gateway" "post-upgrade" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "diam-gateway-hook-name-pre-rollback" -}}
{{- printf "%s-%s-%s" .Release.Name "oc-diam-gateway" "pre-rollback" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "diam-gateway-hook-name-post-rollback" -}}
{{- printf "%s-%s-%s" .Release.Name "oc-diam-gateway" "post-rollback" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "diam-gateway-hook-name-pre-delete" -}}
{{- printf "%s-%s-%s" .Release.Name "oc-diam-gateway" "pre-delete" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "diam-gateway-hook-name-post-delete" -}}
{{- printf "%s-%s-%s" .Release.Name "oc-diam-gateway" "post-delete" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "config-server-container" -}}
{{- printf "%s-%s-%s" .Release.Name .Values.global.configServerFullNameOverride "hook-container" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*--------------------------Ephemeral Storage-------------------------------------------------------------*/}}
{{- define "diam-gateway-ephemeral-storage-request" -}}
 {{- div (mul (add .Values.global.logStorage .Values.global.crictlStorage) 11) 10 -}}Mi
{{- end -}}


