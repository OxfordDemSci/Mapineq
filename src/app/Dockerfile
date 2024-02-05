FROM node:18-alpine as node
WORKDIR /app
COPY . .
RUN npm install

RUN npm run build --prod
# Stage 2
FROM nginx:alpine
COPY --from=node /app/dist/app/browser /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
