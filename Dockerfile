# Imagen de Cloud Run: API de catálogo + landing estática (web/) en el mismo servicio.
FROM node:22-alpine
ENV NODE_ENV=production STATIC_DIR=/app/web
WORKDIR /app
COPY api/package.json ./
COPY api/src ./src
COPY web ./web
USER node
EXPOSE 8080
CMD ["node", "src/server.js"]
