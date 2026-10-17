{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "kube-rclone.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kube-rclone.fullname" -}}
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
{{- define "kube-rclone.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Selector labels. Includes the release so two installs never claim each other's pods.
*/}}
{{- define "kube-rclone.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kube-rclone.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "kube-rclone.labels" -}}
{{ include "kube-rclone.selectorLabels" . }}
helm.sh/chart: {{ include "kube-rclone.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Container image. Still honours the 0.1.x `images.container.*` values so old
values files keep working.
*/}}
{{- define "kube-rclone.image" -}}
{{- $repo := .Values.image.repository -}}
{{- $tag := default .Chart.AppVersion .Values.image.tag -}}
{{- $legacy := index .Values "images" | default dict -}}
{{- $container := index $legacy "container" | default dict -}}
{{- with index $container "repository" }}{{ $repo = . }}{{ end -}}
{{- with index $container "tag" }}{{ $tag = . }}{{ end -}}
{{- printf "%s:%s" $repo (toString $tag) -}}
{{- end -}}

{{- define "kube-rclone.pullPolicy" -}}
{{- $legacy := index .Values "images" | default dict -}}
{{- default .Values.image.pullPolicy (index $legacy "pullPolicy") -}}
{{- end -}}

{{/*
The rclone config, in priority order: rclone.config, then files/rclone.conf
(legacy). Empty when an existing Secret is used.
*/}}
{{- define "kube-rclone.configContent" -}}
{{- if .Values.rclone.config -}}
{{- .Values.rclone.config -}}
{{- else -}}
{{- .Files.Get "files/rclone.conf" -}}
{{- end -}}
{{- end -}}

{{/*
Name of the Secret holding rclone.conf.
*/}}
{{- define "kube-rclone.secretName" -}}
{{- if .Values.rclone.existingSecret -}}
{{- .Values.rclone.existingSecret -}}
{{- else -}}
{{- printf "%s-config" (include "kube-rclone.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "kube-rclone.secretKey" -}}
{{- if .Values.rclone.existingSecret -}}
{{- .Values.rclone.existingSecretKey -}}
{{- else -}}
rclone.conf
{{- end -}}
{{- end -}}

{{/*
Fail early with a clear message when there is no usable config, instead of
a pod that crash-loops on "didn't find section in config file".
*/}}
{{- define "kube-rclone.validate" -}}
{{- if not .Values.rclone.existingSecret -}}
{{- $config := include "kube-rclone.configContent" . -}}
{{- if not (regexMatch "(?m)^\\s*\\[[^\\]]+\\]" $config) -}}
{{- fail "kube-rclone: no rclone config found. Set rclone.existingSecret to a Secret you manage, or pass your config with --set-file rclone.config=./rclone.conf" -}}
{{- end -}}
{{- end -}}
{{- if not (contains ":" .Values.rclone.remote) -}}
{{- fail (printf "kube-rclone: rclone.remote %q must include a colon, e.g. \"gdrive:\" or \"gdrive:media\"" .Values.rclone.remote) -}}
{{- end -}}
{{- end -}}
