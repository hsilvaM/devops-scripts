#!/bin/bash
# Script principal de instalacion del sistema
# Entrypoint que ejecuta todos los scripts de setup en orden

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

# Funcion para ejecutar un script de setup
run_setup_script() {
    local script_path="$1"
    local script_name=$(basename "$script_path")
    
    if [ ! -f "$script_path" ]; then
        log_warn "Script no encontrado: $script_name (saltando)"
        return 0
    fi
    
    if [ ! -x "$script_path" ]; then
        log_warn "Script no ejecutable: $script_name (saltando)"
        return 0
    fi
    
    log_progress "Ejecutando: $script_name"
    
    if bash "$script_path"; then
        log_success "$script_name completado exitosamente"
        return 0
    else
        log_error "$script_name fallo"
        return 1
    fi
}

# Funcion principal
main() {
    log_section "Script de Configuracion del Sistema"
    log_info ""
    
    # Paso 1: Verificar prerrequisitos iniciales
    log_info "Paso 1: Verificando prerrequisitos iniciales..."
    if run_setup_script "${SCRIPT_DIR}/01-prerequisites.sh"; then
        log_success "Todos los prerrequisitos cumplidos"
    else
        log_info "Algunos prerrequisitos faltan, continuando con instalacion..."
    fi
    
    log_separator
    
    # Paso 2: Instalar Docker (si no esta instalado)
    log_info "Paso 2: Verificando/Instalando Docker..."
    run_setup_script "${SCRIPT_DIR}/02-docker.sh"
    
    log_separator
    
    # Paso 3: Instalar Oracle Client (si existe el script)
    log_info "Paso 3: Verificando/Instalando Oracle Client..."
    run_setup_script "${SCRIPT_DIR}/03-oracle-client.sh"
    
    log_separator
    
    # Paso 4: Instalar Jenkins en Docker
    log_info "Paso 4: Instalando Jenkins en Docker..."
    run_setup_script "${SCRIPT_DIR}/04-jenkins.sh"
    
    log_separator
    
    # Paso 5: Configurar Firewall
    log_info "Paso 5: Configurando Firewall..."
    run_setup_script "${SCRIPT_DIR}/05-firewall.sh"
    
    log_info ""
    
    # Paso final: Verificar prerrequisitos finales
    log_section "Verificacion final de prerrequisitos"
    
    if run_setup_script "${SCRIPT_DIR}/01-prerequisites.sh"; then
        log_info ""
        log_section "Configuracion completada exitosamente"
        return 0
    else
        log_error ""
        log_error "=========================================="
        log_error "  Configuracion completada con errores"
        log_error "  Revisa los mensajes anteriores"
        log_error "=========================================="
        return 1
    fi
}

# Manejo de interrupcion (Ctrl+C)
trap 'log_error "Instalacion interrumpida por el usuario"; exit 1' INT TERM

# Ejecutar funcion principal
main "$@"

