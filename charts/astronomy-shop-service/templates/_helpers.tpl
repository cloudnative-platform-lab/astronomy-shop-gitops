{{- define "astronomy-shop-service.name" -}}
{{- required "service.name is required" .Values.service.name -}}
{{- end -}}

{{- define "astronomy-shop-service.fullname" -}}
{{- include "astronomy-shop-service.name" . | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "astronomy-shop-service.labels" -}}
app.kubernetes.io/name: {{ include "astronomy-shop-service.name" . }}
app.kubernetes.io/instance: {{ include "astronomy-shop-service.fullname" . }}
app.kubernetes.io/part-of: astronomy-shop
app.kubernetes.io/managed-by: argocd
environment: {{ .Values.service.environment | quote }}
{{- end -}}

{{- define "astronomy-shop-service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "astronomy-shop-service.name" . }}
app.kubernetes.io/instance: {{ include "astronomy-shop-service.fullname" . }}
{{- end -}}

{{- define "astronomy-shop-service.image" -}}
{{- $repository := required "image.repository is required; let application CI update the environment values file before enabling the GitOps root" .Values.image.repository -}}
{{- if .Values.image.digest -}}
{{- printf "%s@%s" $repository .Values.image.digest -}}
{{- else if .Values.image.tag -}}
{{- printf "%s:%s" $repository .Values.image.tag -}}
{{- else -}}
{{- fail "image.digest or image.tag is required; immutable image.digest is preferred" -}}
{{- end -}}
{{- end -}}

{{- define "astronomy-shop-service.istio.virtualServiceName" -}}
{{- default (printf "%s-virtualservice" (include "astronomy-shop-service.fullname" .)) .Values.rollout.trafficRouting.istio.virtualService.name -}}
{{- end -}}

{{- define "astronomy-shop-service.istio.destinationRuleName" -}}
{{- default (printf "%s-destination" (include "astronomy-shop-service.fullname" .)) .Values.rollout.trafficRouting.istio.destinationRule.name -}}
{{- end -}}
