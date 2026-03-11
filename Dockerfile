FROM node:24-alpine

WORKDIR /app

ENV NODE_ENV=production

# Build from repository root but install backend dependencies only.
COPY tutoreverywhere_backend/package*.json ./
RUN npm ci --omit=dev

COPY tutoreverywhere_backend ./

EXPOSE 3000

CMD ["npm", "run", "run"]
