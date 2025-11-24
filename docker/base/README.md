# Oracle Instant Client Base Images

Estos Dockerfiles permiten construir imágenes base que ya incluyen Oracle Instant Client.
Utiliza estas imágenes como `FROM` en las aplicaciones (NestJS, PHP) para evitar
instalaciones durante el despliegue en servidores sin acceso a Internet.

## Preparación de archivos

1. Descarga desde Oracle los archivos ZIP:
   - `instantclient-basic-linux.x64-12.2.0.1.0.zip`
   - `instantclient-sdk-linux.x64-12.2.0.1.0.zip`

2. Copia ambos ZIP en:
   - `docker/base/oracle-node/instantclient/`
   - `docker/base/oracle-php/instantclient/`

> **Nota:** Estos archivos **no deben** versionarse en Git. Añádeles reglas en `.gitignore`
> si aún no están excluidos.

## Construcción de imágenes localmente

Desde la raíz del repositorio:

```bash
# Imagen base para aplicaciones Node/NestJS
docker build \
  -f docker/base/oracle-node/Dockerfile \
  --build-arg BASIC_ZIP=instantclient-basic-linux.x64-12.2.0.1.0.zip \
  --build-arg SDK_ZIP=instantclient-sdk-linux.x64-12.2.0.1.0.zip \
  -t hsilv/oracle-node-base:latest .

# Imagen base para aplicaciones PHP/Apache
docker build \
  -f docker/base/oracle-php/Dockerfile \
  --build-arg BASIC_ZIP=instantclient-basic-linux.x64-12.2.0.1.0.zip \
  --build-arg SDK_ZIP=instantclient-sdk-linux.x64-12.2.0.1.0.zip \
  -t hsilv/oracle-php-base:latest .
```

Una vez generadas, súbelas a tu registro (ej. Docker Hub):

```bash
# Autenticarse en Docker Hub (si no lo has hecho)
docker login

# Subir imágenes
docker push hsilv/oracle-node-base:latest
docker push hsilv/oracle-php-base:latest
```

## Uso en los proyectos

En los Dockerfiles de las aplicaciones:

- NestJS: reemplaza la primera línea por `FROM <usuario>/oracle-node-base:latest`
- PHP: usa `FROM <usuario>/oracle-php-base:latest`

Esto eliminará la necesidad de ejecutar `apt-get` o copiar nuevamente los ZIP en
los Dockerfiles finales.

## Importar imágenes en servidores sin Internet

En el servidor de destino:

```bash
# Copia los tar.gz previamente exportados
gunzip -c oracle-node-base.tar.gz | docker load
gunzip -c oracle-php-base.tar.gz  | docker load
```

Así, los despliegues (`docker compose up`, `setup/main.sh`) utilizarán las imágenes
pre-cargadas sin descargar dependencias desde Internet.

