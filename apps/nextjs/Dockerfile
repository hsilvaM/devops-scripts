# Dockerfile para NextJS
FROM node:20-alpine

WORKDIR /app

# Copiar package.json y package-lock.json primero para cachear layers
COPY my-app/package*.json ./

# Instalar dependencias (incluye dev dependencies necesarias para build)
RUN npm ci

# Copiar el resto de la aplicacion
COPY my-app/ .

# Build de la aplicacion
RUN npm run build

EXPOSE 3000

CMD ["npm", "run", "start"]