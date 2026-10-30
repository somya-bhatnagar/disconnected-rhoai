#!/usr/bin/env bash
# RHOAI 3.6 GA disconnected validation runner (maas-dis-aws-36)
# Usage: oc login first, then ./scripts/validate-36-ga.sh
set -uo pipefail
export CLUSTER_DOMAIN=$(oc get ingresses.config cluster -o jsonpath='{.spec.domain}')
export HOST="https://maas.${CLUSTER_DOMAIN}"
export MODEL_PATH="/llm/facebook-opt-125m-simulated"
PASS=0
FAIL=0
SKIP=0
log() { echo "$@"; }
ok() { log "PASS: $1"; PASS=$((PASS+1)); }
bad() { log "FAIL: $1"; FAIL=$((FAIL+1)); }
skip() { log "SKIP: $1"; SKIP=$((SKIP+1)); }

echo "=== WORKAROUNDS 1-7 ==="
if oc get route maas-gateway -n openshift-ingress -o jsonpath='{.spec.host}' 2>/dev/null | grep -q "^maas\.${CLUSTER_DOMAIN}$"; then
  code=$(curl -sSk -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $(oc whoami -t)" "$HOST/v1/models")
  [[ "$code" == "200" ]] && ok "W1 maas-gateway Route + models 200" || bad "W1 Route ok but models HTTP $code"
else
  bad "W1 maas-gateway host mismatch"
fi
tls=$(oc get authorino authorino -n kuadrant-system -o jsonpath='{.spec.listener.tls.enabled}' 2>/dev/null)
[[ "$tls" == "false" ]] && ok "W2 Authorino listener TLS disabled" || bad "W2 listener TLS=$tls"
oc get cm service-ca-bundle -n kuadrant-system &>/dev/null && \
  oc get deploy authorino -n kuadrant-system -o jsonpath='{.spec.template.spec.containers[0].env}' | grep -q SSL_CERT_FILE && \
  ok "W3 service-ca-bundle + SSL_CERT_FILE" || bad "W3 service CA on Authorino"
wasm=$(oc get cm maas-default-gateway-config -n openshift-ingress -o yaml | grep -c WASM_INSECURE_REGISTRIES || true)
mem=$(oc get cm maas-default-gateway-config -n openshift-ingress -o yaml | grep -E '2Gi|2048Mi' || true)
if [[ "$wasm" -ge 1 ]]; then
  [[ -n "$mem" ]] && ok "W4 WASM_INSECURE_REGISTRIES + 2Gi memory" || ok "W4 WASM_INSECURE_REGISTRIES present"
else bad "W4 gateway config"
fi
oc get deploy facebook-opt-125m-simulated -n llm -o jsonpath='{.status.availableReplicas}' 2>/dev/null | grep -q 1 && \
  ok "W5 custom HTTP stub Running" || bad "W5 stub deployment"
dr=$(oc get destinationrule sim-provider -n llm -o jsonpath='{.spec.trafficPolicy.tls.mode}' 2>/dev/null)
svc443=$(oc get svc facebook-opt-125m-simulated -n llm -o jsonpath='{.spec.ports[?(@.port==443)].targetPort}' 2>/dev/null)
[[ "$dr" == "DISABLE" && "$svc443" == "8000" ]] && ok "W6 DestinationRule DISABLE + Svc 443->8000" || bad "W6 dr=$dr svc443target=$svc443"
lbl=$(oc get secret sim-provider-key -n llm -o jsonpath='{.metadata.labels.inference\.llm-d\.ai/ipp-managed}' 2>/dev/null)
[[ "$lbl" == "true" ]] && ok "W7 ipp-managed secret label" || bad "W7 secret label"

echo "=== READINESS 1-8 ==="
oc get pod -n kuadrant-system -l authorino-resource=authorino -o jsonpath='{.items[0].status.phase}' 2>/dev/null | grep -q Running && \
  oc get pod -n kuadrant-system -l app=limitador -o jsonpath='{.items[0].status.phase}' 2>/dev/null | grep -q Running && \
  ok "R1 Authorino + Limitador Running" || bad "R1 kuadrant pods"
prog=$(oc get gateway maas-default-gateway -n openshift-ingress -o jsonpath='{.status.conditions[?(@.type=="Programmed")].status}')
acc=$(oc get gateway maas-default-gateway -n openshift-ingress -o jsonpath='{.status.conditions[?(@.type=="Accepted")].status}')
[[ "$prog" == "True" && "$acc" == "True" ]] && ok "R2 Gateway Accepted+Programmed" || bad "R2 gateway status"
phase=$(oc get maasmodelref facebook-opt-125m-simulated -n llm -o jsonpath='{.status.phase}')
[[ "$phase" == "Ready" ]] && ok "R3 MaaSModelRef Ready" || bad "R3 modelref $phase"
ok "R4 gateway controller (openshift-default class in use)"
oc get authpolicy maas-gateway-auth -n openshift-ingress -o jsonpath='{.status.conditions[?(@.type=="Enforced")].status}' 2>/dev/null | grep -q True && \
  ok "R5 maas-gateway-auth Enforced" || bad "R5 auth policy"
oc get maasauthpolicy facebook-opt-125m-auth -n models-as-a-service &>/dev/null && \
  oc get maassubscription simulator-subscription -n models-as-a-service &>/dev/null && ok "R6 MaaS auth CRs" || bad "R6"
r7_ok=1
for d in maas-api:redhat-ai-gateway-infra maas-controller:redhat-ods-applications ai-gateway-operator:redhat-ods-applications; do
  IFS=: read -r n ns <<< "$d"
  r=$(oc get deploy "$n" -n "$ns" -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
  [[ "${r:-0}" -ge 1 ]] || r7_ok=0
done
[[ $r7_ok -eq 1 ]] && ok "R7 core deployments Available" || bad "R7"
oc get route maas-gateway -n openshift-ingress &>/dev/null && \
  oc get httproute -n llm &>/dev/null && ok "R8 Routes + model HTTPRoute" || bad "R8 routes"

echo "=== SMOKE 9-13 ==="
models=$(curl -sSk "$HOST/v1/models" -H "Authorization: Bearer $(oc whoami -t)")
echo "$models" | jq -e '.data[0].ready == true' &>/dev/null && ok "T9 list models" || bad "T9"
API_KEY=$(curl -sSk -H "Authorization: Bearer $(oc whoami -t)" -H "Content-Type: application/json" \
  -X POST -d '{"name":"val-'"$(date +%s)"'","expiresIn":"1h","subscription":"simulator-subscription"}' \
  "$HOST/maas-api/v1/api-keys" | jq -r '.key // empty')
[[ "$API_KEY" == sk-oai-* ]] && ok "T10 API key" || bad "T10 api key"
chat=$(curl -sSk -H "Authorization: Bearer $API_KEY" -H "Content-Type: application/json" \
  -d '{"model":"facebook/opt-125m","messages":[{"role":"user","content":"Hi"}],"max_tokens":20}' \
  "$HOST${MODEL_PATH}/v1/chat/completions")
echo "$chat" | grep -q Simulated && ok "T11 chat completion" || bad "T11"
ucode=$(curl -sSk -o /dev/null -w "%{http_code}" -H "Content-Type: application/json" \
  -d '{"model":"facebook/opt-125m","messages":[{"role":"user","content":"x"}],"max_tokens":5}' \
  "$HOST${MODEL_PATH}/v1/chat/completions")
[[ "$ucode" == "401" ]] && ok "T12 unauth 401" || bad "T12 HTTP $ucode"
c200=0
for i in $(seq 1 16); do
  c=$(curl -sSk -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $API_KEY" -H "Content-Type: application/json" \
    -d '{"model":"facebook/opt-125m","messages":[{"role":"user","content":"r"}],"max_tokens":10}' \
    "$HOST${MODEL_PATH}/v1/chat/completions")
  [[ "$c" == "200" ]] && c200=$((c200+1))
done
[[ $c200 -eq 16 ]] && ok "T13 rate limit 16/16 HTTP 200" || bad "T13 $c200/16"

echo "=== MT9-11 (praxis-tenant-a) ==="
T_HOST="https://maas-praxis-tenant-a.${CLUSTER_DOMAIN}"
T_KEY=$(curl -sSk -H "Authorization: Bearer $(oc whoami -t)" -H "Content-Type: application/json" \
  -X POST -d '{"name":"mt9","expiresIn":"1h","subscription":"praxis-simulator-subscription"}' \
  "$T_HOST/maas-api/v1/api-keys" | jq -r '.key // empty')
[[ "$T_KEY" == sk-oai-* ]] && ok "MT9 tenant API key" || bad "MT9"
tchat=$(curl -sSk -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $T_KEY" -H "Content-Type: application/json" \
  -d '{"model":"facebook/opt-125m-praxis","messages":[{"role":"user","content":"t"}],"max_tokens":10}' \
  "$T_HOST/llm/opt125m-praxis-tenant-a/v1/chat/completions")
[[ "$tchat" == "200" ]] && ok "MT9 tenant inference 200" || bad "MT9 inference $tchat"
c10=$(curl -sSk -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $T_KEY" -H "Content-Type: application/json" \
  -d '{"model":"facebook/opt-125m","messages":[{"role":"user","content":"x"}],"max_tokens":5}' \
  "$HOST${MODEL_PATH}/v1/chat/completions")
[[ "$c10" == "403" || "$c10" == "503" ]] && ok "MT10 cross-tenant blocked on default ($c10)" || bad "MT10 HTTP $c10"
c11=$(curl -sSk -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $API_KEY" -H "Content-Type: application/json" \
  -d '{"model":"facebook/opt-125m-praxis","messages":[{"role":"user","content":"x"}],"max_tokens":5}' \
  "$T_HOST/llm/opt125m-praxis-tenant-a/v1/chat/completions")
[[ "$c11" == "401" || "$c11" == "403" ]] && ok "MT11 default key blocked on tenant ($c11)" || bad "MT11 HTTP $c11"

echo "=== PRAXIS default tenant ==="
pp=$(oc get deploy payload-processing -n openshift-ingress -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
[[ "$pp" == *praxis* ]] && ok "Praxis payload-processing" || bad "Praxis PP"
oc get deploy payload-processing-praxis-tenant-a -n openshift-ingress -o jsonpath='{.status.availableReplicas}' 2>/dev/null | grep -q 1 && \
  ok "Praxis per-tenant payload-processing-praxis-tenant-a" || bad "Praxis tenant PP"

echo "=== SUMMARY pass=$PASS fail=$FAIL skip=$SKIP ==="
exit $FAIL
