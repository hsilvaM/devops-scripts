#!/bin/bash
# Script de instalacion y configuracion de Nginx

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../config"
NGINX_CONFIG_DIR="/etc/nginx"
NGINX_SITES_DIR="${NGINX_CONFIG_DIR}/conf.d"

# Cargar funciones comunes
if [ -f "${CONFIG_DIR}/common.sh" ]; then
    source "${CONFIG_DIR}/common.sh"
else
    echo "Error: No se encuentra common.sh"
    exit 1
fi

# Verificar que estamos como root
check_root

# Funcion para verificar si nginx esta instalado
nginx_is_installed() {
    if command_exists nginx; then
        return 0
    fi
    return 1
}

# Funcion para verificar si nginx esta corriendo
nginx_is_running() {
    if systemctl is-active --quiet nginx; then
        return 0
    fi
    return 1
}

# Funcion para instalar EPEL (necesario para nginx en RHEL/CentOS)
install_epel() {
    if rpm -qa | grep -q epel-release; then
        log_success "EPEL ya esta instalado"
        return 0
    fi
    
    log_progress "Instalando repositorio EPEL..."
    
    if command_exists yum; then
        yum install -y epel-release
    elif command_exists dnf; then
        dnf install -y epel-release
    else
        log_error "No se puede instalar EPEL sin yum/dnf"
        return 1
    fi
    
    if [ $? -eq 0 ]; then
        log_success "EPEL instalado correctamente"
        return 0
    else
        log_error "Error al instalar EPEL"
        return 1
    fi
}

# Funcion para instalar nginx
install_nginx() {
    log_install "Instalando Nginx..."
    
    if nginx_is_installed; then
        log_success "Nginx ya esta instalado"
        return 0
    fi
    
    if command_exists yum; then
        # Instalar EPEL primero si es necesario
        if ! install_epel; then
            log_error "No se pudo instalar EPEL, necesario para nginx"
            return 1
        fi
        log_progress "Instalando Nginx con yum..."
        yum install -y nginx
    elif command_exists dnf; then
        # Instalar EPEL primero si es necesario
        if ! install_epel; then
            log_error "No se pudo instalar EPEL, necesario para nginx"
            return 1
        fi
        log_progress "Instalando Nginx con dnf..."
        dnf install -y nginx
    elif command_exists apt-get; then
        log_progress "Instalando Nginx con apt-get..."
        apt-get update
        apt-get install -y nginx
    else
        log_error "No se encontro gestor de paquetes compatible (yum/dnf/apt-get)"
        return 1
    fi
    
    if [ $? -eq 0 ]; then
        log_success "Nginx instalado correctamente"
        return 0
    else
        log_error "Error al instalar Nginx"
        return 1
    fi
}

# Funcion para crear configuracion de emetra.muniguate.com
configure_emetra() {
    log_config "Configurando Nginx para emetra.muniguate.com..."
    
    local config_file="${NGINX_SITES_DIR}/emetra.muniguate.com.conf"
    
    log_progress "Creando configuracion en ${config_file}..."
    
    cat > "${config_file}" << 'EOF'
server {
    listen 80;
    server_name emetra.muniguate.com;

    # Logs
    access_log /var/log/nginx/emetra-access.log;
    error_log /var/log/nginx/emetra-error.log;

    # Configuracion de proxy
    location / {
        proxy_pass http://localhost:3002;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Configuracion de tamaño maximo de archivos
    client_max_body_size 10M;
}
EOF

    if [ $? -eq 0 ]; then
        log_success "Configuracion creada en ${config_file}"
        return 0
    else
        log_error "Error al crear configuracion"
        return 1
    fi
}

# Funcion para verificar configuracion de nginx
test_nginx_config() {
    log_progress "Verificando configuracion de Nginx..."
    
    if nginx -t 2>&1; then
        log_success "Configuracion de Nginx es valida"
        return 0
    else
        log_error "Error en la configuracion de Nginx"
        return 1
    fi
}

# Funcion para iniciar y habilitar nginx
start_nginx() {
    log_progress "Iniciando y habilitando Nginx..."
    
    systemctl enable nginx
    systemctl start nginx
    
    if [ $? -eq 0 ]; then
        log_success "Nginx iniciado correctamente"
        return 0
    else
        log_error "Error al iniciar Nginx"
        return 1
    fi
}

# Funcion principal
main() {
    log_section "Instalacion y Configuracion de Nginx"
    
    # Instalar nginx
    if ! install_nginx; then
        log_error "No se pudo instalar Nginx"
        return 1
    fi
    
    log_separator
    
    # Crear configuracion
    if ! configure_emetra; then
        log_error "No se pudo crear configuracion de Nginx"
        return 1
    fi
    
    log_separator
    
    # Verificar configuracion
    if ! test_nginx_config; then
        log_error "La configuracion de Nginx tiene errores"
        return 1
    fi
    
    log_separator
    
    # Iniciar nginx
    if ! start_nginx; then
        log_error "No se pudo iniciar Nginx"
        return 1
    fi
    
    log_separator
    
    # Verificar que nginx esta corriendo
    if nginx_is_running; then
        log_success "Nginx esta corriendo correctamente"
    else
        log_error "Nginx no esta corriendo"
        return 1
    fi
    
    log_info ""
    log_section "Nginx Instalado y Configurado"
    log_info "Configuracion: ${NGINX_SITES_DIR}/emetra.muniguate.com.conf"
    log_info "URL: http://emetra.muniguate.com -> http://localhost:3002"
    log_info ""
    log_check "Comandos utiles:"
    log_info "  Ver estado: systemctl status nginx"
    log_info "  Reiniciar: systemctl restart nginx"
    log_info "  Ver logs: tail -f /var/log/nginx/emetra-error.log"
    log_info "  Verificar config: nginx -t"
    
    return 0
}

main "$@"

