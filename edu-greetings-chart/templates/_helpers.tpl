{{/*
Named templates for the greetings chart.

Defined once here, used everywhere via `include`. If you find yourself writing
the same expression in two templates, it belongs in this file.
*/}}

{{- define "greetings.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Object names are derived from the RELEASE name, which is what lets the same
chart be installed twice in one namespace without collisions.
trunc 63 because Kubernetes names cap at 63 chars; trimSuffix "-" because a
trailing dash is an invalid name and trunc can leave one behind.
*/}}
{{- define "greetings.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "greetings.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end }}

{{- define "greetings.labels" -}}
app.kubernetes.io/name: {{ include "greetings.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end }}

{{/*
Selector labels are a SUBSET of the labels above, and must never include
version — a Deployment's selector is immutable, so putting a changing value in
here makes the chart un-upgradeable. This is the single most common way to
brick your own chart.
*/}}
{{- define "greetings.selectorLabels" -}}
app.kubernetes.io/name: {{ include "greetings.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
The database hostname. In module 5 this was a manual three-way contract between
the ConfigMap, the Service name and the backend's env var. Computed once here,
so there is one source of truth instead of three.
*/}}
{{- define "greetings.databaseHost" -}}
{{- if .Values.database.hostOverride -}}
{{- .Values.database.hostOverride -}}
{{- else -}}
{{- .Values.postgres.fullnameOverride | default (printf "%s-postgres" .Release.Name) -}}
{{- end -}}
{{- end }}

{{/*
Which Secret holds the DB password. Derived from .Release.Name, not from
fullname, because the postgres subchart must reach the same answer on its own
and .Release.Name is all they share. Its helper must stay in step with this one.
*/}}
{{- define "greetings.secretName" -}}
{{- .Values.database.existingSecret | default (printf "%s-db-credentials" .Release.Name) -}}
{{- end }}

{{- define "greetings.secretKey" -}}
{{- if .Values.database.existingSecret -}}
{{- .Values.database.existingSecretKey -}}
{{- else -}}
password
{{- end -}}
{{- end }}

{{/*
The image reference. Falls back to the chart's appVersion so `image.tag` can be
left empty and still be correct.
*/}}
{{- define "greetings.image" -}}
{{- printf "%s:%s" .Values.image.repository (.Values.image.tag | default .Chart.AppVersion) -}}
{{- end }}
