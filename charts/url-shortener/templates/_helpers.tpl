{{- define "url-shortener.name" -}}
url-shortener
{{- end }}

{{- define "url-shortener.fullname" -}}
url-shortener
{{- end }}

{{- define "url-shortener.labels" -}}
app.kubernetes.io/name: url-shortener
app.kubernetes.io/instance: url-shortener
app.kubernetes.io/part-of: sovereign-kubernetes-idp-lab
{{- end }}
