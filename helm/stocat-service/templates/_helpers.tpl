{{- define "stocat.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "stocat.fullname" -}}
{{- $name := include "stocat.name" . -}}
{{- printf "%s" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- /* Per-app full name */ -}}
{{- define "stocat.app.fullname" -}}
{{- $root := index . 0 -}}
{{- $app := index . 1 -}}
{{- printf "%s-%s" (include "stocat.fullname" $root) $app.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- /* Generic resource fullname from name */ -}}
{{- define "stocat.resource.fullname" -}}
{{- $root := index . 0 -}}
{{- $name := index . 1 -}}
{{- printf "%s-%s" (include "stocat.fullname" $root) $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
