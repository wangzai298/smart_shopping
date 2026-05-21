FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json tsconfig.json ./
RUN npm ci
COPY src/ ./src/
RUN npx tsc

FROM node:18-alpine AS runner
WORKDIR /app
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/dist/ ./dist/
RUN npm ci --omit=dev
EXPOSE 3000
CMD ["node", "dist/main.js"]
