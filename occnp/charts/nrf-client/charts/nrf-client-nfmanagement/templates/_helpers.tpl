{{/*--------------------Horizontal Pod Autoscalar Name------------------------------------------------------------*/}}
{{- define "hpautoscalar.fullname" -}}
{{ .Release.Name | trunc 63 | trimSuffix "-" -}}-{{- .Chart.Name }}
{{- end -}}

{{/*--------------------Deployment Name---------------------------------------------------------------------------*/}}
{{- define "deployment.fullname" -}}
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

{{/*--------------------Expand the name of the chart.-------------------------------------------------------------*/}}
{{- define "chart.fullname" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*--------------------Create chart name and version as used by the chart label.---------------------------------*/}}
{{- define "chart.fullnameandversion" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*--------------------Expand the name of the container.-------------------------------------------------------------*/}}
{{- define "container.fullname" -}}
{{- $prefix := default "" .Values.global.k8sResource.container.prefix | lower -}}
{{- $suffix := default "" .Values.global.k8sResource.container.suffix | lower -}}
{{- printf "%s-%s-%s" $prefix (include "chart.fullname" . ) $suffix | trunc 63 | trimPrefix "-"|trimSuffix "-" -}}
{{- end -}}

{{/*--------------------Engineering Labels common for all microservices--------------------------------------------*/}}
{{- define "engineering.labels" -}}
application: {{ .Values.global.applicationName }}
microservice: {{ printf "%s-%s" (include "service-prefix" . ) .Chart.Name }}
engVersion: {{.Chart.Version}}
mktgVersion: {{.Chart.AppVersion}}
vendor: {{ .Values.global.vendor }}
{{- end -}}

{{/*--------------------Engineering Annotations common for all microservices---------------------------------------*/}}
{{- define "engineering.annotations" -}}
{{- end -}}

{{- define "factory.labels" -}}
  {{- range $key, $value := $.Values.global.customExtension.factoryLabelTemplates }}
    {{- $key | toYaml | trimSuffix "\n" | nindent 4 }}: {{ tpl $value $ }}
  {{- end }}
{{- end -}}

{{- define "factory.annotations" -}}
  {{- range $key, $value := $.Values.global.customExtension.factoryAnnotationTemplates }}
    {{- $key | toYaml | trimSuffix "\n" | nindent 4 }}: {{ tpl $value $ }}
  {{- end }}
{{- end -}}

{{- define "labels.services" -}}
  {{- $global_allResources_labels := .Values.global.customExtension.allResources.labels -}}
  {{- $global_services_labels := .Values.global.customExtension.nonlbServices.labels -}}
  {{- if .Values.useLbLabelsAndAnnotations -}} 
     {{- $global_services_labels := .Values.global.customExtension.lbServices.labels -}}
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
    {{- $global_deployment_labels := .Values.global.customExtension.lbDeployments.labels }}
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

{{- define "annotations.services" -}}
  {{- $global_allResources_annotations := .Values.global.customExtension.allResources.annotations -}}
  {{- $global_services_annotations := .Values.global.customExtension.nonlbServices.annotations -}}
  {{- if .Values.useLbLabelsAndAnnotations }} 
    {{- $global_services_annotations := .Values.global.customExtension.lbServices.annotations -}}
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
    {{- $global_deployment_annotations := .Values.global.customExtension.lbDeployments.annotations -}}
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

{{/*-------------------- Persistent configuration --------------------------------------------------------------------*/}}
{{- define "defaultNrfClientMgmtConfig.labels" -}}
logging:
  appLogLevel: {{ .Values.logging.level.nrfclient }}
  packageLogLevel:
  - packageName: root
    logLevelForPackage: {{ .Values.logging.level.root }}
{{- if eq .Values.nfProfileConfigMode "REST" }}
nfProfileList: {{ printf "%s" (include "getConfigValue" (list . "appProfiles")) }}
{{- end }}
generalOptions:
  nfProfileUpdateMode: {{ .Values.generalOptions.nfProfileUpdateMode }}
  triggerNfRegistration: {{ .Values.generalOptions.triggerNfRegistration }}
{{- if eq .Values.nrfRouteConfigMode "REST" }}
{{- if eq (include "getConfigValue" (list . "useNrfRouteList")) "true" }}
nrfRouteList: {{ printf "%s" (include "getConfigValue" (list . "nrfRouteList")) }}
{{- else }}
nrfRouteList:
 - scheme: {{ printf "%s" (include "getConfigValue" (list . "nrfScheme")) }}
   nrfApi: {{ printf "%s" (include "getConfigValue" (list . "primaryNrfApiRoot")) }}
   priority: 1
   weight: 100
 {{- if printf "%s" (include "getConfigValue" (list . "secondaryNrfApiRoot")) }}
 - scheme: {{ printf "%s" (include "getConfigValue" (list . "nrfScheme")) }}
   nrfApi: {{ printf "%s" (include "getConfigValue" (list . "secondaryNrfApiRoot")) }}
   priority: 2
   weight: 100
 {{- end -}}
 {{- end }}
 {{- end }}
{{- end -}}

{{/*-------------------- Job Name for Pre-Install .--------------------------------*/}}
{{- define "pre-install-job.fullname" -}}
{{- printf "%s-%s" (include "service.fullname" .) "pre-install" | trunc 63 | trimPrefix "-"|trimSuffix "-" -}}
{{- end -}}

{{/*--------------------Expand the name of the pre-install container.--------------------------------*/}}
{{- define "pre-install-job.container.fullname" -}}
{{- $prefix := default "" .Values.global.k8sResource.container.prefix | lower -}}
{{- $suffix := default "" .Values.global.k8sResource.container.suffix | lower -}}
{{- printf "%s-%s-%s-%s" $prefix (include "service.fullname" .) "pre-install" $suffix | trunc 63 | trimPrefix "-"|trimSuffix "-" -}}
{{- end -}}

{{/*-------------------- Job Name for Pre-Upgrade .--------------------------------*/}}
{{- define "pre-upgrade-job.fullname" -}}
{{- printf "%s-%s" (include "service.fullname" .) "pre-upgrade" | trunc 63 | trimPrefix "-"|trimSuffix "-" -}}
{{- end -}}

{{/*--------------------Expand the name of the pre-upgrade container.--------------------------------*/}}
{{- define "pre-upgrade-job.container.fullname" -}}
{{- $prefix := default "" .Values.global.k8sResource.container.prefix | lower -}}
{{- $suffix := default "" .Values.global.k8sResource.container.suffix | lower -}}
{{- printf "%s-%s-%s-%s" $prefix (include "service.fullname" .) "pre-upgrade" $suffix | trunc 63 | trimPrefix "-"|trimSuffix "-" -}}
{{- end -}}

{{/*-------------------- Job Name for Pre-Rollback .--------------------------------*/}}
{{- define "pre-rollback-job.fullname" -}}
{{- printf "%s-%s" (include "service.fullname" .) "pre-rollback" | trunc 63 | trimPrefix "-"|trimSuffix "-" -}}
{{- end -}}

{{/*--------------------Expand the name of the pre-rollback container.--------------------------------*/}}
{{- define "pre-rollback-job.container.fullname" -}}
{{- $prefix := default "" .Values.global.k8sResource.container.prefix | lower -}}
{{- $suffix := default "" .Values.global.k8sResource.container.suffix | lower -}}
{{- printf "%s-%s-%s-%s" $prefix (include "service.fullname" .) "pre-rollback" $suffix | trunc 63 | trimPrefix "-"|trimSuffix "-" -}}
{{- end -}}

{{/*-------------------- Job Name for Pre-Delete .--------------------------------*/}}
{{- define "pre-delete-job.fullname" -}}
{{- printf "%s-%s" (include "service.fullname" .) "pre-delete" | trunc 63 | trimPrefix "-"|trimSuffix "-" -}}
{{- end -}}

{{/*--------------------Expand the name of the pre-delete container.--------------------------------*/}}
{{- define "pre-delete-job.container.fullname" -}}
{{- $prefix := default "" .Values.global.k8sResource.container.prefix | lower -}}
{{- $suffix := default "" .Values.global.k8sResource.container.suffix | lower -}}
{{- printf "%s-%s-%s-%s" $prefix (include "service.fullname" .) "pre-delete" $suffix | trunc 63 | trimPrefix "-"|trimSuffix "-" -}}
{{- end -}}

{{/*-------------------- Job Name for Post-Upgrade .--------------------------------*/}}
{{- define "post-upgrade-job.fullname" -}}
{{- printf "%s-%s" (include "service.fullname" .) "post-upgrade" | trunc 63 | trimPrefix "-"|trimSuffix "-" -}}
{{- end -}}

{{/*--------------------Expand the name of the post-upgrade container.--------------------------------*/}}
{{- define "post-upgrade-job.container.fullname" -}}
{{- $prefix := default "" .Values.global.k8sResource.container.prefix | lower -}}
{{- $suffix := default "" .Values.global.k8sResource.container.suffix | lower -}}
{{- printf "%s-%s-%s-%s" $prefix (include "service.fullname" .) "post-upgrade" $suffix | trunc 63 | trimPrefix "-"|trimSuffix "-" -}}
{{- end -}}

{{/*-------------------- Job Name for Post-Rollback .--------------------------------*/}}
{{- define "post-rollback-job.fullname" -}}
{{- printf "%s-%s" (include "service.fullname" .) "post-rollbck" | trunc 63 | trimPrefix "-"|trimSuffix "-" -}}
{{- end -}}

{{/*--------------------Expand the name of the post-rollback container.--------------------------------*/}}
{{- define "post-rollback-job.container.fullname" -}}
{{- $prefix := default "" .Values.global.k8sResource.container.prefix | lower -}}
{{- $suffix := default "" .Values.global.k8sResource.container.suffix | lower -}}
{{- printf "%s-%s-%s-%s" $prefix (include "service.fullname" .) "post-rollback" $suffix | trunc 63 | trimPrefix "-"|trimSuffix "-" -}}
{{- end -}}

{{/*--------------------Common Config server Service Name------------------------------------------------------------*/}}
{{- define "service.ConfigServerSvcFullname" -}}
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

{{/*--------------------Alternate Service Route Host------------------------------------------------------------*/}}
{{- define "service-name-alternate-route" -}}
{{- if .Values.global.alternateRouteServiceHost -}}
{{- .Values.global.alternateRouteServiceHost -}}
{{- else -}}
{{- printf "%s" (include "service-name-alternate-route" .) -}}
{{- end -}}
{{- end -}}

{{/*--------------------Egress Gateway Host-----------------------------------------------------*/}}
{{- define "egress-gateway-host" -}}
{{- if .Values.global.egressGatewayHost -}}
{{ .Values.global.egressGatewayHost -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name .Values.global.deploymentNrfClientService.envEgressGatewayFullnameOverride -}}
{{- end -}}
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

{{/*--------------------------Ephemeral Storage Request-------------------------------------------*/}}
{{- define "nrf-client-nfmanagement-ephemeral-storage-request" -}}
{{- if ne (add .Values.global.logStorage .Values.global.crictlStorage)  0 }}
  {{- $result := dict "ephemeral-storage" (printf "%s%s" (toString (div (mul (add .Values.global.logStorage .Values.global.crictlStorage) 11) 10)) "Mi") }}
  {{- range $key, $value := $result }}
    {{- $key | toYaml | trimSuffix "\n" }}: {{ $value | trimSuffix "\n" | quote }}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*--------------------------Ephemeral Storage Limit------------------------------------------*/}}
{{- define "nrf-client-nfmanagement-ephemeral-storage-limit" -}}
{{- if ne (int .Values.global.ephemeralStorageLimit)  0 }}
  {{- $result := dict "ephemeral-storage" (printf "%s%s" (toString .Values.global.ephemeralStorageLimit) "Mi") }}
  {{- range $key, $value := $result }}
    {{- $key | toYaml | trimSuffix "\n" }}: {{ $value | trimSuffix "\n" | quote }}
  {{- end -}}
{{- end -}}
{{- end -}}

