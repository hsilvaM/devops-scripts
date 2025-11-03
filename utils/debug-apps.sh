#!/bin/bash
# Script para debuggear problemas con las apps

echo "=== Estado de contenedores ==="
docker ps -a | grep -E "(nextjs|nestjs)"

echo ""
echo "=== Logs de NextJS (ultimas 50 lineas) ==="
docker logs nextjs-app --tail 50 2>&1 || echo "Contenedor no existe"

echo ""
echo "=== Logs de NestJS (ultimas 50 lineas) ==="
docker logs nestjs-app --tail 50 2>&1 || echo "Contenedor no existe"

echo ""
echo "=== Redes Docker ==="
docker network ls | grep -E "(apps-net|monitoring-net|jenkins-net)"

echo ""
echo "=== Verificar puertos ==="
netstat -tuln | grep -E "(3001|3002)" || ss -tuln | grep -E "(3001|3002)"
