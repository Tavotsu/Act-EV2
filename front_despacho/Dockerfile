# Stage 1: Build the Vite application
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Stage 2: Serve the application with Nginx
FROM nginxinc/nginx-unprivileged:alpine
# Copy the Nginx template to be processed by entrypoint
COPY default.conf.template /etc/nginx/templates/default.conf.template
# Copy the build output
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
