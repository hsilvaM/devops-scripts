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

# Configurar pnpm para usar shamefully-hoist (estructura tradicional de node_modules)
# Esto es necesario para que TypeScript pueda encontrar los modulos
RUN echo "shamefully-hoist=true" > .npmrc && \
    echo "node-linker=hoisted" >> .npmrc

# Instalar dependencias (incluye dev dependencies necesarias para build)
RUN pnpm install --prefer-frozen-lockfile || pnpm install --no-frozen-lockfile

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

# Forzar configuracion de pnpm para usar estructura hoisted
# Esto asegura que los modulos esten disponibles directamente en node_modules/
# incluso si el proyecto tiene su propio .npmrc
RUN echo "shamefully-hoist=true" > .npmrc && \
    echo "node-linker=hoisted" >> .npmrc && \
    echo "Configuracion de pnpm aplicada:" && \
    cat .npmrc

# Reinstalar dependencias si es necesario (por si acaso se perdieron al copiar)
# Forzar reinstalacion completa para asegurar que todo este disponible
RUN echo "Reinstalando dependencias despues de copiar codigo..." && \
    pnpm install --prefer-frozen-lockfile || pnpm install --no-frozen-lockfile

# Verificar que las dependencias estan disponibles usando pnpm list
# Esto es mas confiable que verificar directorios ya que pnpm usa estructura diferente
RUN echo "Verificando que react y next estan instalados..." && \
    pnpm list react next 2>&1 | grep -E "(react|next)@[0-9]" || { \
        echo "ERROR: react o next no encontrados en las dependencias instaladas"; \
        echo "Listando todas las dependencias:"; \
        pnpm list --depth=0 2>&1 | head -30; \
        exit 1; \
    } && \
    echo "Dependencias verificadas correctamente"

# Build de la aplicacion
RUN pnpm run build

EXPOSE 3000

# Usar NODE_ENV production pero mantener npm
ENV NODE_ENV=production

CMD ["pnpm", "run", "start"]