#!/bin/bash
# Funciones comunes para todos los scripts

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funciones de logging
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validar si un comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Validar si estamos como root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Este script requiere permisos de root"
        exit 1
    fi
}

