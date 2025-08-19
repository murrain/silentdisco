SHELL := /bin/bash

.PHONY: help up down logs rebuild env clean

help:
	@echo "Targets:"
	@echo "  make env     - Detect Pulse source and write .env (UID, GROUP, PORT, BITRATE, PULSE_SOURCE)"
	@echo "  make up      - Build and start containers"
	@echo "  make down    - Stop containers"
	@echo "  make logs    - Tail logs"
	@echo "  make rebuild - Rebuild images and restart"
	@echo "  make clean   - Remove containers and images"

env:
	@./scripts/detect_pulse.sh || true
	@echo "Review .env and set PULSE_SOURCE if empty."

up:
	docker compose up --build -d

down:
	docker compose down

logs:
	docker compose logs -f --tail=200

rebuild:
	docker compose down
	docker compose build --no-cache
	docker compose up -d

clean:
	docker compose down --rmi all -v --remove-orphans || true
	rm -f .env
