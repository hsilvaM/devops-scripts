#!/bin/bash
# Script para verificar el estado de todos los servicios

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../config"

# Cargar funciones comunes
if [ -f "${CONFIG_DIR}/common.sh" ]; then
    source "${CONFIG_DIR}/common.sh"
else
    echo "Error: No se encuentra common.sh"
    exit 1
fi

# Funcion para verificar un contenedor
check_container() {
    local container_name=$1
    local friendly_name=$2
    
    if docker ps | grep -q "$container_name"; then
        log_success "$friendly_name: CORRIENDO"
        return 0
    elif docker ps -a | grep -q "$container_name"; then
        log_warn "$friendly_name: DETENIDO"
        return 1
    else
        log_error "$friendly_name: NO INSTALADO"
        return 2
    fi
}

# Funcion principal
main() {
    log_section "Estado de Servicios"
    log_info ""
    
    # Servicios principales
    log_info "=== Servicios DevOps ==="
    check_container "jenkins" "Jenkins"
    check_container "prometheus" "Prometheus"
    check_container "grafana" "Grafana"
    
    log_info ""
    log_info "=== Aplicaciones ==="
    check_container "nestjs-api-portal" "NestJS API Portal"
    check_container "nestjs-api-autenticacion" "NestJS API Autenticacion"
    
    log_info ""
    log_section "Redes Docker"
    docker network ls | grep -E "(apps-net|monitoring-net|jenkins-net)" || log_info "Ninguna red personalizada encontrada"
    
    log_info ""
    log_section "Resumen de Puertos"
    echo "  Jenkins:              http://localhost:8080/jenkins"
    echo "  Prometheus:            http://localhost:9090"
    echo "  Grafana:               http://localhost:3000"
    echo "  NestJS API Portal:     http://localhost:3003"
    echo "  NestJS API Autenticacion: http://localhost:3004"
    echo "  PHP Oracle:            http://localhost:3001/php"
}

main "$@"
