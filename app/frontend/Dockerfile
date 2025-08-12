FROM node:20-slim AS build
WORKDIR /app
COPY package.json tsconfig.json ./
COPY public ./public
COPY src ./src
RUN npm install && npm run build

FROM nginx:1.20-alpine
COPY --from=build /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
