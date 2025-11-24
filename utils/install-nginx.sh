#!/bin/bash
# Script de instalacion de Nginx en el servidor RHEL

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

# Funcion para verificar si Nginx esta instalado
nginx_is_installed() {
    if command_exists nginx; then
        NGINX_VERSION=$(nginx -v 2>&1 | grep -oP 'nginx/\K[0-9.]+' || echo "unknown")
        if [ $? -eq 0 ]; then
            return 0
        fi
    fi
    return 1
}

# Funcion para verificar si el servicio de Nginx esta corriendo
nginx_service_running() {
    if systemctl is-active --quiet nginx; then
        return 0
    fi
    return 1
}

# Funcion para verificar si el servicio de Nginx esta habilitado
nginx_service_enabled() {
    if systemctl is-enabled --quiet nginx; then
        return 0
    fi
    return 1
}

# Funcion para instalar Nginx
install_nginx() {
    log_install "Instalando Nginx..."
    
    # Verificar gestor de paquetes disponible
    if command_exists dnf; then
        PACKAGE_MANAGER="dnf"
    elif command_exists yum; then
        PACKAGE_MANAGER="yum"
    else
        log_error "No se encuentra dnf ni yum. Este script requiere RHEL/AlmaLinux/CentOS"
        exit 1
    fi
    
    log_config "Usando $PACKAGE_MANAGER para instalar Nginx..."
    
    $PACKAGE_MANAGER install -y nginx
    
    if [ $? -ne 0 ]; then
        log_error "Error al instalar Nginx"
        return 1
    fi
    
    return 0
}

# Funcion para configurar el servicio de Nginx
configure_nginx_service() {
    log_config "Configurando servicio de Nginx..."
    
    # Habilitar servicio para que inicie al arrancar el sistema
    if ! nginx_service_enabled; then
        log_progress "Habilitando servicio Nginx para inicio automatico..."
        systemctl enable nginx
        if [ $? -eq 0 ]; then
            log_success "Servicio Nginx habilitado para inicio automatico"
        else
            log_warn "No se pudo habilitar el servicio Nginx"
        fi
    else
        log_check "Servicio Nginx ya esta habilitado"
    fi
    
    # Iniciar servicio si no esta corriendo
    if ! nginx_service_running; then
        log_progress "Iniciando servicio Nginx..."
        systemctl start nginx
        if [ $? -eq 0 ]; then
            log_success "Servicio Nginx iniciado"
        else
            log_error "No se pudo iniciar el servicio Nginx"
            return 1
        fi
    else
        log_check "Servicio Nginx ya esta corriendo"
    fi
}

# Funcion para verificar la configuracion de Nginx
verify_nginx_config() {
    log_check "Verificando configuracion de Nginx..."
    
    if nginx -t >/dev/null 2>&1; then
        log_success "Configuracion de Nginx es valida"
        return 0
    else
        log_error "Configuracion de Nginx tiene errores"
        log_info "Ejecuta 'nginx -t' para ver los detalles"
        return 1
    fi
}

# Funcion para mostrar informacion de Nginx
show_nginx_info() {
    log_section "Informacion de Nginx"
    
    if nginx_is_installed; then
        NGINX_VERSION=$(nginx -v 2>&1 | grep -oP 'nginx/\K[0-9.]+' || echo "unknown")
        log_info "Version: $NGINX_VERSION"
    fi
    
    if nginx_service_running; then
        log_success "Estado: CORRIENDO"
        
        # Mostrar puertos en uso
        log_info "Puertos en uso:"
        netstat -tlnp 2>/dev/null | grep nginx | awk '{print "  " $4}' || \
        ss -tlnp 2>/dev/null | grep nginx | awk '{print "  " $4}' || \
        log_info "  (No se pudo obtener informacion de puertos)"
    else
        log_warn "Estado: DETENIDO"
    fi
    
    if nginx_service_enabled; then
        log_success "Inicio automatico: HABILITADO"
    else
        log_warn "Inicio automatico: DESHABILITADO"
    fi
    
    log_info ""
    log_info "Ubicaciones importantes:"
    log_info "  Configuracion principal: /etc/nginx/nginx.conf"
    log_info "  Configuracion de sitios: /etc/nginx/conf.d/"
    log_info "  Directorio web por defecto: /usr/share/nginx/html"
    log_info "  Logs de acceso: /var/log/nginx/access.log"
    log_info "  Logs de error: /var/log/nginx/error.log"
    log_info ""
    log_info "Comandos utiles:"
    log_info "  Verificar config: nginx -t"
    log_info "  Recargar config: systemctl reload nginx"
    log_info "  Reiniciar servicio: systemctl restart nginx"
    log_info "  Ver estado: systemctl status nginx"
}

# Funcion principal
main() {
    log_section "Instalacion de Nginx"
    
    # Verificar si Nginx ya esta instalado
    if nginx_is_installed; then
        NGINX_VERSION=$(nginx -v 2>&1 | grep -oP 'nginx/\K[0-9.]+' || echo "unknown")
        log_success "Nginx ya esta instalado: version $NGINX_VERSION"
    else
        log_warn "Nginx no esta instalado"
        log_install "Instalando Nginx..."
        
        if ! install_nginx; then
            log_error "No se pudo instalar Nginx"
            exit 1
        fi
        
        log_success "Nginx instalado exitosamente"
    fi
    
    log_info ""
    
    # Configurar y arrancar el servicio
    if ! configure_nginx_service; then
        log_error "No se pudo configurar el servicio de Nginx"
        exit 1
    fi
    
    log_info ""
    
    # Verificar configuracion
    verify_nginx_config
    
    log_info ""
    
    # Mostrar informacion
    show_nginx_info
    
    log_success "Instalacion de Nginx completada"
    return 0
}

# Ejecutar funcion principal
main "$@"

