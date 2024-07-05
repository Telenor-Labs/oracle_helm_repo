{{/*Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "perf-info.fullname" -}}
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

{{- define "perf-info-deployment-name" -}}
{{- printf "%s-%s" .Release.Name "performance" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*--------------------Service Account Name---------------------------------------------------------------*/}}
{{- define "ocnf.service-account-name" -}}
{{- if .Values.global.serviceAccountName -}}
{{- .Values.global.serviceAccountName | trimSuffix "-" -}}
{{- else -}}
{{- include "perf-info-deployment-name" . }}
{{- end -}}
{{- end -}}

{{- define "globalSeviceAccountEnabled" -}}
{{- if .Values.global.serviceAccountName -}}
{{- printf "true" }}
{{- else -}}
{{- printf "false" }}
{{- end -}}
{{- end -}}


{{- define "perf-info.createServiceAccount" -}}
{{- if and ( $.Values.global.performanceServiceEnable) (eq (include "globalSeviceAccountEnabled" .) "false") -}}
{{- printf "true" }}
{{- else -}}
{{- printf "false" }}
{{- end -}}
{{- end -}}



{{- define "service-name-perf-info" -}}
{{- printf "%s-%s" (include "service-prefix" .) "perf-info" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

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

{{- define "factory.labels" -}}
  {{- range $key, $value := $.Values.global.customExtension.factoryLabelTemplates }}
    {{- $key | toYaml | trimSuffix "\n" | nindent 4 }}: {{ tpl $value $ }}
  {{- end }}
{{- end -}}

{{- define "factory.annotations" -}}
  {{- range $key, $value := $.Values.global.customExtension.factoryAnnotationsTemplates }}
    {{- $key | toYaml | trimSuffix "\n" | nindent 4 }}: {{ tpl $value $ }}
  {{- end }}
{{- end -}}

{{/*--------------------Expand the name of the chart.-------------------------------------------------------------*/}}
{{- define "chart.fullname" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*--------------------Expand the name of the container.-------------------------------------------------------------*/}}
{{- define "container.fullname" -}}
{{- $prefix := default "" .Values.global.k8sResource.container.prefix | lower -}}
{{- $suffix := default "" .Values.global.k8sResource.container.suffix | lower -}}
{{- printf "%s-%s-%s" $prefix (include "chart.fullname" . ) $suffix | trunc 63 | trimPrefix "-"|trimSuffix "-" -}}
{{- end -}}

{{/*--------------------------------------Debug Tool Container---------------------------------------------------*/}}
{{- define "extraContainers" -}} 
  {{- if (eq .Values.extraContainers "ENABLED") -}} 
    {{- tpl (default .Values.global.extraContainersTpl .Values.extraContainersTpl) . }}
  {{- else if (eq .Values.extraContainers "USE_GLOBAL_VALUE") -}} 
    {{- if (eq .Values.global.extraContainers "ENABLED") -}} 
      {{- tpl (default .Values.global.extraContainersTpl .Values.extraContainersTpl) . }}
    {{- end -}} 
  {{- end -}} 
{{- end -}} 

{{/*--------------------Engineering Labels common for all microservices--------------------------------------------*/}}
{{- define "engineering.labels" -}}
{{- end -}}

{{/*--------------------Engineering Annotations common for all microservices---------------------------------------*/}}
{{- define "engineering.annotations" -}}
{{- end -}}

{{/*--------------------perfinfo.hook.chartVersion--------------------------------------------*/}}
{{- define "perfinfo.hook.chartVersion" -}}
{{- .Chart.Version | trunc 9 | trimSuffix "-" -}}
{{- end -}}

{{/*-----------Annotations for All kubernetes resources-----------------*/}}
{{- define "annotations.allResources" -}}
{{- include "custom.extensions.annotations.allResources" . }}
{{- include "engineering.annotations" . | nindent 4 }}
{{- end -}}

{{/*--------------------CustomExtension annotations for all kubernetes resources-----------------------------------------------------------*/}}
{{- define "custom.extensions.annotations.allResources" -}}
  {{- $global_allResources_annotations := .Values.global.customExtension.allResources.annotations -}}
  {{- range $key, $value := $global_allResources_annotations }}
    {{- $key | toYaml | trimSuffix "\n" | nindent 4 }}: {{ $value | trimSuffix "\n" | quote }}
  {{- end }}
{{- end -}}

{{/*--------------------CustomExtension labels for all kubernetes resources-----------------------------------------------------------*/}}
{{- define "custom.extensions.labels.allResources" -}}
  {{- $global_allResources_labels := .Values.global.customExtension.allResources.labels -}}
  {{- range $key, $value := $global_allResources_labels }}
    {{- $key | toYaml | trimSuffix "\n" | nindent 4 }}: {{ $value | trimSuffix "\n" | quote }}
  {{- end }}
{{- end -}}

{{/*-----------Labels for All kubernetes resources-----------------*/}}
{{- define "labels.allResources" -}}
{{- include "custom.extensions.labels.allResources" . }}
{{- include "engineering.labels" . | nindent 4 }}
{{- end -}}

{{/*--------------------Service Name Of IGW------------------------------------------------------------*/}}
{{- define "service.OverloadIngressGatewaySvcFullname" -}}
{{- if .Values.overloadManager.ingressGatewaySvcName -}}
{{- $name := .Values.overloadManager.ingressGatewaySvcName -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- else -}}
{{- .Values.overloadManager.ingressGatewayHost | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}


{{/*--------------------Common Config server Service Name------------------------------------------------------------*/}}
{{- define "perfinfo.service.ConfigServerSvcFullname" -}}
{{- if .Values.commonCfgServer.configServerSvcName -}}
{{- $name := .Values.commonCfgServer.configServerSvcName -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- else -}}
{{- .Values.commonCfgServer.host | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*-------------------- Persistent configuration --------------------------------------------------------------------*/}}
{{- define "perfinfo.defaultconfig.overloadLevelThreshold" -}}
overloadLevelThreshold: []
{{- end -}}

{{- define "perfinfo.defaultconfig.labels" -}}
logging:
  appLogLevel: {{ .Values.log.level.perfinfo }}
{{ include "perfinfo.defaultconfig.overloadLevelThreshold" . -}}
{{- end -}}

{{/*-------------------- Job Name for Pre-Install .--------------------------------*/}}
{{- define "pre-install-perfinfo-job.fullname" -}}
{{- printf "%s-%s" (include "service-name-perf-info" .) "pre-install" | trunc 63 | trimPrefix "-"|trimSuffix "-" -}}
{{- end -}}

{{/*--------------------Expand the name of the pre-install container.--------------------------------*/}}
{{- define "pre-install-perfinfo-job.container.fullname" -}}
{{- $prefix := default "" .Values.global.k8sResource.container.prefix | lower -}}
{{- $suffix := default "" .Values.global.k8sResource.container.suffix | lower -}}
{{- printf "%s-%s-%s-%s" $prefix (include "service-name-perf-info" .) "pre-install" $suffix | trunc 63 | trimPrefix "-"|trimSuffix "-" -}}
{{- end -}}

{{/*-------------------- Job Name for Pre-Upgrade .--------------------------------*/}}
{{- define "pre-upgrade-perfinfo-job.fullname" -}}
{{- printf "%s-%s" (include "service-name-perf-info" .) "pre-upgrade" | trunc 63 | trimPrefix "-"|trimSuffix "-" -}}
{{- end -}}

{{/*--------------------Expand the name of the pre-upgrade container.--------------------------------*/}}
{{- define "pre-upgrade-perfinfo-job.container.fullname" -}}
{{- $prefix := default "" .Values.global.k8sResource.container.prefix | lower -}}
{{- $suffix := default "" .Values.global.k8sResource.container.suffix | lower -}}
{{- printf "%s-%s-%s-%s" $prefix (include "service-name-perf-info" .) "pre-upgrade" $suffix | trunc 63 | trimPrefix "-"|trimSuffix "-" -}}
{{- end -}}

{{/*-------------------- Job Name for Pre-Rollback .--------------------------------*/}}
{{- define "pre-rollback-perfinfo-job.fullname" -}}
{{- printf "%s-%s" (include "service-name-perf-info" .) "pre-rollback" | trunc 63 | trimPrefix "-"|trimSuffix "-" -}}
{{- end -}}

{{/*--------------------Expand the name of the pre-rollback container.--------------------------------*/}}
{{- define "pre-rollback-perfinfo-job.container.fullname" -}}
{{- $prefix := default "" .Values.global.k8sResource.container.prefix | lower -}}
{{- $suffix := default "" .Values.global.k8sResource.container.suffix | lower -}}
{{- printf "%s-%s-%s-%s" $prefix (include "service-name-perf-info" .) "pre-rollback" $suffix | trunc 63 | trimPrefix "-"|trimSuffix "-" -}}
{{- end -}}

{{/*-------------------- Job Name for Pre-Delete .--------------------------------*/}}
{{- define "pre-delete-perfinfo-job.fullname" -}}
{{- printf "%s-%s" (include "service-name-perf-info" .) "pre-delete" | trunc 63 | trimPrefix "-"|trimSuffix "-" -}}
{{- end -}}

{{/*--------------------Expand the name of the pre-delete container.--------------------------------*/}}
{{- define "pre-delete-perfinfo-job.container.fullname" -}}
{{- $prefix := default "" .Values.global.k8sResource.container.prefix | lower -}}
{{- $suffix := default "" .Values.global.k8sResource.container.suffix | lower -}}
{{- printf "%s-%s-%s-%s" $prefix (include "service-name-perf-info" .) "pre-delete" $suffix | trunc 63 | trimPrefix "-"|trimSuffix "-" -}}
{{- end -}}
 
{{/*-------------------- Job Name for Post-Upgrade .--------------------------------*/}}
{{- define "post-upgrade-perfinfo-job.fullname" -}}
{{- printf "%s-%s" (include "service-name-perf-info" .) "post-upgrade" | trunc 63 | trimPrefix "-"|trimSuffix "-" -}}
{{- end -}}

{{/*--------------------Expand the name of the post-upgrade container.--------------------------------*/}}
{{- define "post-upgrade-perfinfo-job.container.fullname" -}}
{{- $prefix := default "" .Values.global.k8sResource.container.prefix | lower -}}
{{- $suffix := default "" .Values.global.k8sResource.container.suffix | lower -}}
{{- printf "%s-%s-%s-%s" $prefix (include "service-name-perf-info" .) "post-upgrade" $suffix | trunc 63 | trimPrefix "-"|trimSuffix "-" -}}
{{- end -}}

{{/*-------------------- Job Name for Post-Rollback .--------------------------------*/}}
{{- define "post-rollback-perfinfo-job.fullname" -}}
{{- printf "%s-%s" (include "service-name-perf-info" .) "post-rollback" | trunc 63 | trimPrefix "-"|trimSuffix "-" -}}
{{- end -}}

{{/*--------------------Expand the name of the post-rollback container.--------------------------------*/}}
{{- define "post-rollback-perfinfo-job.container.fullname" -}}
{{- $prefix := default "" .Values.global.k8sResource.container.prefix | lower -}}
{{- $suffix := default "" .Values.global.k8sResource.container.suffix | lower -}}
{{- printf "%s-%s-%s-%s" $prefix (include "service-name-perf-info" .) "post-rollback" $suffix | trunc 63 | trimPrefix "-"|trimSuffix "-" -}}
{{- end -}}

{{/*--------------------Common Tolerations----------------------------------------------------------------------*/}}
{{- define "ocnf.tolerations" }}
 {{- $localTolerationsSetting := .Values.tolerationsSetting | default "USE_GLOBAL_VALUE" }}
 {{- $globalTolerationsSetting := .Values.global.tolerationsSetting | default "DISABLED" }}
 {{- $tolerations := "" }}

 {{- if (eq $localTolerationsSetting "ENABLED") }}
   {{- $tolerations =  .Values.tolerations }}
 {{- else if (eq $localTolerationsSetting "USE_GLOBAL_VALUE") }}
   {{- if (eq $globalTolerationsSetting "ENABLED")}}
     {{- $tolerations = .Values.global.tolerations }}
   {{- end }}
 {{- end }}

 {{- if $tolerations }}
{{- toYaml $tolerations }}
 {{- end }}
{{- end }}
{{/*--------------------Common NodeSelector----------------------------------------------------------------------*/}}
{{- define "ocnf.nodeselector" }}
 {{- $localNodeSelection := .Values.nodeSelection | default "USE_GLOBAL_VALUE" }}
 {{- $globalNodeSelection := .Values.global.nodeSelection | default "DISABLED" }}
 {{- $nodeselector := "" }}

 {{- if (eq $localNodeSelection "ENABLED") }}
   {{- $nodeselector =  .Values.nodeSelector }}
 {{- else if (eq $localNodeSelection "USE_GLOBAL_VALUE") }}
   {{- if (eq $globalNodeSelection "ENABLED")}}
     {{- $nodeselector = .Values.global.nodeSelector }}
   {{- end }}
 {{- end }}

 {{- if $nodeselector }}
{{- toYaml $nodeselector }}
 {{- end }}
{{- end }}
{{/*##################################################################################################################
####################################################################################################################*/}}

{{/*--------------------------Ephemeral Storage-------------------------------------------------------------*/}}
{{- define "perf-info-ephemeral-storage-request" -}}
 {{- div (mul (add .Values.global.logStorage .Values.global.crictlStorage) 11) 10 -}}Mi
{{- end -}}

