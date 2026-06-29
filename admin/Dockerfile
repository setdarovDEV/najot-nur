FROM node:22-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 5173

# Dev server (compose overrides with --host). For production use `npm run build`
# and serve `dist/` via nginx.
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
