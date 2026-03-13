SHELL := /bin/bash

export PATH := $(HOME)/.local/bin:$(PATH)
.SILENT:
.IGNORE:
.DEFAULT_GOAL := help

REPO_ROOT := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

## General
help: ## Show this help message
	echo "Available targets:"
	echo "=================="
	grep -E '(^[a-zA-Z_-]+:.*?## .*$$|^## )' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; \
		     /^## / {gsub("^## ", ""); print "\n\033[1;35m" $$0 "\033[0m"}; \
		     /^[a-zA-Z_-]+:/ {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

## Tmux scripts
.PHONY: test

test: ## Run bats test suite for tmux status scripts
	@if ! command -v bats &>/dev/null; then \
		echo "bats not found — install with:"; \
		echo "  git clone https://github.com/bats-core/bats-core.git /tmp/bats-core"; \
		echo "  /tmp/bats-core/install.sh ~/.local"; \
		exit 1; \
	fi
	bats scripts/tmux/tests/

## Systemd ICE mount service
ICE_SERVICE_NAME = ice.service
ICE_SERVICE_SRC  = $(REPO_ROOT)/systemd/$(ICE_SERVICE_NAME)
ICE_SERVICE_DST  = /etc/systemd/system/$(ICE_SERVICE_NAME)
ICE_ENV          = $(REPO_ROOT)/.env
ICE_MOUNT_SCRIPT = $(REPO_ROOT)/scripts/ice/mount.sh

.PHONY: ice-link ice-reload ice-enable ice-start ice-stop ice-restart ice-status

ice-link: ## Link ice service file to systemd directory
	sudo ln -sf $(ICE_SERVICE_SRC) $(ICE_SERVICE_DST)
	sudo chcon -t systemd_unit_file_t $(ICE_SERVICE_SRC)
	sudo chcon -t systemd_unit_file_t $(ICE_ENV)
	sudo chcon -t bin_t $(ICE_MOUNT_SCRIPT)

ice-reload: ## Reload systemd daemon
	sudo systemctl daemon-reload

ice-enable: ice-reload ## Enable the ice service
	sudo systemctl enable $(ICE_SERVICE_NAME)

ice-start: ice-enable ## Start the ice service
	sudo systemctl start $(ICE_SERVICE_NAME)

ice-stop: ## Stop the ice service
	sudo systemctl stop $(ICE_SERVICE_NAME)

ice-restart: ## Restart the ice service
	sudo systemctl restart $(ICE_SERVICE_NAME)

ice-status: ## Show the status of the ice service
	systemctl status $(ICE_SERVICE_NAME)

## Systemd Zotero sync service
ZOTERO_SERVICE_NAME = zotero.service
ZOTERO_SERVICE_SRC  = $(REPO_ROOT)/systemd/$(ZOTERO_SERVICE_NAME)
ZOTERO_SERVICE_DST  = /etc/systemd/system/$(ZOTERO_SERVICE_NAME)

.PHONY: zotero-link zotero-reload zotero-enable zotero-start zotero-stop zotero-restart zotero-status

zotero-link: ## Link zotero service file to systemd directory
	sudo ln -sf $(ZOTERO_SERVICE_SRC) $(ZOTERO_SERVICE_DST)

zotero-reload: ## Reload systemd daemon
	sudo systemctl daemon-reload

zotero-enable: zotero-reload ## Enable the zotero service
	sudo systemctl enable $(ZOTERO_SERVICE_NAME)

zotero-start: zotero-enable ## Start the zotero service
	sudo systemctl start $(ZOTERO_SERVICE_NAME)

zotero-stop: ## Stop the zotero service
	sudo systemctl stop $(ZOTERO_SERVICE_NAME)

zotero-restart: ## Restart the zotero service
	sudo systemctl restart $(ZOTERO_SERVICE_NAME)

zotero-status: ## Show the status of the zotero service
	systemctl status $(ZOTERO_SERVICE_NAME)

## Personal setup
GITCONFIG_SRC    = $(REPO_ROOT)/config/.gitconfig
GITCONFIG_DST    = $(HOME)/.gitconfig
BASH_PROFILE_SRC = $(REPO_ROOT)/config/.bash_profile
BASHRC_DST       = $(HOME)/.bashrc
NVIM_SRC         = $(REPO_ROOT)/config/nvim
NVIM_DST         = $(HOME)/.config/nvim
ENV_SAMPLE       = $(REPO_ROOT)/.env.sample
ENVRC_SAMPLE     = $(REPO_ROOT)/.envrc.sample
ENV_DST          = $(REPO_ROOT)/.env
ENVRC_DST        = $(REPO_ROOT)/.envrc

.PHONY: setup-all setup-gitconfig setup-bashrc setup-tmux setup-nvim setup-env setup-envrc setup-env-files

setup-all: setup-gitconfig setup-bashrc setup-tmux setup-nvim setup-env-files ## Run all personal setup steps

setup-gitconfig: ## Hard link repo .gitconfig into home
	ln -f $(GITCONFIG_SRC) $(GITCONFIG_DST)

setup-bashrc: ## Source repo .bash_profile from ~/.bashrc
	touch $(BASHRC_DST)
	grep -qxF 'source $(BASH_PROFILE_SRC)' $(BASHRC_DST) || \
		echo 'source $(BASH_PROFILE_SRC)' >> $(BASHRC_DST)

setup-tmux: ## Link tmux configuration
	ln -f $(REPO_ROOT)/config/.tmux.conf $(HOME)/.tmux.conf

setup-nvim: ## Symlink repo nvim config to ~/.config/nvim
	mkdir -p $(HOME)/.config
	ln -sfn $(NVIM_SRC) $(NVIM_DST)

setup-envrc: ## Generate .envrc
	@if [ -f $(ENVRC_DST) ]; then \
		echo ".envrc already exists. Delete it first to regenerate."; \
	else \
		cp $(ENVRC_SAMPLE) $(ENVRC_DST); \
		echo ".envrc created."; \
	fi

setup-env: ## Generate .env interactively
	@if [ -f $(ENV_DST) ]; then \
		echo ".env already exists. Delete it first to regenerate."; \
	else \
		cp $(ENV_SAMPLE) $(ENV_DST); \
		echo "Filling out .env (press Enter to leave a field empty):"; \
		while IFS= read -r line || [ -n "$$line" ]; do \
			[[ "$$line" =~ ^#.*$$ || -z "$$line" ]] && continue; \
			key=$$(echo "$$line" | cut -d= -f1); \
			default=$$(echo "$$line" | cut -d= -f2-); \
			if echo "$$key" | grep -qiE 'PASSWORD|SECRET|KEY|TOKEN'; then \
				read -rsp "  $$key: " v < /dev/tty && echo; \
			else \
				read -rp  "  $$key [$$default]: " v < /dev/tty; \
			fi; \
			[ -z "$$v" ] && v="$$default"; \
			sed -i "s|^$$key=.*|$$key=$$v|" $(ENV_DST); \
		done < $(ENV_SAMPLE); \
		echo ".env created."; \
	fi

setup-env-files: setup-envrc setup-env ## Generate both .env and .envrc from samples

## Neovim
.PHONY: update-nvim

update-nvim: ## Build and install latest stable Neovim from source
	$(REPO_ROOT)/scripts/update-nvim.sh

## Dependencies
PYTORCH_INDEX = https://download.pytorch.org/whl/cu130

.PHONY: install-deps install-apt install-python

install-deps: install-apt install-python ## Install all dependencies (apt + python)

install-apt: ## Install required system packages (apt or dnf)
	@if command -v dnf &>/dev/null; then \
		sudo dnf install -y \
			curl \
			direnv \
			expect \
			fd-find \
			fuse-sshfs \
			gcc \
			iproute \
			make \
			nodejs \
			ripgrep \
			sysstat \
			tmux \
			unzip; \
	else \
		sudo apt-get update -qq && \
		sudo apt-get install -y \
			curl \
			direnv \
			expect \
			fd-find \
			gcc \
			iproute2 \
			make \
			nodejs \
			ripgrep \
			sshfs \
			sysstat \
			tmux \
			unzip \
			wl-clipboard; \
	fi

install-python: ## Install required Python packages via uv
	uv pip install torch torchvision --index-url $(PYTORCH_INDEX)