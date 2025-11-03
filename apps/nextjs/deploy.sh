#!/bin/bash
# Script de despliegue de aplicacion NextJS

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Llamar al script principal de instalacion
if [ -f "${SCRIPT_DIR}/../../docker/apps/nextjs/install.sh" ]; then
    bash "${SCRIPT_DIR}/../../docker/apps/nextjs/install.sh" "$@"
else
    echo "Error: No se encuentra el script principal de instalacion"
    exit 1
fi