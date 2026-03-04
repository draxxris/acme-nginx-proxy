FROM nginx:alpine

# Install dependencies
RUN apk add --no-cache \
    curl \
    openssl \
    socat \
    dcron \
    bash \
    unzip

ENV ZIPFILE=https://github.com/acmesh-official/acme.sh/archive/refs/heads/master.zip
# Download acme.sh (install will run in entrypoint with correct email)
RUN curl -Lo /tmp/acme.zip $ZIPFILE && \
    cd /tmp && \
    unzip acme.zip

# Create directory for nginx templates
RUN mkdir -p /etc/nginx/templates

# Copy nginx configuration template
COPY nginx.conf.template /etc/nginx/templates/nginx.conf.template

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose ports
EXPOSE 443

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
