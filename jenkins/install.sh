#!/bin/bash
# Script de instalacion de Jenkins
# Wrapper que llama al script principal de setup

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Llamar al script principal de setup
if [ -f "${SCRIPT_DIR}/../setup/04-jenkins.sh" ]; then
    bash "${SCRIPT_DIR}/../setup/04-jenkins.sh" "$@"
else
    echo "Error: No se encuentra el script principal de instalacion"
    exit 1
fi