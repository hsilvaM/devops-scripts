#!/bin/bash
# Script de instalacion de Jenkins en Docker

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../../config"
JENKINS_DIR="${SCRIPT_DIR}/../../jenkins"

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

# Funcion para verificar si Jenkins esta corriendo
jenkins_is_running() {
    if docker ps | grep -q jenkins; then
        return 0
    fi
    return 1
}

# Funcion para verificar si existen los directorios de datos de Jenkins
jenkins_data_exists() {
    if [ -d "/var/jenkins_home" ] || [ -d "${SCRIPT_DIR}/../docker/volumes/jenkins" ]; then
        return 0
    fi
    return 1
}

# Funcion para preparar directorios y permisos
prepare_jenkins_directories() {
    log_config "Preparando directorios para Jenkins..."
    
    # Crear directorio de datos de Jenkins si no existe
    if [ ! -d "/var/jenkins_home" ]; then
        log_info "Creando directorio /var/jenkins_home..."
        mkdir -p /var/jenkins_home
        chown -R 1000:1000 /var/jenkins_home
    else
        log_check "Directorio /var/jenkins_home ya existe"
    fi
}

# Funcion para crear docker-compose.yml si no existe
create_docker_compose_file() {
    local compose_file="${JENKINS_DIR}/docker-compose.yml"
    
    if [ -f "$compose_file" ] && [ -s "$compose_file" ]; then
        log_check "docker-compose.yml ya existe"
        return 0
    fi
    
    log_config "Creando archivo docker-compose.yml para Jenkins..."
    
    cat > "$compose_file" << 'EOF'
version: '3.8'

services:
  jenkins:
    image: jenkins/jenkins:lts
    container_name: jenkins
    restart: unless-stopped
    privileged: true
    user: root
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - /var/jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - JENKINS_OPTS=--prefix=/jenkins
    networks:
      - jenkins-net

networks:
  jenkins-net:
    driver: bridge
EOF
    
    log_success "docker-compose.yml creado exitosamente"
}

# Funcion para instalar Jenkins
install_jenkins() {
    log_install "Instalando Jenkins en Docker..."
    
    if ! docker_is_installed; then
        log_error "Docker no esta instalado. Ejecuta ./setup/02-docker.sh primero"
        exit 1
    fi
    
    if ! docker_service_running; then
        log_error "Docker no esta corriendo. Ejecuta: systemctl start docker"
        exit 1
    fi
    
    prepare_jenkins_directories
    create_docker_compose_file
    
    # Navegar al directorio de Jenkins
    cd "$JENKINS_DIR" || {
        log_error "No se puede acceder al directorio de Jenkins"
        exit 1
    }
    
    # Descargar la imagen de Jenkins
    log_download "Descargando imagen oficial de Jenkins LTS..."
    docker compose pull jenkins
    
    if [ $? -ne 0 ]; then
        log_error "Error al descargar imagen de Jenkins"
        exit 1
    fi
    
    # Iniciar Jenkins
    log_install "Iniciando contenedor de Jenkins..."
    docker compose up -d
    
    if [ $? -ne 0 ]; then
        log_error "Error al iniciar Jenkins"
        exit 1
    fi
    
    # Esperar a que Jenkins inicie
    log_progress "Esperando a que Jenkins inicie..."
    sleep 10
    
    # Verificar que Jenkins este corriendo
    if jenkins_is_running; then
        log_success "Jenkins iniciado exitosamente"
    else
        log_error "Jenkins no pudo iniciarse correctamente"
        exit 1
    fi
    
    # Mostrar informacion de acceso
    log_info ""
    log_section "Jenkins Instalado Exitosamente"
    log_info "URL de acceso: http://localhost:8080/jenkins"
    log_info "Puerto: 8080"
    log_info ""
    log_important "Para obtener la contraseña inicial, ejecuta:"
    log_info "docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword"
    log_info ""
    log_check "Verificar logs de Jenkins:"
    log_info "docker logs jenkins"
}

# Funcion principal
main() {
    log_section "Instalacion de Jenkins en Docker"
    
    # Verificar si Jenkins ya esta corriendo
    if jenkins_is_running; then
        log_success "Jenkins ya esta corriendo"
        log_info "URL: http://localhost:8080/jenkins"
        log_info ""
        log_check "Para reiniciar Jenkins, ejecuta:"
        log_info "cd ${JENKINS_DIR} && docker compose restart"
        log_info ""
        log_check "Para detener Jenkins, ejecuta:"
        log_info "cd ${JENKINS_DIR} && docker compose down"
        return 0
    fi
    
    # Verificar si los datos de Jenkins ya existen
    if jenkins_data_exists; then
        log_info "Datos de Jenkins encontrados, iniciando contenedor..."
        cd "$JENKINS_DIR" || {
            log_error "No se puede acceder al directorio de Jenkins"
            exit 1
        }
        
        create_docker_compose_file
        
        log_install "Iniciando Jenkins con datos existentes..."
        docker compose up -d
        
        if jenkins_is_running; then
            log_success "Jenkins iniciado exitosamente con datos existentes"
            log_info "URL: http://localhost:8080/jenkins"
            return 0
        else
            log_error "Error al iniciar Jenkins con datos existentes"
            log_error "Verifica los logs: docker logs jenkins"
            exit 1
        fi
    fi
    
    # Jenkins no esta instalado, proceder con instalacion
    install_jenkins
}

# Ejecutar funcion principal
main "$@"
