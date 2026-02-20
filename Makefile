SHELL := /bin/bash
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

## Systemd ICE mount service
ICE_SERVICE_NAME = ice.service
ICE_SERVICE_SRC  = $(REPO_ROOT)/systemd/$(ICE_SERVICE_NAME)
ICE_SERVICE_DST  = /etc/systemd/system/$(ICE_SERVICE_NAME)

.PHONY: ice-link ice-reload ice-enable ice-start ice-stop ice-restart ice-status

ice-link: ## Link ice service file to systemd directory
	sudo ln -sf $(ICE_SERVICE_SRC) $(ICE_SERVICE_DST)

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
GITCONFIG_SRC = $(REPO_ROOT)/config/.gitconfig
GITCONFIG_DST = $(HOME)/.gitconfig
BASH_PROFILE_SRC = $(REPO_ROOT)/config/.bash_profile
BASHRC_DST = $(HOME)/.bashrc

.PHONY: setup-all setup-gitconfig setup-bashrc setup-tmux

setup-all: setup-gitconfig setup-bashrc setup-tmux ## Run all personal setup steps

setup-gitconfig: ## Hard link repo .gitconfig into home
	ln -f $(GITCONFIG_SRC) $(GITCONFIG_DST)

setup-bashrc: ## Source repo .bash_profile from ~/.bashrc
	touch $(BASHRC_DST)
	grep -qxF 'source $(BASH_PROFILE_SRC)' $(BASHRC_DST) || \
		echo 'source $(BASH_PROFILE_SRC)' >> $(BASHRC_DST)

setup-tmux: ## Link tmux configuration
	ln -f $(REPO_ROOT)/config/.tmux.conf $(HOME)/.tmux.conf