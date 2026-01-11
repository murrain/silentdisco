# Variables for image caching
CACHE_DIR := cache
CACHE_FILE := $(CACHE_DIR)/silentdisco-images.tar
IMAGES := silentdisco-web:offline silentdisco-streamer:offline

.PHONY: help env sink up down logs rebuild clean

help:
	@echo "Targets:"
	@echo "  make sink    - Create persistent Pulse/pipewire virtual sink 'MixxxMaster'"
	@echo "  make env     - Detect Pulse source and write .env (prefers MixxxMaster.monitor)"
	@echo "  make up      - Build and start containers"
	@echo "  make up-offline - Build and start containers (offline)"
	@echo "  make down    - Stop containers"
	@echo "  make logs    - Tail logs"
	@echo "  make rebuild - Rebuild images and restart"
	@echo "  save-cache    - Build then save images to $(CACHE_FILE)"
	@echo "  save-cache-gz - As above, gzipped"
	@echo "  load-cache    - Load images from cache (tar or tar.gz)"
	@echo "  clean-images  - Remove the tagged images from local cache"
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

build:
	docker compose build
rebuild:
	docker compose down
	docker compose build --no-cache
	docker compose up -d
up-offline:
	@./scripts/offline_boot.sh
save-cache: build
	mkdir -p $(CACHE_DIR)
	docker save -o $(CACHE_FILE) $(IMAGES)
	@echo "Saved image bundle: $(CACHE_FILE)"

save-cache-gz: save-cache
	gzip -f $(CACHE_FILE)
	@echo "Saved image bundle: $(CACHE_FILE).gz"

load-cache:
	@if [ -f "$(CACHE_FILE).gz" ]; then \
		gunzip -c "$(CACHE_FILE).gz" | docker load; \
	elif [ -f "$(CACHE_FILE)" ]; then \
		docker load -i "$(CACHE_FILE)"; \
	else \
		echo "No cache tar found in $(CACHE_DIR)"; exit 1; \
	fi

clean-images:
	@for img in $(IMAGES); do docker image rm $$img || true; done

clean:
	docker compose down --rmi all -v --remove-orphans || true
	rm -f .env