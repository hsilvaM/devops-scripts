#!/bin/bash
# Script para debuggear problemas con las apps

echo "=== Estado de contenedores ==="
docker ps -a | grep -E "(nestjs-api-portal|php-oracle-app)" || echo "No hay contenedores de aplicaciones activos"

echo ""
echo "=== Logs de NestJS (ultimas 50 lineas) ==="
docker logs nestjs-api-portal --tail 50 2>&1 || echo "Contenedor no existe"

echo ""
echo "=== Logs de PHP (ultimas 50 lineas) ==="
docker logs php-oracle-app --tail 50 2>&1 || echo "Contenedor no existe"

echo ""
echo "=== Redes Docker ==="
docker network ls | grep -E "(apps-net|monitoring-net|jenkins-net)"

echo ""
echo "=== Verificar puertos ==="
netstat -tuln | grep -E "(3001|3003)" || ss -tuln | grep -E "(3001|3003)"
