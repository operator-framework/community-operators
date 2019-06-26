{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "konfigurator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" | lower -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "konfigurator.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "konfigurator.labels.selector" -}}
app: {{ template "konfigurator.name" . }}
group: {{ .Values.konfigurator.labels.group }}
provider: {{ .Values.konfigurator.labels.provider }}
{{- end -}}

{{- define "konfigurator.labels.stakater" -}}
{{ template "konfigurator.labels.selector" . }}
version: {{ .Values.konfigurator.labels.version }}
{{- end -}}

{{- define "konfigurator.labels.chart" -}}
chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
release: {{ .Release.Name | quote }}
heritage: {{ .Release.Service | quote }}
{{- end -}}