FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .

FROM node:20-alpine
RUN addgroup -g 1001 -S sentinel && adduser -u 1001 -S sentinel -G sentinel
WORKDIR /app
COPY --from=build /app .
USER 1001
EXPOSE 3000
CMD ["node", "index.js"]