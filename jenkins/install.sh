#!/bin/bash
# Script de instalacion de Jenkins
# Wrapper que llama al script principal de setup

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Llamar al script principal de setup
if [ -f "${SCRIPT_DIR}/../docker/jenkins/install.sh" ]; then
    bash "${SCRIPT_DIR}/../docker/jenkins/install.sh" "$@"
else
    echo "Error: No se encuentra el script principal de instalacion"
    exit 1
fi