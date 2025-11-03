# Dockerfile para NestJS
FROM node:20-alpine

# Instalar pnpm globalmente
RUN npm install -g pnpm

WORKDIR /app

# Copiar package.json y pnpm-lock.yaml primero para cachear layers
COPY package.json pnpm-lock.yaml ./

# Instalar dependencias
RUN pnpm install --frozen-lockfile

# Copiar el resto de la aplicacion
COPY . .

# Build de la aplicacion
RUN pnpm run build

EXPOSE 3001

CMD ["pnpm", "run", "start:prod"]