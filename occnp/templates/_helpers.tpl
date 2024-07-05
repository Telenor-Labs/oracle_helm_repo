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

{{/*--------------------Common Service Account Name---------------------------------------------------------------*/}}
{{- define "ocnf.serviceaccount" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}-serviceaccount
{{- end -}}

{{/*--------------------Common ROLE-------------------------------------------------------------------------------*/}}
{{- define "ocnf.role" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}-role
{{- end -}}

{{/*--------------------Common ROLE BINDING----------------------------------------------------------------------*/}}
{{- define "ocnf.rolebinding" -}}
{{ .Release.Name | trunc 63 | trimSuffix "-" -}}-rolebinding
{{- end -}}

{{/*--------------------Expand the name of the container.-------------------------------------------------------------*/}}
{{- define "container.fullname" -}}
{{- $prefix := default "" .Values.global.k8sResource.container.prefix | lower -}}
{{- $suffix := default "" .Values.global.k8sResource.container.suffix | lower -}}
{{- printf "%s-%s-%s" $prefix (include "chart.fullname" . ) $suffix | trunc 63 | trimPrefix "-"|trimSuffix "-" -}}
{{- end -}}

{{/*--------------------Engineering Labels common for all microservices--------------------------------------------*/}}
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

{{/*--------------------Engineering Annotations common for all microservices---------------------------------------*/}}
{{- define "engineering.annotations" -}}
{{- end -}}



{{/*##################################################################################################################
############################    CustomExtension LABELS section START       ###########################################*/}}

{{/*--------------------CustomExtension labels for lb services-----------------------------------------------------------*/}}
{{- define "custom.extensions.labels.lbServices" -}}
  {{- $global_allResources_labels := .Values.global.customExtension.allResources.labels -}}
  {{- $global_lbServices_labels := .Values.global.customExtension.lbServices.labels -}}
  {{- $service_specific_labels := .Values.service.customExtension.labels -}}
  {{- $result := dict }}
  {{- $result := merge $result $service_specific_labels }}
  {{- $result := merge $result $global_lbServices_labels }}
  {{- $result := merge $result $global_allResources_labels }}
  {{- range $key, $value := $result }}
    {{- $key | toYaml | trimSuffix "\n" | nindent 4 }}: {{ $value | trimSuffix "\n" | quote }}
  {{- end }}
{{- end -}}


{{/*--------------------CustomExtension labels for non lb services-----------------------------------------------------------*/}}
{{- define "custom.extensions.labels.nonlbServices" -}}
  {{- $global_allResources_labels := .Values.global.customExtension.allResources.labels -}}
  {{- $global_nonlbServices_labels := .Values.global.customExtension.nonlbServices.labels -}}
  {{- $service_specific_labels := .Values.service.customExtension.labels -}} 
  {{- $result := dict }}
  {{- $result := merge $result $service_specific_labels }}
  {{- $result := merge $result $global_nonlbServices_labels }}
  {{- $result := merge $result $global_allResources_labels }}
  {{- range $key, $value := $result }}
    {{- $key | toYaml | trimSuffix "\n" | nindent 4 }}: {{ $value | trimSuffix "\n" | quote }}
  {{- end }}
{{- end -}}

{{/*--------------------CustomExtension labels for lb deployments-----------------------------------------------------------*/}}
{{- define "custom.extensions.labels.lbDeployments" -}}
  {{- $global_allResources_labels := .Values.global.customExtension.allResources.labels -}}
  {{- $global_lbDeployment_labels := .Values.global.customExtension.lbDeployments.labels -}}
  {{- $deployment_specific_labels := .Values.deployment.customExtension.labels -}}
  {{- $result := dict }}
  {{- $result := merge $result $deployment_specific_labels }}
  {{- $result := merge $result $global_lbDeployment_labels }}
  {{- $result := merge $result $global_allResources_labels }}
  {{- range $key, $value := $result }}
    {{- $key | toYaml | trimSuffix "\n" | nindent 4 }}: {{ $value | trimSuffix "\n" | quote }}
  {{- end }}
{{- end -}}


{{/*--------------------CustomExtension labels for non lb deployments-----------------------------------------------------------*/}}
{{- define "custom.extensions.labels.nonlbDeployments" -}}
  {{- $global_allResources_labels := .Values.global.customExtension.allResources.labels -}}
  {{- $global_nonlbDeployment_labels := .Values.global.customExtension.nonlbDeployments.labels -}}
  {{- $deployment_specific_labels := .Values.deployment.customExtension.labels -}}
  {{- $result := dict }}
  {{- $result := merge $result $deployment_specific_labels }}
  {{- $result := merge $result $global_nonlbDeployment_labels }}
  {{- $result := merge $result $global_allResources_labels }}
  {{- range $key, $value := $result }}
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

{{/*##############################           CustomExtension LABELS section END    ################################################
###################################################################################################################################*/}}


{{/*###############################################################################################################################
############################    CustomExtension ANNOTATIONS section START        ##################################################*/}}

{{/*--------------------CustomExtension annotations for lb services-----------------------------------------------------------*/}}
{{- define "custom.extensions.annotations.lbServices" -}}
  {{- $global_allResources_annotations := .Values.global.customExtension.allResources.annotations -}}
  {{- $global_lbServices_annotations := .Values.global.customExtension.lbServices.annotations -}}
  {{- $service_specific_annotations := .Values.service.customExtension.annotations -}}
  {{- $result := dict }}
  {{- $result := merge $result $service_specific_annotations }} 
  {{- $result := merge $result $global_lbServices_annotations }}
  {{- $result := merge $result $global_allResources_annotations }}
  {{- range $key, $value := $result }}
    {{- $key | toYaml | trimSuffix "\n" | nindent 4 }}: {{ $value | trimSuffix "\n" | quote }}
  {{- end }}
{{- end -}}


{{/*--------------------CustomExtension annotations for non lb services-----------------------------------------------------------*/}}
{{- define "custom.extensions.annotations.nonlbServices" -}}
  {{- $global_allResources_annotations := .Values.global.customExtension.allResources.annotations -}}
  {{- $global_nonlbServices_annotations := .Values.global.customExtension.nonlbServices.annotations -}}
  {{- $service_specific_annotations := .Values.service.customExtension.annotations -}}
  {{- $result := dict }}
  {{- $result := merge $result $service_specific_annotations }}
  {{- $result := merge $result $global_nonlbServices_annotations }}
  {{- $result := merge $result $global_allResources_annotations }}
  {{- range $key, $value := $result }}
    {{- $key | toYaml | trimSuffix "\n" | nindent 4 }}: {{ $value | trimSuffix "\n" | quote }}
  {{- end }}
{{- end -}}

{{/*--------------------CustomExtension annotations for lb deployments-----------------------------------------------------------*/}}
{{- define "custom.extensions.annotations.lbDeployments" -}}
  {{- $global_allResources_annotations := .Values.global.customExtension.allResources.annotations -}}
  {{- $global_lbDeployment_annotations := .Values.global.customExtension.lbDeployments.annotations -}}
  {{- $deployment_specific_annotations := .Values.deployment.customExtension.annotations -}}
  {{- $result := dict }}
  {{- $result := merge $result $deployment_specific_annotations  }}
  {{- $result := merge $result $global_lbDeployment_annotations }}
  {{- $result := merge $result $global_allResources_annotations }}
  {{- range $key, $value := $result }}
    {{- $key | toYaml | trimSuffix "\n" | nindent 4 }}: {{ $value | trimSuffix "\n" | quote }}
  {{- end }}
{{- end -}}

{{/*--------------------CustomExtension annotations for non lb deployments-----------------------------------------------------------*/}}
{{- define "custom.extensions.annotations.nonlbDeployments" -}}
  {{- $global_allResources_annotations := .Values.global.customExtension.allResources.annotations -}}
  {{- $global_nonlbDeployment_annotations := .Values.global.customExtension.nonlbDeployments.annotations -}}
  {{- $deployment_specific_annotations := .Values.deployment.customExtension.annotations -}}
  {{- $result := dict }}
  {{- $result := merge $result $deployment_specific_annotations }}
  {{- $result := merge $result $global_nonlbDeployment_annotations }}
  {{- $result := merge $result $global_allResources_annotations }}
  {{- range $key, $value := $result }}
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

{{/*##############################           CustomExtension ANNOTATIONS section END       #############################################
########################################################################################################################################*/}}

{{/*###############################################################################################################################
##################################       Merged LABELS section START             ##################################################*/}}

{{/*-----------Labels for Lb Services-----------------*/}}
{{- define "labels.lbServices" -}}
{{- include "custom.extensions.labels.lbServices" . }}
{{- include "engineering.labels" . | nindent 4 }}
{{- end -}}

{{/*-----------Labels for NonLb Services-----------------*/}}
{{- define "labels.nonlbServices" -}}
{{- include "custom.extensions.labels.nonlbServices" . }}
{{- include "engineering.labels" . | nindent 4 }}
{{- end -}}

{{/*-----------Labels for Lb Deployments-----------------*/}}
{{- define "labels.lbDeployments" -}}
{{- include "custom.extensions.labels.lbDeployments" . }}
{{- include "engineering.labels" . | nindent 4 }}
{{- end -}}

{{/*-----------Labels for nonlb Deployments-----------------*/}}
{{- define "labels.nonlbDeployments" -}}
{{- include "custom.extensions.labels.nonlbDeployments" . }}
{{- include "engineering.labels" . | nindent 4 }}
{{- end -}}

{{/*-----------Labels for All kubernetes resources-----------------*/}}
{{- define "labels.allResources" -}}
{{- include "custom.extensions.labels.allResources" . }}
{{- include "engineering.labels" . | nindent 4 }}
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
{{/*##############################    Merged LABELS section END            #############################################################
########################################################################################################################################*/}}

{{/*###############################################################################################################################
##################################       Merged ANNOTATIONS section START        ##################################################*/}}
{{/*-----------Annotations for Lb Services-----------------*/}}
{{- define "annotations.lbServices" -}}
{{- include "custom.extensions.annotations.lbServices" . }}
{{- include "engineering.annotations" . | nindent 4 }}
{{- end -}}

{{/*-----------Annotations for NonLb Services-----------------*/}}
{{- define "annotations.nonlbServices" -}}
{{- include "custom.extensions.annotations.nonlbServices" . }}
{{- include "engineering.annotations" . | nindent 4 }}
{{- end -}}


{{/*-----------Annotations for Lb Deployments-----------------*/}}
{{- define "annotations.lbDeployments" -}}
{{- include "custom.extensions.annotations.lbDeployments" . }}
{{- include "engineering.annotations" . | nindent 4 }}
{{- end -}}

{{/*-----------Annotations for nonLb Deployments-----------------*/}}
{{- define "annotations.nonlbDeployments" -}}
{{- include "custom.extensions.annotations.nonlbDeployments" . }}
{{- include "engineering.annotations" . | nindent 4 }}
{{- end -}}

{{/*-----------Annotations for All kubernetes resources-----------------*/}}
{{- define "annotations.allResources" -}}
{{- include "custom.extensions.annotations.allResources" . }}
{{- include "engineering.annotations" . | nindent 4 }}
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

{{/*##############################   Merged ANNOTATIONS section END       #############################################################
########################################################################################################################################*/}}


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



{{- define "service-prefix" -}}
{{- if .Values.global.nfName -}}
{{- printf "%s-%s" .Release.Name .Values.global.nfName | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*----------- Service names -----------------*/}}

{{- define "service-name-binding" -}}
{{- printf "%s-%s" (include "service-prefix" .) "binding" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-perf-info" -}}
{{- printf "%s-%s" (include "service-prefix" .) "perf-info" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-pcf-ue" -}}
{{- printf "%s-%s" (include "service-prefix" .) "pcf-ue" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-query" -}}
{{- printf "%s-%s" (include "service-prefix" .) "query" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-pcf-sm" -}}
{{- printf "%s-%s" (include "service-prefix" .) "pcf-sm" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-ldap-gateway" -}}
{{- printf "%s-%s" (include "service-prefix" .) "ldap-gateway" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-policy-ds" -}}
{{- printf "%s-%s" (include "service-prefix" .) "policy-ds" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-nrf-client-nfdiscovery" -}}
{{- printf "%s-%s" (include "service-prefix" .) "nrf-client-nfdiscovery" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-nrf-client-nfmanagement" -}}
{{- printf "%s-%s" (include "service-prefix" .) "nrf-client-nfmanagement" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-pcf-am" -}}
{{- printf "%s-%s" (include "service-prefix" .) "pcf-am" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-app-info" -}}
{{- printf "%s-%s" (include "service-prefix" .) "app-info" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-soap-connector" -}}
{{- printf "%s-%s" (include "service-prefix" .) "soap-connector" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-oc-diam-gateway" -}}
{{- printf "%s-%s" (include "service-prefix" .) "oc-diam-gateway" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-oc-diam-gateway-headless" -}}
{{- printf "%s-%s" (include "service-prefix" .) "oc-diam-gateway-headless" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-oc-diam-gateway-coherence-headless" -}}
{{- printf "%s-%s" (include "service-prefix" .) "oc-diam-gateway-coherence-headless" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-bulwark" -}}
{{- printf "%s-%s" (include "service-prefix" .) "bulwark" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-bulwark-service-coherence-headless" -}}
{{- printf "%s-%s" (include "service-prefix" .) "bulwark-coherence-headless" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-diam-connector" -}}
{{- printf "%s-%s" (include "service-prefix" .) "oc-diam-connector" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-diameter-connector" -}}
{{- printf "%s-%s" (include "service-prefix" .) "diameter-connector" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-audit" -}}
{{- printf "%s-%s" (include "service-prefix" .) "audit" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-pcf-user" -}}
{{- printf "%s-%s" (include "service-prefix" .) "pcf-user" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-udr-connector" -}}
{{- printf "%s-%s" (include "service-prefix" .) "udr-connector" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-chf-connector" -}}
{{- printf "%s-%s" (include "service-prefix" .) "chf-connector" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-pcrf-core-headless" -}}
{{- printf "%s-%s" (include "service-prefix" .) "pcrf-core-headless" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-pcrf-core" -}}
{{- printf "%s-%s" (include "service-prefix" .) "pcrf-core" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-config-mgmt" -}}
{{- printf "%s-%s" (include "service-prefix" .) "config-mgmt" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-config-server" -}}
{{- printf "%s-%s" (include "service-prefix" .) "config-server" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-pre" -}}
{{- printf "%s-%s" (include "service-prefix" .) "pre" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-pre-test" -}}
{{- printf "%s-%s" (include "service-prefix" .) "pre-test" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-egress-gateway" -}}
{{- printf "%s-%s" (include "service-prefix" .) "egress-gateway" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-ingress-gateway" -}}
{{- printf "%s-%s" (include "service-prefix" .) "ingress-gateway" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-bsf-management" -}}
{{- printf "%s-%s" (include "service-prefix" .) "bsf-management" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service-name-alternate-route" -}}
{{- printf "%s-%s" (include "service-prefix" .) "alternate-route" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*----------- DB URI Scheme -----------------*/}}
{{- define "db-uri-scheme" -}}
{{- if and (.Values.global.envMysqlLoadBalancingEnabled) (.Values.global.envMysqlDnsSrvEnabled) -}}
jdbc:mysql+srv:loadbalance
{{- else if .Values.global.envMysqlLoadBalancingEnabled -}}
jdbc:mysql:loadbalance
{{- else if .Values.global.envMysqlDnsSrvEnabled -}}
jdbc:mysql+srv
{{- else -}}
jdbc:mysql
{{- end -}}
{{- end -}}

{{/*----------- DB Host and port-----------------*/}}
{{- define "db-host-and-port" -}}
{{- if .Values.global.envMysqlLoadBalancingEnabled -}}
{{- .Values.global.envMysqlLoadBalanceHosts | trimSuffix "-" -}}
{{- else if .Values.global.envMysqlDnsSrvEnabled -}}
{{- .Values.global.envMysqlHost | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s:%s" .Values.global.envMysqlHost .Values.global.envMysqlPort | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*----------- DB URL - loadBalance Configuration-----------------*/}}
{{- define "db-url-load-balance-config" -}}
{{- if .Values.global.envMysqlLoadBalancingEnabled -}}
{{- printf "%s%s" "&loadBalanceBlacklistTimeout=" .Values.global.mySql.loadBalance.serverBlocklistTimeout -}}
{{- end -}}
{{- end -}}
