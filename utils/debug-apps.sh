#!/bin/bash
# Script para debuggear problemas con las apps

echo "=== Estado de contenedores ==="
docker ps -a | grep -E "(portal-emetra|nextjs)" || echo "No hay contenedores NextJS activos"

echo ""
echo "=== Logs de NextJS (ultimas 50 lineas) ==="
docker logs portal-emetra-app --tail 50 2>&1 || echo "Contenedor no existe"

echo ""
echo "=== Redes Docker ==="
docker network ls | grep -E "(apps-net|monitoring-net|jenkins-net)"

echo ""
echo "=== Verificar puertos ==="
netstat -tuln | grep -E "(3002)" || ss -tuln | grep -E "(3002)"
