FROM node:18-alpine AS node
WORKDIR /app
COPY . .
RUN npm install
RUN node update_app_version_and_build.js
RUN npm run build --prod
# Stage 2
FROM nginx:alpine
COPY --from=node /app/dist/app/browser /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
