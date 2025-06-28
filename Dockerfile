# Use a lightweight Nginx image as the base
FROM nginx:alpine

# Copy all files from the current directory into the container
COPY . /usr/share/nginx/html

# Expose port 80 (the default Nginx port) inside the container
EXPOSE 80
