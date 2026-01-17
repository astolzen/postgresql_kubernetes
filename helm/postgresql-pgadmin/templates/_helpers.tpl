{{/*
Expand the name of the chart.
*/}}
{{- define "postgresql-pgadmin.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "postgresql-pgadmin.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "postgresql-pgadmin.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "postgresql-pgadmin.labels" -}}
helm.sh/chart: {{ include "postgresql-pgadmin.chart" . }}
{{ include "postgresql-pgadmin.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "postgresql-pgadmin.selectorLabels" -}}
app.kubernetes.io/name: {{ include "postgresql-pgadmin.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "postgresql-pgadmin.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "postgresql-pgadmin.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
PostgreSQL secret name
*/}}
{{- define "postgresql-pgadmin.postgresql.secretName" -}}
{{- printf "%s-postgresql" (include "postgresql-pgadmin.fullname" .) }}
{{- end }}

{{/*
pgAdmin secret name
*/}}
{{- define "postgresql-pgadmin.pgadmin.secretName" -}}
{{- printf "%s-pgadmin" (include "postgresql-pgadmin.fullname" .) }}
{{- end }}

{{/*
PostgreSQL service name
*/}}
{{- define "postgresql-pgadmin.postgresql.serviceName" -}}
{{- printf "%s-postgresql" (include "postgresql-pgadmin.fullname" .) }}
{{- end }}

{{/*
pgAdmin service name
*/}}
{{- define "postgresql-pgadmin.pgadmin.serviceName" -}}
{{- printf "%s-pgadmin" (include "postgresql-pgadmin.fullname" .) }}
{{- end }}

{{/*
PVC name
*/}}
{{- define "postgresql-pgadmin.pvc.name" -}}
{{- printf "%s-pvc" (include "postgresql-pgadmin.fullname" .) }}
{{- end }}

{{/*
ConfigMap name
*/}}
{{- define "postgresql-pgadmin.configmap.name" -}}
{{- printf "%s-config" (include "postgresql-pgadmin.fullname" .) }}
{{- end }}

{{/*
Return the proper PostgreSQL image name
*/}}
{{- define "postgresql-pgadmin.postgresql.image" -}}
{{- $registry := .Values.postgresql.image.registry -}}
{{- $repository := .Values.postgresql.image.repository -}}
{{- $tag := .Values.postgresql.image.tag | toString -}}
{{- printf "%s/%s:%s" $registry $repository $tag -}}
{{- end }}

{{/*
Return the proper pgAdmin image name
*/}}
{{- define "postgresql-pgadmin.pgadmin.image" -}}
{{- $registry := .Values.pgadmin.image.registry -}}
{{- $repository := .Values.pgadmin.image.repository -}}
{{- $tag := .Values.pgadmin.image.tag | toString -}}
{{- printf "%s/%s:%s" $registry $repository $tag -}}
{{- end }}
