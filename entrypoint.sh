#!/bin/sh

set -e

# Validate required environment variables
if [ -z "$DOMAINS" ]; then
    echo "ERROR: DOMAINS environment variable is required"
    exit 1
fi

if [ -z "$BACKEND" ]; then
    echo "ERROR: BACKEND environment variable is required"
    exit 1
fi

if [ -z "$ACME_EMAIL" ]; then
    echo "ERROR: ACME_EMAIL environment variable is required"
    exit 1
fi

if [ -z "$LISTEN" ]; then
    export LISTEN=443
fi

if [ -z "$RESOLVER" ]; then
    export RESOLVER=127.0.0.11
fi

if [ -z "$ACME_DNSAPI" ]; then
    export ACME_DNSAPI=dns_he
fi

# Install acme.sh if not already installed
if [ ! -f "/root/.acme.sh/acme.sh" ]; then
    echo "Installing acme.sh with email: $ACME_EMAIL"
    cd /tmp/acme.sh-master
    bash ./acme.sh --install --accountemail "$ACME_EMAIL" --cert-home /acme.sh
else
    echo "acme.sh already installed"
fi

# Get the first domain as the primary domain for certificate naming
PRIMARY_DOMAIN=$(echo "$DOMAINS" | cut -d',' -f1)
export PRIMARY_DOMAIN

# Build the domain arguments for acme.sh
DOMAIN_ARGS=""
IFS=','
for domain in $DOMAINS; do
    DOMAIN_ARGS="$DOMAIN_ARGS -d $domain"
done
unset IFS

# Check if certificate already exists
if [ ! -f "/acme.sh/${PRIMARY_DOMAIN}_ecc/fullchain.cer" ]; then
    echo "Certificate not found. Issuing new certificate for: $DOMAINS"
    
    # Issue certificate using acme.sh with DNS validation
    /root/.acme.sh/acme.sh --issue --dns $ACME_DNSAPI \
        $DOMAIN_ARGS \
        --server letsencrypt \
        --keylength ec-256 \
        --accountemail "$ACME_EMAIL" \
        --force || {
        echo "ERROR: Failed to issue certificate"
        exit 1
    }
    
    echo "Certificate issued successfully"
else
    echo "Certificate already exists for: $PRIMARY_DOMAIN"
fi

# Generate nginx.conf from template
echo "Generating nginx configuration"
envsubst '${DOMAINS} ${BACKEND} ${PRIMARY_DOMAIN} ${LISTEN} ${RESOLVER}' \
    < /etc/nginx/templates/nginx.conf.template \
    > /etc/nginx/conf.d/default.conf

# Start crond for certificate renewal
echo "Starting cron daemon"
crond -l 2 -f &
CRON_PID=$!

# Start nginx
echo "Starting nginx"
exec nginx -g 'daemon off;'
