# acme.sh & nginx Docker Container

A Docker container that provides an Nginx reverse proxy with automatic Let's Encrypt certificate management using `acme.sh` and the HE (Hurricane Electric) DNS API.

## Features

- Automatic SSL certificate issuance and renewal using Let's Encrypt
- DNS validation via HE DNS API (no need to open port 80 for ACME challenges)
- Internal cron daemon for periodic certificate renewal
- Nginx reverse proxy to a specified backend
- Support for multiple domains in a single certificate

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DOMAINS` | Yes | - | Comma-separated list of domains (e.g., `shop.example.com,devnet.example.com`) |
| `BACKEND` | Yes | - | The backend URL to proxy traffic to (e.g., `http://192.168.11.30:8000`). Supports HTTPS as well. |
| `ACME_EMAIL` | Yes | - | Email address for Let's Encrypt account registration |
| `ACME_DNSAPI` | No | `dns_he` | The DNS API to use for ACME challenges. See [acme.sh dnsapi](https://github.com/acmesh-official/acme.sh/tree/master/dnsapi) for available options. |
| `LISTEN` | No | `443` | The port nginx listens on |
| `RESOLVER` | No | `127.0.0.11` | The DNS resolver for nginx (Docker's embedded DNS by default) |

## Usage

### Building the Image

```bash
make build
```

### Running the Container

To see the full command with all available options:

```bash
make run-print
```

### Makefile Targets

- `make build` - Build the Docker image
- `make tar` - Build and save the Docker image as a tarball
- `make run-print` - Print the command to start the container with sample environment variables
- `make publish` - Push the Docker image to Docker Hub
- `make clean` - Remove the Docker image and tarball
- `make help` - Show available make targets

## How It Works

1. On container startup, the entrypoint script validates required environment variables
2. If certificates don't exist, `acme.sh` issues new certificates using DNS validation
3. Nginx configuration is generated from the template using environment variables
4. Cron daemon is started in the background for automatic certificate renewal
5. Nginx starts and begins proxying traffic to the specified backend

## Certificate Renewal

Certificates are automatically renewed by `acme.sh` via the cron daemon. The default renewal check runs daily. When certificates are renewed, Nginx will need to be reloaded (this can be added to the `acme.sh` deploy hook if needed).

## Notes

- Certificates are stored in `/acme.sh/` inside the container
- For persistent certificates across container restarts, mount a volume to `/acme.sh` (e.g., `-v ./data:/acme.sh`)
- The container uses ECC (ec-256) certificates by default for better performance
