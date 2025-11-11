#!/bin/bash
# Script de despliegue de aplicacion PHP con Oracle

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "${SCRIPT_DIR}/../../docker/apps/php/install.sh" ]; then
    bash "${SCRIPT_DIR}/../../docker/apps/php/install.sh" "$@"
else
    echo "Error: No se encuentra el script principal de instalacion"
    exit 1
fi

