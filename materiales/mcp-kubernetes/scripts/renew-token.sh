#!/usr/bin/env bash
set -euo pipefail
umask 077

BASE="/home/migue/laboratorios/devsecops/mcp-kubernetes"
CONFIG="$BASE/config/kubernetes-mcp.kubeconfig"
ADMIN_CONFIG="/home/migue/.kube/config"

export KUBECONFIG="$ADMIN_CONFIG"

TOKEN=$(kubectl -n app-demo create token kubernetes-mcp --duration=24h)

if [[ -z "$TOKEN" ]]; then
    echo "ERROR: no se pudo generar el token" >&2
    exit 1
fi

TMP=$(mktemp "$BASE/config/.kubernetes-mcp.XXXXXX")
trap 'rm -f "$TMP"' EXIT

kubectl config view \
    --raw \
    --minify \
    --flatten > "$TMP"

kubectl --kubeconfig "$TMP" config set-credentials \
    kubernetes-mcp --token="$TOKEN" >/dev/null

kubectl --kubeconfig "$TMP" config set-context \
    kubernetes-mcp \
    --cluster="$(kubectl config view --minify -o jsonpath='{.contexts[0].context.cluster}')" \
    --user=kubernetes-mcp \
    --namespace=app-demo >/dev/null

kubectl --kubeconfig "$TMP" config use-context kubernetes-mcp >/dev/null

# Eliminar usuarios administrativos del kubeconfig temporal.
python3 - "$TMP" <<'PY'
import json
import subprocess
import sys

path = sys.argv[1]
data = json.loads(subprocess.check_output(
    ["kubectl", "--kubeconfig", path, "config", "view", "--raw", "-o", "json"]
))

data["users"] = [
    user for user in data["users"]
    if user["name"] == "kubernetes-mcp"
]
data["contexts"] = [
    context for context in data["contexts"]
    if context["name"] == "kubernetes-mcp"
]

with open(path, "w") as f:
    json.dump(data, f)
PY

chmod 600 "$TMP"
mv -f "$TMP" "$CONFIG"
unset TOKEN

echo "Token MCP renovado correctamente"
