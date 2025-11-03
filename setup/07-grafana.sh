#!/bin/bash
# Script de instalacion de Grafana en Docker

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../config"
GRAFANA_DIR="${SCRIPT_DIR}/../monitoring/grafana"

# Cargar funciones comunes
if [ -f "${CONFIG_DIR}/common.sh" ]; then
    source "${CONFIG_DIR}/common.sh"
else
    echo "Error: No se encuentra common.sh"
    exit 1
fi

# Verificar que estamos como root
check_root

# Verificar que Docker esta instalado y corriendo
docker_is_installed() {
    if command_exists docker; then
        DOCKER_VERSION=$(docker --version 2>/dev/null)
        if [ $? -eq 0 ]; then
            return 0
        fi
    fi
    return 1
}

docker_service_running() {
    if systemctl is-active --quiet docker; then
        return 0
    fi
    return 1
}

# Funcion para verificar si Grafana esta corriendo
grafana_is_running() {
    if docker ps | grep -q grafana; then
        return 0
    fi
    return 1
}

# Funcion para instalar Grafana
install_grafana() {
    log_install "Instalando Grafana en Docker..."
    
    if ! docker_is_installed; then
        log_error "Docker no esta instalado. Ejecuta ./setup/02-docker.sh primero"
        exit 1
    fi
    
    if ! docker_service_running; then
        log_error "Docker no esta corriendo. Ejecuta: systemctl start docker"
        exit 1
    fi
    
    # Navegar al directorio de Grafana
    cd "$GRAFANA_DIR" || {
        log_error "No se puede acceder al directorio de Grafana"
        exit 1
    }
    
    # Descargar la imagen de Grafana
    log_download "Descargando imagen oficial de Grafana..."
    docker compose pull grafana
    
    if [ $? -ne 0 ]; then
        log_error "Error al descargar imagen de Grafana"
        exit 1
    fi
    
    # Iniciar Grafana
    log_install "Iniciando contenedor de Grafana..."
    docker compose up -d
    
    if [ $? -ne 0 ]; then
        log_error "Error al iniciar Grafana"
        exit 1
    fi
    
    # Esperar a que Grafana inicie
    log_progress "Esperando a que Grafana inicie..."
    sleep 10
    
    # Verificar que Grafana este corriendo
    if grafana_is_running; then
        log_success "Grafana iniciado exitosamente"
    else
        log_error "Grafana no pudo iniciarse correctamente"
        exit 1
    fi
    
    # Mostrar informacion de acceso
    log_info ""
    log_section "Grafana Instalado Exitosamente"
    log_info "URL de acceso: http://localhost:3000"
    log_info "Puerto: 3000"
    log_info "Usuario: admin"
    log_info "Password: admin"
    log_info ""
    log_check "Verificar logs de Grafana:"
    log_info "docker logs grafana"
}

# Funcion principal
main() {
    log_section "Instalacion de Grafana en Docker"
    
    # Verificar si Grafana ya esta corriendo
    if grafana_is_running; then
        log_success "Grafana ya esta corriendo"
        log_info "URL: http://localhost:3000"
        log_info "Usuario: admin / Password: admin"
        log_info ""
        log_check "Para reiniciar Grafana, ejecuta:"
        log_info "cd ${GRAFANA_DIR} && docker compose restart"
        log_info ""
        log_check "Para detener Grafana, ejecuta:"
        log_info "cd ${GRAFANA_DIR} && docker compose down"
        return 0
    fi
    
    # Grafana no esta instalado, proceder con instalacion
    install_grafana
}

# Ejecutar funcion principal
main "$@"
