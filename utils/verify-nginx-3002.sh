#!/bin/bash
# Script para verificar que nginx este escuchando en puerto 3002

echo "=== Verificacion de Nginx en Puerto 3002 ==="
echo ""

# Verificar si nginx esta corriendo
if systemctl is-active --quiet nginx; then
    echo "[OK] Nginx esta corriendo"
else
    echo "[ERROR] Nginx NO esta corriendo"
    exit 1
fi

echo ""

# Verificar puerto 3002
echo "=== Verificando puerto 3002 ==="
if command_exists ss; then
    echo "Usando 'ss' para verificar puertos:"
    ss -tlnp | grep ":3002 " || echo "[WARN] Puerto 3002 no encontrado con ss"
elif command_exists netstat; then
    echo "Usando 'netstat' para verificar puertos:"
    netstat -tlnp | grep ":3002 " || echo "[WARN] Puerto 3002 no encontrado con netstat"
else
    echo "[ERROR] No se encuentra ss ni netstat"
fi

echo ""

# Verificar configuracion
echo "=== Verificando configuracion ==="
if [ -f "/etc/nginx/conf.d/fotos.conf" ]; then
    echo "[OK] Archivo de configuracion existe: /etc/nginx/conf.d/fotos.conf"
    echo ""
    echo "Contenido del archivo:"
    echo "----------------------------------------"
    cat /etc/nginx/conf.d/fotos.conf
    echo "----------------------------------------"
else
    echo "[ERROR] Archivo de configuracion NO existe: /etc/nginx/conf.d/fotos.conf"
fi

echo ""

# Verificar sintaxis de nginx
echo "=== Verificando sintaxis de nginx ==="
nginx -t

echo ""

# Verificar logs de error recientes
echo "=== Ultimas lineas del log de error ==="
if [ -f "/var/log/nginx/error.log" ]; then
    tail -20 /var/log/nginx/error.log
else
    echo "[WARN] Log de error no encontrado"
fi

echo ""

# Verificar directorio de fotos
echo "=== Verificando directorio de fotos ==="
if [ -d "/var/www/html/fotos" ]; then
    echo "[OK] Directorio existe: /var/www/html/fotos"
    echo "Permisos:"
    ls -ld /var/www/html/fotos
    echo ""
    echo "Contenido:"
    ls -la /var/www/html/fotos | head -10
else
    echo "[ERROR] Directorio NO existe: /var/www/html/fotos"
fi

echo ""

# Intentar conexion de prueba
echo "=== Prueba de conexion ==="
if command_exists curl; then
    echo "Probando conexion a http://localhost:3002/fotos..."
    curl -I http://localhost:3002/fotos 2>&1 | head -5
elif command_exists wget; then
    echo "Probando conexion a http://localhost:3002/fotos..."
    wget --spider -S http://localhost:3002/fotos 2>&1 | head -5
else
    echo "[INFO] curl y wget no disponibles para prueba de conexion"
fi

echo ""
echo "=== Resumen ==="
echo "Para verificar manualmente:"
echo "  - Ver puertos: ss -tlnp | grep 3002"
echo "  - Ver logs: tail -f /var/log/nginx/error.log"
echo "  - Reiniciar: systemctl restart nginx"
echo "  - Probar URL: curl http://localhost:3002/fotos"



