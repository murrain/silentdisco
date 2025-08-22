.PHONY: help env sink up down logs rebuild clean

help:
	@echo "Targets:"
	@echo "  make sink    - Create persistent Pulse/pipewire virtual sink 'MixxxMaster'"
	@echo "  make env     - Detect Pulse source and write .env (prefers MixxxMaster.monitor)"
	@echo "  make up      - Build and start containers"
	@echo "  make down    - Stop containers"
	@echo "  make logs    - Tail logs"
	@echo "  make rebuild - Rebuild images and restart"
	@echo "  make clean   - Remove containers and images"

sink:
	@./scripts/setup_mixxx_sink.sh

env:
	@./scripts/detect_pulse.sh || true
	@echo "If PULSE_SOURCE is empty, run 'make sink' and then 'make env' again."

up:
	docker compose build
	docker compose up -d

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