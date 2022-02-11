{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "application-library.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "application-library.fullname" -}}
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
{{- define "application-library.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "application-library.labels" -}}
app.kubernetes.io/name: {{ include "application-library.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}  
app.kubernetes.io/version: {{ default "latest" .Values.image.tag }}  
app.kubernetes.io/component: {{ .Values.component }}  
app.kubernetes.io/part-of: {{ .Values.sistema }}  
app.kubernetes.io/managed-by: {{ .Release.Service }}  
helm.sh/chart: {{ include "application-library.chart" . }}
{{- if .Values.extraLabels }}
{{ toYaml .Values.extraLabels }}
{{- end }}
{{- end -}}

{{/*
Selector Match labels
*/}}
{{- define "application-library.selectorLabels" -}}
app.kubernetes.io/name: {{ include "application-library.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }} 
{{- end -}}

{{/*
Allow the release namespace to be overridden for multi-namespace deployments in combined charts
*/}}
{{- define "application-library.namespace" -}}
  {{- if .Values.namespaceOverride -}}
    {{- .Values.namespaceOverride -}}
  {{- else -}}
    {{- .Release.Namespace -}}
  {{- end -}}
{{- end -}}


