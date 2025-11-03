#!/bin/bash
# Script de instalacion de Grafana
# Wrapper que llama al script principal de setup

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Llamar al script principal de setup
if [ -f "${SCRIPT_DIR}/../../setup/07-grafana.sh" ]; then
    bash "${SCRIPT_DIR}/../../setup/07-grafana.sh" "$@"
else
    echo "Error: No se encuentra el script principal de instalacion"
    exit 1
fi