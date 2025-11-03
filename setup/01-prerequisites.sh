#!/bin/bash
# Script de verificacion de pre-requisitos del sistema

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

# Funcion para verificar si Docker esta instalado
docker_is_installed() {
    if command_exists docker; then
        DOCKER_VERSION=$(docker --version 2>/dev/null)
        if [ $? -eq 0 ]; then
            return 0
        fi
    fi
    return 1
}

# Funcion para verificar el servicio de Docker
docker_service_running() {
    if systemctl is-active --quiet docker; then
        return 0
    fi
    return 1
}

# Funcion para verificar si Git esta instalado
git_is_installed() {
    if command_exists git; then
        GIT_VERSION=$(git --version 2>/dev/null)
        if [ $? -eq 0 ]; then
            return 0
        fi
    fi
    return 1
}

# Funcion para instalar Git
install_git() {
    log_info "Instalando Git..."
    
    # Verificar gestor de paquetes disponible
    if command_exists dnf; then
        PACKAGE_MANAGER="dnf"
    elif command_exists yum; then
        PACKAGE_MANAGER="yum"
    else
        log_error "No se encuentra dnf ni yum. Este script requiere RHEL/AlmaLinux/CentOS"
        exit 1
    fi
    
    log_info "Usando $PACKAGE_MANAGER para instalar Git..."
    
    $PACKAGE_MANAGER install -y git
    
    if [ $? -ne 0 ]; then
        log_error "Error al instalar Git"
        return 1
    fi
    
    return 0
}

# Funcion para verificar Git
check_git() {
    log_info "Verificando Git..."
    
    if git_is_installed; then
        GIT_VERSION=$(git --version)
        log_info "Git esta instalado: $GIT_VERSION"
        return 0
    else
        log_warn "Git no esta instalado"
        log_info "Instalando Git automaticamente..."
        
        if install_git; then
            GIT_VERSION=$(git --version)
            log_info "Git instalado exitosamente: $GIT_VERSION"
            return 0
        else
            log_error "No se pudo instalar Git"
            return 1
        fi
    fi
}

# Funcion para verificar Docker
check_docker() {
    log_info "Verificando Docker..."
    
    if docker_is_installed; then
        DOCKER_VERSION=$(docker --version)
        log_info "Docker esta instalado: $DOCKER_VERSION"
        
        if docker_service_running; then
            log_info "Servicio Docker esta corriendo"
            
            # Verificar que Docker funcione correctamente
            log_info "Ejecutando prueba de Docker..."
            if docker run --rm hello-world >/dev/null 2>&1; then
                log_info "Docker funciona correctamente"
                return 0
            else
                log_warn "Docker esta instalado pero no pudo ejecutar contenedores"
                log_warn "Esto puede ser normal en instalaciones sin acceso a internet"
                return 0
            fi
        else
            log_warn "Docker esta instalado pero el servicio no esta corriendo"
            log_warn "Ejecuta: systemctl start docker"
            return 1
        fi
    else
        log_warn "Docker no esta instalado"
        log_info "Ejecuta ./setup/02-docker.sh para instalarlo"
        return 1
    fi
}

# Funcion principal
main() {
    log_info "=== Verificacion de Pre-requisitos ==="
    
    # Verificar Git
    GIT_OK=false
    if check_git; then
        GIT_OK=true
    fi
    
    log_info ""
    
    # Verificar Docker
    DOCKER_OK=false
    if check_docker; then
        DOCKER_OK=true
    fi
    
    log_info ""
    log_info "=== Resumen de Pre-requisitos ==="
    
    if [ "$GIT_OK" = true ]; then
        log_info "Git: OK"
    else
        log_error "Git: FALTA"
    fi
    
    if [ "$DOCKER_OK" = true ]; then
        log_info "Docker: OK"
    else
        log_error "Docker: FALTA"
    fi
    
    if [ "$GIT_OK" = false ] || [ "$DOCKER_OK" = false ]; then
        log_error "Algunos pre-requisitos no estan cumplidos"
        exit 1
    fi
    
    log_info "Todos los pre-requisitos estan cumplidos"
    return 0
}

# Ejecutar funcion principal
main "$@"

