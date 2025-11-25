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

# Funcion para detectar version de RHEL/CentOS
get_rhel_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "rhel" ]] || [[ "$ID" == "centos" ]] || [[ "$ID" == "rocky" ]] || [[ "$ID" == "almalinux" ]]; then
            VERSION_ID=$(echo "$VERSION_ID" | cut -d. -f1)
            echo "$VERSION_ID"
            return 0
        fi
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
    
    # Intentar primero con yum/dnf
    if command_exists yum; then
        yum install -y epel-release 2>/dev/null
        if [ $? -eq 0 ]; then
            log_success "EPEL instalado correctamente"
            return 0
        fi
    elif command_exists dnf; then
        dnf install -y epel-release 2>/dev/null
        if [ $? -eq 0 ]; then
            log_success "EPEL instalado correctamente"
            return 0
        fi
    fi
    
    # Si falla, descargar e instalar el RPM directamente
    log_progress "Los repositorios no estan disponibles, descargando EPEL directamente..."
    
    local rhel_version=$(get_rhel_version)
    if [ -z "$rhel_version" ]; then
        log_error "No se pudo detectar la version de RHEL/CentOS"
        return 1
    fi
    
    local epel_url="https://dl.fedoraproject.org/pub/epel/epel-release-latest-${rhel_version}.noarch.rpm"
    local temp_rpm="/tmp/epel-release.rpm"
    
    log_progress "Descargando EPEL desde ${epel_url}..."
    
    if command_exists curl; then
        curl -L -o "${temp_rpm}" "${epel_url}" 2>/dev/null
    elif command_exists wget; then
        wget -O "${temp_rpm}" "${epel_url}" 2>/dev/null
    else
        log_error "No se encontro curl ni wget para descargar EPEL"
        return 1
    fi
    
    if [ $? -ne 0 ] || [ ! -f "${temp_rpm}" ]; then
        log_error "Error al descargar EPEL"
        return 1
    fi
    
    log_progress "Instalando EPEL desde RPM descargado..."
    if command_exists yum; then
        yum localinstall -y "${temp_rpm}" 2>/dev/null
    elif command_exists dnf; then
        dnf localinstall -y "${temp_rpm}" 2>/dev/null
    elif command_exists rpm; then
        rpm -ivh "${temp_rpm}" 2>/dev/null
    else
        log_error "No se encontro herramienta para instalar RPM"
        rm -f "${temp_rpm}"
        return 1
    fi
    
    rm -f "${temp_rpm}"
    
    if rpm -qa | grep -q epel-release; then
        log_success "EPEL instalado correctamente"
        log_progress "Actualizando cache de repositorios..."
        if command_exists yum; then
            yum clean all 2>/dev/null
            yum makecache 2>/dev/null
        elif command_exists dnf; then
            dnf clean all 2>/dev/null
            dnf makecache 2>/dev/null
        fi
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
        # Habilitar repositorios base si están deshabilitados
        log_progress "Habilitando repositorios base..."
        subscription-manager repos --enable=rhel-*-appstream-rpms 2>/dev/null || true
        subscription-manager repos --enable=rhel-*-baseos-rpms 2>/dev/null || true
        
        # Intentar habilitar CRB si existe el comando
        if command_exists crb; then
            log_progress "Habilitando repositorio CRB..."
            crb enable 2>/dev/null || true
        fi
        
        # Instalar EPEL si es necesario
        if ! install_epel; then
            log_warn "No se pudo instalar EPEL, continuando sin el..."
        fi
        
        log_progress "Buscando nginx en repositorios disponibles..."
        # Intentar desde AppStream primero (RHEL 9)
        if yum list available nginx 2>/dev/null | grep -q nginx; then
            log_progress "nginx encontrado en repositorios, instalando..."
            yum install -y nginx
        elif yum list available --enablerepo=epel nginx 2>/dev/null | grep -q nginx; then
            log_progress "nginx encontrado en EPEL, instalando..."
            yum install -y nginx --enablerepo=epel
        else
            log_warn "nginx no encontrado en repositorios, intentando instalacion desde AppStream..."
            yum install -y nginx --enablerepo='*' 2>/dev/null || yum install -y nginx
        fi
    elif command_exists dnf; then
        # Habilitar repositorios base si están deshabilitados
        log_progress "Habilitando repositorios base..."
        subscription-manager repos --enable=rhel-*-appstream-rpms 2>/dev/null || true
        subscription-manager repos --enable=rhel-*-baseos-rpms 2>/dev/null || true
        
        # Intentar habilitar CRB si existe el comando
        if command_exists crb; then
            log_progress "Habilitando repositorio CRB..."
            crb enable 2>/dev/null || true
        fi
        
        # Instalar EPEL si es necesario
        if ! install_epel; then
            log_warn "No se pudo instalar EPEL, continuando sin el..."
        fi
        
        log_progress "Buscando nginx en repositorios disponibles..."
        # Intentar desde AppStream primero (RHEL 9)
        if dnf list available nginx 2>/dev/null | grep -q nginx; then
            log_progress "nginx encontrado en repositorios, instalando..."
            dnf install -y nginx
        elif dnf list available --enablerepo=epel nginx 2>/dev/null | grep -q nginx; then
            log_progress "nginx encontrado en EPEL, instalando..."
            dnf install -y nginx --enablerepo=epel
        else
            log_warn "nginx no encontrado en repositorios, intentando instalacion desde AppStream..."
            dnf install -y nginx --enablerepo='*' 2>/dev/null || dnf install -y nginx
        fi
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
        log_warn "No se pudo instalar nginx desde repositorios"
        log_progress "Intentando instalar nginx desde codigo fuente..."
        
        # Instalar dependencias para compilar
        log_progress "Instalando dependencias de compilacion..."
        if command_exists yum; then
            yum groupinstall -y "Development Tools" 2>/dev/null || true
            # Instalar dependencias básicas
            yum install -y zlib-devel openssl-devel wget gcc make 2>/dev/null || true
        elif command_exists dnf; then
            dnf groupinstall -y "Development Tools" 2>/dev/null || true
            # Instalar dependencias básicas
            dnf install -y zlib-devel openssl-devel wget gcc make 2>/dev/null || true
        fi
        
        # Descargar PCRE y nginx
        local pcre_version="8.45"
        local nginx_version="1.24.0"
        local work_dir="/tmp/nginx-build"
        local pcre_dir="${work_dir}/pcre-${pcre_version}"
        local nginx_dir="${work_dir}/nginx-${nginx_version}"
        local pcre_tar="${work_dir}/pcre-${pcre_version}.tar.gz"
        local nginx_tar="${work_dir}/nginx-${nginx_version}.tar.gz"
        
        mkdir -p "${work_dir}"
        cd "${work_dir}"
        
        log_progress "Descargando PCRE ${pcre_version}..."
        if command_exists wget; then
            wget -O "${pcre_tar}" "https://downloads.sourceforge.net/project/pcre/pcre/${pcre_version}/pcre-${pcre_version}.tar.gz" 2>/dev/null || \
            wget -O "${pcre_tar}" "http://ftp.pcre.org/pub/pcre/pcre-${pcre_version}.tar.gz" 2>/dev/null
        elif command_exists curl; then
            curl -L -o "${pcre_tar}" "https://downloads.sourceforge.net/project/pcre/pcre/${pcre_version}/pcre-${pcre_version}.tar.gz" 2>/dev/null || \
            curl -L -o "${pcre_tar}" "http://ftp.pcre.org/pub/pcre/pcre-${pcre_version}.tar.gz" 2>/dev/null
        else
            log_error "No se encontro wget ni curl para descargar PCRE"
            return 1
        fi
        
        if [ ! -f "${pcre_tar}" ] || [ ! -s "${pcre_tar}" ]; then
            log_error "No se pudo descargar PCRE o el archivo esta vacio"
            return 1
        fi
        
        log_progress "Extrayendo PCRE..."
        tar -xzf "${pcre_tar}" || {
            log_error "Error al extraer PCRE"
            return 1
        }
        
        log_progress "Descargando nginx ${nginx_version}..."
        if command_exists wget; then
            wget -O "${nginx_tar}" "http://nginx.org/download/nginx-${nginx_version}.tar.gz" 2>/dev/null
        elif command_exists curl; then
            curl -L -o "${nginx_tar}" "http://nginx.org/download/nginx-${nginx_version}.tar.gz" 2>/dev/null
        else
            log_error "No se encontro wget ni curl para descargar nginx"
            return 1
        fi
        
        if [ ! -f "${nginx_tar}" ] || [ ! -s "${nginx_tar}" ]; then
            log_error "No se pudo descargar nginx o el archivo esta vacio"
            return 1
        fi
        
        log_progress "Extrayendo nginx..."
        tar -xzf "${nginx_tar}" || {
            log_error "Error al extraer nginx"
            return 1
        }
        
        cd "${nginx_dir}"
        
        log_progress "Configurando nginx con PCRE..."
        ./configure --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx --with-http_ssl_module --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_stub_status_module --with-http_auth_request_module --with-threads --with-stream --with-stream_ssl_module --with-stream_ssl_preread_module --with-stream_realip_module --with-http_slice_module --with-file-aio --with-http_v2_module --with-pcre="${pcre_dir}"
        
        if [ $? -ne 0 ]; then
            log_error "Error al configurar nginx"
            return 1
        fi
        
        make -j$(nproc)
        if [ $? -ne 0 ]; then
            log_error "Error al compilar nginx"
            return 1
        fi
        
        make install
        if [ $? -ne 0 ]; then
            log_error "Error al instalar nginx"
            return 1
        fi
        
        # Crear usuario nginx si no existe
        if ! id nginx &>/dev/null; then
            useradd -r -s /sbin/nologin nginx 2>/dev/null || true
        fi
        
        # Crear directorios y establecer permisos
        mkdir -p /var/log/nginx /var/cache/nginx /var/run /run
        chown -R nginx:nginx /var/log/nginx /var/cache/nginx 2>/dev/null || true
        chmod 755 /var/log/nginx /var/cache/nginx /run /var/run 2>/dev/null || true
        
        # Crear directorios necesarios
        mkdir -p /var/cache/nginx/client_temp /var/cache/nginx/proxy_temp /var/cache/nginx/fastcgi_temp /var/cache/nginx/uwsgi_temp /var/cache/nginx/scgi_temp
        chown -R nginx:nginx /var/cache/nginx
        
        # Limpiar
        cd /
        rm -rf "${work_dir}"
        
        log_success "Nginx compilado e instalado correctamente"
        return 0
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

# Funcion para verificar si el puerto 80 esta en uso
check_port_80() {
    if command_exists netstat; then
        if netstat -tuln | grep -q ":80 "; then
            log_warn "El puerto 80 esta en uso"
            netstat -tuln | grep ":80 " | head -3
            return 1
        fi
    elif command_exists ss; then
        if ss -tuln | grep -q ":80 "; then
            log_warn "El puerto 80 esta en uso"
            ss -tuln | grep ":80 " | head -3
            return 1
        fi
    fi
    return 0
}

# Funcion para crear nginx.conf si no existe
create_nginx_conf() {
    if [ -f "${NGINX_CONFIG_DIR}/nginx.conf" ]; then
        return 0
    fi
    
    log_progress "Creando configuracion principal de nginx..."
    
    cat > "${NGINX_CONFIG_DIR}/nginx.conf" << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    include /etc/nginx/conf.d/*.conf;
}
EOF

    log_success "Configuracion principal de nginx creada"
}

# Funcion para iniciar y habilitar nginx
start_nginx() {
    log_progress "Verificando puerto 80..."
    if ! check_port_80; then
        log_warn "El puerto 80 esta en uso. Verificando si nginx ya esta corriendo..."
        if systemctl is-active --quiet nginx; then
            log_success "Nginx ya esta corriendo"
            return 0
        else
            log_error "El puerto 80 esta en uso por otro proceso"
            log_info "Deteniendo proceso que usa el puerto 80..."
            if command_exists fuser; then
                fuser -k 80/tcp 2>/dev/null || true
                sleep 2
            fi
        fi
    fi
    
    log_progress "Verificando que el usuario nginx existe..."
    if ! id nginx &>/dev/null; then
        log_progress "Creando usuario nginx..."
        useradd -r -s /sbin/nologin -d /var/cache/nginx -c "nginx user" nginx 2>/dev/null || {
            log_error "No se pudo crear el usuario nginx"
            return 1
        }
    fi
    
    log_progress "Creando configuracion principal si no existe..."
    create_nginx_conf
    
    log_progress "Creando directorios necesarios..."
    mkdir -p /var/log/nginx /var/cache/nginx /var/run /run
    mkdir -p /etc/nginx/conf.d
    
    # Asegurar permisos correctos
    chown -R nginx:nginx /var/log/nginx /var/cache/nginx 2>/dev/null || true
    chmod 755 /var/log/nginx /var/cache/nginx 2>/dev/null || true
    
    # Limpiar archivos PID existentes que puedan causar problemas
    rm -f /run/nginx.pid /var/run/nginx.pid 2>/dev/null || true
    
    # Asegurar que /run tiene permisos correctos
    chmod 755 /run /var/run 2>/dev/null || true
    
    log_progress "Habilitando Nginx..."
    systemctl enable nginx
    
    log_progress "Deteniendo Nginx si esta corriendo..."
    systemctl stop nginx 2>/dev/null || true
    pkill -9 nginx 2>/dev/null || true
    sleep 2
    
    # Limpiar archivos PID y locks
    rm -f /run/nginx.pid /var/run/nginx.pid /var/run/nginx.lock /run/nginx.lock 2>/dev/null || true
    
    # Asegurar que nginx puede escribir en /run
    # En algunos sistemas, /run es tmpfs y necesita permisos específicos
    if [ -d "/run" ]; then
        chmod 1777 /run 2>/dev/null || chmod 755 /run 2>/dev/null || true
    fi
    
    log_progress "Iniciando Nginx..."
    # Intentar iniciar directamente primero para ver errores
    if /usr/sbin/nginx -t 2>&1; then
        systemctl start nginx
    else
        log_error "La configuracion de nginx tiene errores"
        /usr/sbin/nginx -t
        return 1
    fi
    
    # Esperar un momento y verificar
    sleep 2
    
    if systemctl is-active --quiet nginx; then
        log_success "Nginx iniciado correctamente"
        return 0
    else
        log_error "Error al iniciar Nginx"
        log_info "Verificando logs de nginx..."
        journalctl -u nginx.service --no-pager -n 20 2>/dev/null | tail -10 || true
        log_info "Verificando estado del servicio..."
        systemctl status nginx.service --no-pager -l 2>/dev/null | tail -15 || true
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

