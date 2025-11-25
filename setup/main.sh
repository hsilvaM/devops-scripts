#!/bin/bash
# Script principal de instalacion del sistema
# Entrypoint que ejecuta todos los scripts de setup en orden

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../config"
FLAG_UPDOWN=false
FLAG_RESTART_APPS=false

# Cargar funciones comunes
if [ -f "${CONFIG_DIR}/common.sh" ]; then
    source "${CONFIG_DIR}/common.sh"
else
    echo "Error: No se encuentra common.sh"
    exit 1
fi

# Parsear argumentos
print_usage() {
    cat <<EOF
Uso: $(basename "$0") [opciones]

Opciones:
  --updown        Detener servicios existentes antes de volver a desplegar
  --restart-apps  Limpiar imagenes y reiniciar solo las aplicaciones (NextJS/PHP)
  -h, --help      Mostrar esta ayuda
EOF
}

for arg in "$@"; do
    case "$arg" in
        --updown)
            FLAG_UPDOWN=true
            ;;
        --restart-apps)
            FLAG_RESTART_APPS=true
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            log_warn "Argumento desconocido: ${arg}"
            ;;
    esac
done

if $FLAG_UPDOWN && $FLAG_RESTART_APPS; then
    log_warn "--updown se ignora porque se indicó --restart-apps"
    FLAG_UPDOWN=false
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

stop_service() {
    local dir="$1"
    local description="$2"

    if [ ! -d "$dir" ]; then
        log_warn "Directorio no encontrado para ${description}: $dir"
        return 0
    fi

    if [ ! -f "${dir}/docker-compose.yml" ]; then
        log_warn "docker-compose.yml no encontrado en ${dir} (saltando ${description})"
        return 0
    fi

    log_progress "Deteniendo ${description}..."
    (cd "$dir" && docker compose down --remove-orphans)
    if [ $? -eq 0 ]; then
        log_success "${description} detenido"
    else
        log_warn "No se pudo detener ${description} (continuando)"
    fi
}

stop_all_services() {
    log_section "Deteniendo servicios Docker existentes"
    stop_service "${SCRIPT_DIR}/../docker/jenkins" "Jenkins"
    stop_service "${SCRIPT_DIR}/../docker/prometheus" "Prometheus"
    stop_service "${SCRIPT_DIR}/../docker/grafana" "Grafana"
    stop_service "${SCRIPT_DIR}/../apps/nextjs" "NextJS"
    stop_service "${SCRIPT_DIR}/../apps/php" "PHP Oracle"
}

restart_apps() {
    log_section "Reinicio de aplicaciones (NextJS / PHP)"

    local services=(
        "NextJS Portal Emetra|apps/nextjs"
        "PHP Oracle|apps/php"
    )

    for entry in "${services[@]}"; do
        IFS='|' read -r label rel_dir <<< "${entry}"
        local full_dir="${SCRIPT_DIR}/../${rel_dir}"
        local compose_file="${full_dir}/docker-compose.yml"

        if [ ! -d "${full_dir}" ] || [ ! -f "${compose_file}" ]; then
            log_warn "No se encontró docker-compose para ${label} (${full_dir})"
            continue
        fi

        log_progress "Deteniendo ${label}..."
        (cd "${full_dir}" && docker compose down --remove-orphans)

        log_progress "Eliminando imagenes locales de ${label}..."
        (cd "${full_dir}" && docker compose down --rmi all --remove-orphans) >/dev/null 2>&1

        log_progress "Descargando imagenes base actualizadas de ${label}..."
        (cd "${full_dir}" && docker compose pull) >/dev/null 2>&1

        log_progress "Reconstruyendo contenedores de ${label}..."
        if (cd "${full_dir}" && docker compose build --pull --no-cache); then
            log_progress "Levantando ${label}..."
            if (cd "${full_dir}" && docker compose up -d); then
                log_success "${label} desplegado nuevamente"
            else
                log_error "No se pudo iniciar ${label}"
            fi
        else
            log_error "No se pudo reconstruir ${label}"
        fi

        log_separator
    done

    log_success "Proceso de reinicio de aplicaciones finalizado"
}

# Funcion principal
main() {
    log_section "Script de Configuracion del Sistema"
    log_info ""

    if $FLAG_RESTART_APPS; then
        restart_apps
        return 0
    fi
    
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

    if $FLAG_UPDOWN; then
        stop_all_services
        log_separator
    fi
    
    # Paso 3: Instalar Oracle Client (si existe el script)
    log_info "Paso 3: Verificando/Instalando Oracle Client..."
    run_setup_script "${SCRIPT_DIR}/03-oracle-client.sh"
    
    log_separator
    
    # Paso 4: Instalar Jenkins en Docker
    log_info "Paso 4: Instalando Jenkins en Docker..."
    run_setup_script "${SCRIPT_DIR}/../docker/jenkins/install.sh"
    
    log_separator
    
    # Paso 5: Configurar Firewall
    log_info "Paso 5: Configurando Firewall..."
    run_setup_script "${SCRIPT_DIR}/05-firewall.sh"
    
    log_separator
    
    # Paso 6: Instalar Prometheus
    log_info "Paso 6: Instalando Prometheus..."
    run_setup_script "${SCRIPT_DIR}/../docker/prometheus/install.sh"
    
    log_separator
    
    # Paso 7: Instalar Grafana
    log_info "Paso 7: Instalando Grafana..."
    run_setup_script "${SCRIPT_DIR}/../docker/grafana/install.sh"
    
    log_separator
    
    # Paso 8: Desplegar NextJS
    log_info "Paso 8: Desplegando NextJS..."
    run_setup_script "${SCRIPT_DIR}/../docker/apps/nextjs/install.sh"
    
    log_separator
    
    # Paso 9: Desplegar aplicacion PHP con Oracle (OCI8)
    log_info "Paso 9: Desplegando aplicacion PHP con Oracle..."
    run_setup_script "${SCRIPT_DIR}/../docker/apps/php/install.sh"
    
    log_separator
    
    # Paso 10: Instalar y configurar Nginx
    log_info "Paso 10: Instalando y configurando Nginx..."
    run_setup_script "${SCRIPT_DIR}/06-nginx.sh"
    
    log_info ""
    
    # Paso final: Verificar prerrequisitos finales
    log_section "Verificacion final de prerrequisitos"
    
    if run_setup_script "${SCRIPT_DIR}/01-prerequisites.sh"; then
        log_info ""
        log_section "Configuracion completada exitosamente"
        log_info ""
        log_info "=== URLs de Acceso ==="
        log_info "Jenkins:       http://localhost:8080/jenkins"
        log_info "Prometheus:    http://localhost:9090"
        log_info "Grafana:       http://localhost:3000 (admin/admin)"
        log_info "NextJS App:    http://localhost:3002"
        log_info "PHP Oracle App:http://localhost:3001/php"
        log_info "Emetra Portal: http://emetra.muniguate.com"
        log_info ""
        log_check "Verificar servicios corriendo:"
        log_info "docker ps"
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

