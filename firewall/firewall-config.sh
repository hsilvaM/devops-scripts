#!/bin/bash
# Script principal de configuracion de firewall

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../config"

# Cargar funciones comunes
if [ -f "${CONFIG_DIR}/common.sh" ]; then
    source "${CONFIG_DIR}/common.sh"
else
    echo "Error: No se encuentra common.sh"
    exit 1
fi

# Verificar que estamos como root
check_root

# Ejecutar scripts de configuracion
bash "${SCRIPT_DIR}/services/enable-services.sh"
bash "${SCRIPT_DIR}/ports/open-ports.sh"
bash "${SCRIPT_DIR}/rules/configure-rules.sh"