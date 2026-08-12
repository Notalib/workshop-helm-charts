{{- define "postgres.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
The parent sets fullnameOverride: database, so every object here is named
"database" — the same Service name you created by hand in workshop #2 module 5,
which is what makes the backend's POSTGRES_HOST work unchanged.
*/}}
{{- define "postgres.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "postgres.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end }}

{{- define "postgres.labels" -}}
app.kubernetes.io/name: {{ include "postgres.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: database
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "postgres.selectorLabels" -}}
app.kubernetes.io/name: {{ include "postgres.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: database
{{- end }}

{{/*
MUST match greetings.secretName in the parent chart. Both derive the name from
.Release.Name, the only value parent and subchart are guaranteed to share.
Change one and you must change the other — the coupling is real, and naming it
here is better than pretending it isn't.
*/}}
{{- define "postgres.secretName" -}}
{{- .Values.auth.existingSecret | default (printf "%s-db-credentials" .Release.Name) -}}
{{- end }}

{{- define "postgres.secretKey" -}}
{{- if .Values.auth.existingSecret -}}
{{- .Values.auth.existingSecretKey -}}
{{- else -}}
password
{{- end -}}
{{- end }}
