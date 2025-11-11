#!/bin/bash
# Script de despliegue de aplicacion NestJS (api-portal)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "${SCRIPT_DIR}/../../docker/apps/nestjs/install.sh" ]; then
    bash "${SCRIPT_DIR}/../../docker/apps/nestjs/install.sh" "$@"
else
    echo "Error: No se encuentra el script principal de instalacion"
    exit 1
fi

