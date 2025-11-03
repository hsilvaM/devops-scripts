#!/bin/bash
# Script de instalacion de Docker en RHEL

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

# Funcion para verificar si Docker esta instalado (solo para este script)
docker_is_installed() {
    if command_exists docker; then
        DOCKER_VERSION=$(docker --version 2>/dev/null)
        if [ $? -eq 0 ]; then
            return 0
        fi
    fi
    return 1
}

# Funcion para verificar el servicio de Docker (solo para este script)
docker_service_running() {
    if systemctl is-active --quiet docker; then
        return 0
    fi
    return 1
}

# Funcion para instalar Docker
install_docker() {
    log_install "Instalando Docker..."
    
    # Verificar gestor de paquetes disponible
    if command_exists dnf; then
        PACKAGE_MANAGER="dnf"
    elif command_exists yum; then
        PACKAGE_MANAGER="yum"
    else
        log_error "No se encuentra dnf ni yum. Este script requiere RHEL/CentOS"
        exit 1
    fi
    
    log_config "Usando $PACKAGE_MANAGER como gestor de paquetes"
    
    # Actualizar lista de paquetes
    log_progress "Actualizando lista de paquetes..."
    $PACKAGE_MANAGER makecache -y
    
    # Instalar dependencias necesarias
    log_install "Instalando dependencias..."
    $PACKAGE_MANAGER install -y yum-utils device-mapper-persistent-data lvm2
    
    # Agregar repositorio de Docker (si no existe)
    if [ ! -f /etc/yum.repos.d/docker-ce.repo ]; then
        log_config "Agregando repositorio de Docker..."
        if [ "$PACKAGE_MANAGER" = "dnf" ]; then
            dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        else
            yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        fi
        
        # Si estamos en RHEL, necesitamos usar el repositorio de CentOS o ajustar
        # Nota: Docker CE oficialmente soporta CentOS, no RHEL directamente
        # Por eso podriamos necesitar usar el repositorio de CentOS
    fi
    
    # Instalar Docker CE
    log_install "Instalando Docker CE..."
    $PACKAGE_MANAGER install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    if [ $? -ne 0 ]; then
        log_error "Error al instalar Docker"
        exit 1
    fi
}

# Funcion para iniciar Docker
start_docker() {
    log_config "Iniciando servicio Docker..."
    systemctl start docker
    
    if [ $? -ne 0 ]; then
        log_error "Error al iniciar Docker"
        exit 1
    fi
    
    log_config "Habilitando Docker para inicio automatico..."
    systemctl enable docker
    
    if [ $? -ne 0 ]; then
        log_warn "No se pudo habilitar inicio automatico de Docker"
    fi
}

# Funcion principal
main() {
    log_section "Instalacion de Docker"
    
    # Verificar si Docker ya esta instalado
    if docker_is_installed; then
        DOCKER_VERSION=$(docker --version)
        log_success "Docker ya esta instalado: $DOCKER_VERSION"
        
        # Verificar si el servicio esta corriendo
        if docker_service_running; then
            log_success "Servicio Docker ya esta corriendo"
        else
            log_info "Servicio Docker no esta corriendo, iniciando..."
            start_docker
        fi
        
        log_success "Instalacion de Docker completada"
        log_info "Ejecuta ./setup/01-prerequisites.sh para verificar la instalacion"
        return 0
    fi
    
    # Docker no esta instalado, proceder con la instalacion
    log_install "Docker no esta instalado. Procediendo con la instalacion..."
    
    install_docker
    
    if [ $? -ne 0 ]; then
        log_error "Error durante la instalacion de Docker"
        exit 1
    fi
    
    start_docker
    
    if [ $? -ne 0 ]; then
        log_error "Error al iniciar Docker"
        exit 1
    fi
    
    log_success "Instalacion de Docker completada exitosamente"
    log_info "Ejecuta ./setup/01-prerequisites.sh para verificar la instalacion"
}

# Ejecutar funcion principal
main "$@"

