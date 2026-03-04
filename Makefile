.PHONY: build run clean help publish

IMAGE_NAME := acme-nginx-proxy
DOCKER_REGISTRY ?= docker.io
IMAGE_TAG := $(DOCKER_REGISTRY)/$(DOCKER_HUB_USER)/$(IMAGE_NAME)


help:
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build:
	docker build -t $(IMAGE_NAME) .

tar: build
	docker image save $(IMAGE_NAME):latest > $(IMAGE_NAME).tar

run-print: ## Print command to start the container with sample environment variables
	@echo docker run --rm \
		-p 8447:8447 \
		# nginx defaults to 443
		-e LISTEN=8447 \
		# nginx defaults to 127.0.0.11
		-e RESOLVER=8.8.8.8 \
		-e DOMAINS="shop.example.com,devnet.example.com,jiffy.example.com" \
		# supports HTTPS as well
		-e BACKEND="http://192.168.11.30:8000" \
		-e ACME_EMAIL="admin@example.com" \
		# select one from: https://github.com/acmesh-official/acme.sh/tree/master/dnsapi
		# defaults to dns_he
		-e ACME_DNSAPI="dns_he" \
		# Or any other credentials needed by DNS-API in acme.sh
		-e HE_Username="your_he_username" \
		-e HE_Password="your_he_password" \
		-v ./data:/acme.sh \
		$(IMAGE_NAME)

publish: build
	docker tag $(IMAGE_NAME) $(DOCKER_HUB_USER)/$(IMAGE_NAME):latest
	docker push $(DOCKER_HUB_USER)/$(IMAGE_NAME):latest

clean: ## Remove the Docker image
	docker rmi $(IMAGE_NAME) || true
	docker rmi $(IMAGE_TAG):latest || true
	rm -rf $(IMAGE_NAME).tar
