{{- define "url-shortener.name" -}}
url-shortener
{{- end }}

{{- define "url-shortener.fullname" -}}
url-shortener
{{- end }}

{{- define "url-shortener.labels" -}}
app.kubernetes.io/name: url-shortener
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: sovereign-kubernetes-idp-lab
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "url-shortener.selectorLabels" -}}
app.kubernetes.io/name: url-shortener
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "url-shortener.apiLabels" -}}
{{ include "url-shortener.labels" . }}
app.kubernetes.io/component: api
{{- end }}

{{- define "url-shortener.apiSelectorLabels" -}}
{{ include "url-shortener.selectorLabels" . }}
app.kubernetes.io/component: api
{{- end }}

{{- define "url-shortener.postgresLabels" -}}
{{ include "url-shortener.labels" . }}
app.kubernetes.io/component: postgres
{{- end }}

{{- define "url-shortener.postgresSelectorLabels" -}}
{{ include "url-shortener.selectorLabels" . }}
app.kubernetes.io/component: postgres
{{- end }}
