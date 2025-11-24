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

# Funcion para crear directorio de fotos
create_fotos_directory() {
    log_config "Configurando directorio de fotos..."
    
    local FOTOS_DIR="/var/www/html/fotos"
    
    if [ ! -d "$FOTOS_DIR" ]; then
        log_progress "Creando directorio $FOTOS_DIR..."
        mkdir -p "$FOTOS_DIR"
        if [ $? -eq 0 ]; then
            log_success "Directorio $FOTOS_DIR creado"
        else
            log_error "No se pudo crear el directorio $FOTOS_DIR"
            return 1
        fi
    else
        log_check "Directorio $FOTOS_DIR ya existe"
    fi
    
    # Establecer permisos apropiados
    chown -R nginx:nginx "$FOTOS_DIR" 2>/dev/null || chown -R www-data:www-data "$FOTOS_DIR" 2>/dev/null
    chmod -R 755 "$FOTOS_DIR"
    
    log_success "Permisos configurados para $FOTOS_DIR"
    return 0
}

# Funcion para configurar Nginx para servir fotos en puerto 3002
configure_nginx_fotos() {
    log_config "Configurando Nginx para servir fotos en puerto 3002..."
    
    local NGINX_CONF="/etc/nginx/conf.d/fotos.conf"
    
    # Crear directorio de fotos primero
    if ! create_fotos_directory; then
        log_error "No se pudo crear el directorio de fotos"
        return 1
    fi
    
    # Crear archivo de configuracion
    log_progress "Creando configuracion de Nginx en $NGINX_CONF..."
    
    cat > "$NGINX_CONF" << 'NGINX_EOF'
server {
    listen 3002;
    server_name localhost;
    
    root /var/www/html;
    index index.html index.htm;
    
    # Configuracion para servir fotos
    location /fotos {
        alias /var/www/html/fotos;
        autoindex on;
        autoindex_exact_size off;
        autoindex_localtime on;
        
        # Permitir acceso a archivos de imagen
        location ~* \.(jpg|jpeg|png|gif|ico|svg|webp|bmp)$ {
            expires 30d;
            add_header Cache-Control "public, immutable";
            access_log off;
        }
        
        # Denegar acceso a archivos ocultos
        location ~ /\. {
            deny all;
            access_log off;
            log_not_found off;
        }
    }
    
    # Pagina de error personalizada (opcional)
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
    
    # Logs
    access_log /var/log/nginx/fotos_access.log;
    error_log /var/log/nginx/fotos_error.log;
}
NGINX_EOF
    
    if [ $? -eq 0 ]; then
        log_success "Configuracion de Nginx creada en $NGINX_CONF"
    else
        log_error "No se pudo crear la configuracion de Nginx"
        return 1
    fi
    
    # Verificar que el puerto 3002 no este en uso por otro servicio
    if netstat -tlnp 2>/dev/null | grep -q ":3002 " || ss -tlnp 2>/dev/null | grep -q ":3002 "; then
        local PID=$(netstat -tlnp 2>/dev/null | grep ":3002 " | awk '{print $7}' | cut -d'/' -f1 | head -1)
        if [ -n "$PID" ] && [ "$PID" != "-" ]; then
            log_warn "El puerto 3002 esta en uso por el proceso PID: $PID"
            log_warn "Verifica que no haya conflictos antes de continuar"
        fi
    fi
    
    return 0
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
        nginx -t
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
    log_info "  Configuracion de fotos: /etc/nginx/conf.d/fotos.conf"
    log_info "  Directorio web por defecto: /usr/share/nginx/html"
    log_info "  Directorio de fotos: /var/www/html/fotos"
    log_info "  Logs de acceso: /var/log/nginx/access.log"
    log_info "  Logs de error: /var/log/nginx/error.log"
    log_info "  Logs de fotos: /var/log/nginx/fotos_*.log"
    log_info ""
    log_info "Acceso a fotos:"
    log_info "  URL base: http://localhost:3002/fotos"
    log_info "  Ejemplo: http://localhost:3002/fotos/bulevar_vista/foto1.png"
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
    
    # Configurar Nginx para servir fotos
    if ! configure_nginx_fotos; then
        log_error "No se pudo configurar Nginx para servir fotos"
        exit 1
    fi
    
    log_info ""
    
    # Verificar configuracion
    if ! verify_nginx_config; then
        log_error "La configuracion de Nginx tiene errores. Revisa los detalles arriba."
        exit 1
    fi
    
    log_info ""
    
    # Recargar Nginx para aplicar cambios
    log_progress "Recargando Nginx para aplicar la nueva configuracion..."
    systemctl reload nginx
    if [ $? -eq 0 ]; then
        log_success "Nginx recargado exitosamente"
    else
        log_warn "No se pudo recargar Nginx automaticamente"
        log_info "Ejecuta manualmente: systemctl reload nginx"
    fi
    
    log_info ""
    
    # Mostrar informacion
    show_nginx_info
    
    log_success "Instalacion de Nginx completada"
    return 0
}

# Ejecutar funcion principal
main "$@"

# ============================================================================
# APENDICE: Configuracion de Nginx para servir fotos
# ============================================================================
#
# Este script crea automaticamente el archivo /etc/nginx/conf.d/fotos.conf
# con la siguiente configuracion:
#
# ----------------------------------------------------------------------------
# /etc/nginx/conf.d/fotos.conf
# ----------------------------------------------------------------------------
#
# server {
#     listen 3002;
#     server_name localhost;
#     
#     root /var/www/html;
#     index index.html index.htm;
#     
#     # Configuracion para servir fotos
#     location /fotos {
#         alias /var/www/html/fotos;
#         autoindex on;
#         autoindex_exact_size off;
#         autoindex_localtime on;
#         
#         # Permitir acceso a archivos de imagen
#         location ~* \.(jpg|jpeg|png|gif|ico|svg|webp|bmp)$ {
#             expires 30d;
#             add_header Cache-Control "public, immutable";
#             access_log off;
#         }
#         
#         # Denegar acceso a archivos ocultos
#         location ~ /\. {
#             deny all;
#             access_log off;
#             log_not_found off;
#         }
#     }
#     
#     # Pagina de error personalizada (opcional)
#     error_page 404 /404.html;
#     error_page 500 502 503 504 /50x.html;
#     
#     # Logs
#     access_log /var/log/nginx/fotos_access.log;
#     error_log /var/log/nginx/fotos_error.log;
# }
#
# ----------------------------------------------------------------------------
# Estructura de directorios
# ----------------------------------------------------------------------------
#
# /var/www/html/fotos/
#   ├── bulevar_vista/
#   │   ├── foto1.png
#   │   ├── foto2.jpg
#   │   └── ...
#   ├── otra_carpeta/
#   │   └── ...
#   └── ...
#
# ----------------------------------------------------------------------------
# Ejemplos de acceso
# ----------------------------------------------------------------------------
#
# URL base:              http://localhost:3002/fotos
# Listado de carpetas:   http://localhost:3002/fotos/
# Imagen especifica:     http://localhost:3002/fotos/bulevar_vista/foto1.png
# Otra imagen:           http://localhost:3002/fotos/otra_carpeta/imagen.jpg
#
# ----------------------------------------------------------------------------
# Permisos y propietario
# ----------------------------------------------------------------------------
#
# El directorio /var/www/html/fotos se crea con:
#   - Propietario: nginx:nginx (o www-data:www-data segun la distribucion)
#   - Permisos: 755 (rwxr-xr-x)
#
# Para agregar nuevas fotos:
#   sudo cp foto.png /var/www/html/fotos/bulevar_vista/
#   sudo chown nginx:nginx /var/www/html/fotos/bulevar_vista/foto.png
#
# ----------------------------------------------------------------------------
# Comandos utiles
# ----------------------------------------------------------------------------
#
# Verificar configuracion:
#   sudo nginx -t
#
# Recargar configuracion (sin downtime):
#   sudo systemctl reload nginx
#
# Reiniciar servicio:
#   sudo systemctl restart nginx
#
# Ver logs de acceso:
#   sudo tail -f /var/log/nginx/fotos_access.log
#
# Ver logs de error:
#   sudo tail -f /var/log/nginx/fotos_error.log
#
# Verificar que el puerto 3002 este escuchando:
#   sudo netstat -tlnp | grep 3002
#   sudo ss -tlnp | grep 3002
#
# ----------------------------------------------------------------------------
# Notas importantes
# ----------------------------------------------------------------------------
#
# 1. El puerto 3002 debe estar abierto en el firewall si se accede desde
#    fuera del servidor. Usa el script de firewall para abrirlo:
#    tcp:3002|Nginx Fotos
#
# 2. Si necesitas cambiar el puerto, edita /etc/nginx/conf.d/fotos.conf
#    y cambia "listen 3002;" por el puerto deseado, luego recarga nginx.
#
# 3. El autoindex permite listar el contenido de los directorios. Si no
#    quieres esto por seguridad, cambia "autoindex on;" a "autoindex off;"
#
# 4. Las imagenes tienen cache de 30 dias. Ajusta "expires 30d;" si necesitas
#    un tiempo diferente.
#
# ============================================================================

