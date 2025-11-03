#!/bin/bash
# Funciones comunes para todos los scripts

# Códigos ANSI para colores
RESET='\033[0m'
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

BRIGHT_BLACK='\033[1;30m'
BRIGHT_RED='\033[1;31m'
BRIGHT_GREEN='\033[1;32m'
BRIGHT_YELLOW='\033[1;33m'
BRIGHT_BLUE='\033[1;34m'
BRIGHT_MAGENTA='\033[1;35m'
BRIGHT_CYAN='\033[1;36m'
BRIGHT_WHITE='\033[1;37m'

BOLD='\033[1m'
DIM='\033[2m'
UNDERLINE='\033[4m'

# Variables de entorno
NO_COLOR="${NO_COLOR:-}"

# Detectar soporte de color
supports_color() {
    if [ -n "$NO_COLOR" ]; then
        return 1
    fi
    if [ -t 1 ]; then
        local colors=$(tput colors 2>/dev/null || echo "0")
        [ "$colors" -gt 2 ]
    else
        return 1
    fi
}

# Funciones de logging
log_info() {
    if supports_color; then
        echo -e "${CYAN}[INFO]${RESET} $1"
    else
        echo "[INFO] $1"
    fi
}

log_download() {
    if supports_color; then
        echo -e "${MAGENTA}[DOWNLOAD]${RESET} $1"
    else
        echo "[DOWNLOAD] $1"
    fi
}

log_install() {
    if supports_color; then
        echo -e "${BRIGHT_BLUE}[INSTALL]${RESET} $1"
    else
        echo "[INSTALL] $1"
    fi
}

log_success() {
    if supports_color; then
        echo -e "${GREEN}[SUCCESS]${RESET} $1"
    else
        echo "[SUCCESS] $1"
    fi
}

log_warn() {
    if supports_color; then
        echo -e "${BRIGHT_YELLOW}[WARN]${RESET} $1"
    else
        echo "[WARN] $1"
    fi
}

log_error() {
    if supports_color; then
        echo -e "${BRIGHT_RED}[ERROR]${RESET} $1" >&2
    else
        echo "[ERROR] $1" >&2
    fi
}

log_debug() {
    if [ "${DEBUG:-0}" = "1" ]; then
        if supports_color; then
            echo -e "${DIM}${WHITE}[DEBUG]${RESET} $1" >&2
        else
            echo "[DEBUG] $1" >&2
        fi
    fi
}

log_check() {
    if supports_color; then
        echo -e "${GREEN}[CHECK]${RESET} $1"
    else
        echo "[CHECK] $1"
    fi
}

log_config() {
    if supports_color; then
        echo -e "${BRIGHT_CYAN}[CONFIG]${RESET} $1"
    else
        echo "[CONFIG] $1"
    fi
}

log_progress() {
    if supports_color; then
        echo -e "${BLUE}[PROGRESS]${RESET} $1"
    else
        echo "[PROGRESS] $1"
    fi
}

log_important() {
    if supports_color; then
        echo -e "${BOLD}${BRIGHT_YELLOW}[IMPORTANT]${RESET} $1"
    else
        echo "[IMPORTANT] $1"
    fi
}

log_section() {
    if supports_color; then
        echo -e "${BOLD}${BRIGHT_CYAN}${UNDERLINE}=== $1 ===${RESET}"
    else
        echo "=== $1 ==="
    fi
}

log_separator() {
    if supports_color; then
        echo -e "${DIM}${BLUE}----------------------------------------${RESET}"
    else
        echo "----------------------------------------"
    fi
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

