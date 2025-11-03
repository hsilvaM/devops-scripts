# Scripts de Configuracion DevOps

Estructura de scripts para configurar y desplegar infraestructura en servidor RHEL on-premise.

## Estructura

- `config/` - Configuraciones compartidas y variables de entorno
- `setup/` - Scripts de instalacion inicial del sistema
- `docker/` - Gestion de Docker (redes, volumenes, imagenes)
- `firewall/` - Configuracion de firewall (firewalld) en RHEL
- `jenkins/` - Instalacion y configuracion de Jenkins
- `database/` - Configuracion de base de datos Oracle
- `apps/` - Aplicaciones NextJS y NestJS
- `monitoring/` - Prometheus y Grafana
- `offline/` - Scripts para preparar bundles offline
- `utils/` - Utilidades reutilizables
- `deploy/` - Scripts de orquestacion de despliegue

