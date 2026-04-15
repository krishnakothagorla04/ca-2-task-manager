# ---- Build Stage ----
FROM node:18-alpine

LABEL maintainer="CA2 Task Manager"
LABEL service="task-service"

WORKDIR /usr/src/app

# Install dependencies first (layer caching)
COPY package*.json ./
RUN npm install --omit=dev

# Copy application code
COPY . .

EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -qO- http://localhost:3001/health || exit 1

CMD ["npm", "start"]
