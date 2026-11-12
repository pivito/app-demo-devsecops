
#!/usr/bin/env bash
set -euo pipefail
DRY_RUN="${DRY_RUN:-true}"

NAMESPACE="lab-test-api"
SELECTOR="app.kubernetes.io/managed-by=jenkins-operations"
NOW=$(date -u +%s)

echo "=== Limpieza de entornos efímeros ==="
echo "Namespace: $NAMESPACE"
echo "Fecha UTC: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"

kubectl get deployments \
  -n "$NAMESPACE" \
  -l "$SELECTOR" \
  -o json |
jq -r '
  .items[] |
  [
    .metadata.name,
    (.metadata.annotations["devsecops.io/expires-at"] // ""),
    (.metadata.labels["devsecops.io/test-name"] // "")
  ] | @tsv
' |
while IFS=$'\t' read -r NAME EXPIRES TEST_NAME; do

  if [[ -z "$EXPIRES" || -z "$TEST_NAME" ]]; then
    echo "OMITIDO: $NAME (metadatos incompletos)"
    continue
  fi

  if [[ "$NAME" != "app-$TEST_NAME" ]]; then
    echo "OMITIDO: $NAME (nombre no válido)"
    continue
  fi

  if [[ ! "$EXPIRES" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
    echo "OMITIDO: $NAME (formato de fecha incorrecto)"
    continue
  fi

  if ! EXPIRES_TS=$(date -u -d "$EXPIRES" +%s 2>/dev/null); then
    echo "OMITIDO: $NAME (fecha no válida)"
    continue
  fi

  if (( NOW < EXPIRES_TS )); then
    echo "ACTIVO: $NAME (expira $EXPIRES)"
    continue
  fi

  echo "CADUCADO: $NAME"

  # Verificar que el Service pertenece a la misma prueba.
  SERVICE_OWNER=$(kubectl get service "$NAME" \
    -n "$NAMESPACE" \
    -o jsonpath='{.metadata.labels.app\.kubernetes\.io/managed-by}' \
    --ignore-not-found)

  if [[ "$SERVICE_OWNER" != "jenkins-operations" ]]; then
    echo "OMITIDO: $NAME (Service no administrado por Jenkins)"
    continue
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
  echo "SIMULACIÓN: se eliminarían Service y Deployment: $NAME"
  continue
fi

echo "Eliminando Service: $NAME"
kubectl delete service "$NAME" -n "$NAMESPACE"

echo "Eliminando Deployment: $NAME"
kubectl delete deployment "$NAME" -n "$NAMESPACE"

  echo "ELIMINADO: $NAME"
done

echo "=== Limpieza finalizada ==="
