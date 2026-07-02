# ─────────────────────────────────────────────────────────────
#  NotiqAI Landing — DEV server (vite, hot reload)
# ─────────────────────────────────────────────────────────────

FROM node:22-alpine
WORKDIR /app

COPY package*.json ./
RUN npm install --no-audit --no-fund

COPY . .

EXPOSE 5175
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
