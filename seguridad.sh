#!/usr/bin/env bash
set -euo pipefail

mkdir -p reportes

IMAGE_NAME="${IMAGE_NAME:-estudiante10-api:local}"
API_HEALTH_URL="${API_HEALTH_URL:-http://localhost:8010/health}"
CONTAINERS=("est10_db" "est10_api")

run_gitleaks() {
  echo "[DevSecOps] Ejecutando Gitleaks..."
  if command -v gitleaks >/dev/null 2>&1; then
    gitleaks detect --source . --report-format json --report-path reportes/gitleaks.json || true
  else
    docker run --rm -v "$(pwd):/path" zricethezav/gitleaks:latest detect --source=/path --report-format json --report-path /path/reportes/gitleaks.json || true
  fi
}

run_semgrep() {
  echo "[DevSecOps] Ejecutando Semgrep..."
  if command -v semgrep >/dev/null 2>&1; then
    semgrep --config auto --json --output reportes/semgrep.json . || true
  else
    docker run --rm -v "$(pwd):/src" semgrep/semgrep semgrep --config auto --json --output /src/reportes/semgrep.json /src || true
  fi
}

run_syft() {
  echo "[DevSecOps] Ejecutando Syft (SBOM)..."
  if command -v syft >/dev/null 2>&1; then
    syft "$IMAGE_NAME" -o json > reportes/syft-sbom.json || true
  else
    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v "$(pwd)/reportes:/out" anchore/syft:latest "$IMAGE_NAME" -o json > reportes/syft-sbom.json || true
  fi
}

run_trivy() {
  echo "[DevSecOps] Ejecutando Trivy..."
  if command -v trivy >/dev/null 2>&1; then
    trivy image --format json --output reportes/trivy.json "$IMAGE_NAME" || true
  else
    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v "$(pwd)/reportes:/root/.cache/" aquasec/trivy:latest image --format json --output /root/.cache/trivy.json "$IMAGE_NAME" || true
  fi
}

run_hadolint() {
  echo "[DevSecOps] Ejecutando Hadolint..."
  if command -v hadolint >/dev/null 2>&1; then
    hadolint Dockerfile > reportes/hadolint.txt || true
  else
    docker run --rm -i hadolint/hadolint hadolint - < Dockerfile > reportes/hadolint.txt || true
  fi
}

monitorear() {
  local timestamp
  timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
  {
    echo "=========================================="
    echo "Monitoreo - $timestamp"
    echo "=========================================="
    echo "--- Estado de contenedores ---"
    docker ps -a --filter "name=est10_" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || true
    echo "--- Healthcheck API ($API_HEALTH_URL) ---"
    curl -sS -w "\nHTTP_CODE:%{http_code}\n" "$API_HEALTH_URL" || echo "ERROR: No responde $API_HEALTH_URL"
    echo "--- Ultimos logs (est10_api) ---"
    docker logs --tail 20 est10_api 2>&1 || true
    echo "--- Ultimos logs (est10_db) ---"
    docker logs --tail 10 est10_db 2>&1 || true
    echo ""
  } | tee -a monitoreo.log
}

case "${1:-all}" in
  seguridad)
    run_gitleaks
    run_semgrep
    run_syft
    run_trivy
    run_hadolint
    ;;
  monitorear)
    monitorear
    ;;
  all|*)
    run_gitleaks
    run_semgrep
    run_syft
    run_trivy
    run_hadolint
    monitorear
    ;;
esac