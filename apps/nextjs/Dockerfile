# Dockerfile para NextJS Portal Emetra
FROM node:20-bullseye-slim

WORKDIR /app

# Habilitar pnpm via corepack
ENV PNPM_HOME=/usr/local/share/pnpm
ENV PATH="${PNPM_HOME}:${PATH}"
RUN corepack enable && corepack prepare pnpm@10.11.0 --activate

# Copiar archivos de dependencias primero para cachear layers
COPY pnpm-lock.yaml* ./
COPY package.json ./

# Instalar dependencias (incluye dev dependencies necesarias para build)
# Usar shamefully-hoist para compatibilidad con TypeScript y herramientas que esperan node_modules tradicional
RUN pnpm install --prefer-frozen-lockfile --shamefully-hoist || pnpm install --no-frozen-lockfile --shamefully-hoist

# Verificar que las dependencias se instalaron correctamente
RUN if [ ! -d "node_modules" ]; then \
        echo "ERROR: node_modules no existe despues de pnpm install"; \
        exit 1; \
    fi && \
    echo "Verificando instalacion de dependencias..." && \
    (pnpm list react next 2>&1 | head -10 || echo "No se pudo verificar lista de paquetes") && \
    echo "Dependencias instaladas"

# Copiar el resto de la aplicacion (excluyendo node_modules para no sobrescribir)
COPY . .

# Reinstalar dependencias si es necesario (por si acaso se perdieron al copiar)
RUN if [ ! -d "node_modules/react" ] && [ ! -L "node_modules/react" ]; then \
        echo "Reinstalando dependencias..." && \
        pnpm install --prefer-frozen-lockfile --shamefully-hoist || pnpm install --no-frozen-lockfile --shamefully-hoist; \
    fi

# Verificar que react y next estan disponibles antes del build
RUN if [ ! -d "node_modules/react" ] && [ ! -L "node_modules/react" ]; then \
        echo "ERROR: react no encontrado en node_modules"; \
        echo "Contenido de node_modules:"; \
        ls -la node_modules/ | head -20; \
        exit 1; \
    fi && \
    if [ ! -d "node_modules/next" ] && [ ! -L "node_modules/next" ]; then \
        echo "ERROR: next no encontrado en node_modules"; \
        exit 1; \
    fi && \
    echo "Dependencias verificadas correctamente"

# Build de la aplicacion
RUN pnpm run build

EXPOSE 3000

# Usar NODE_ENV production pero mantener npm
ENV NODE_ENV=production

CMD ["pnpm", "run", "start"]