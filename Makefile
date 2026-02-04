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
SERVICE_NAME = ice.service
SERVICE_SRC  = $(REPO_ROOT)/systemd/$(SERVICE_NAME)
SERVICE_DST  = /etc/systemd/system/$(SERVICE_NAME)

.PHONY: service-link service-reload service-enable service-start service-stop service-restart service-status
.PHONY: link reload enable start stop restart status

service-link: ## Link the service file to systemd directory
	sudo ln -sf $(SERVICE_SRC) $(SERVICE_DST)

service-reload: ## Reload systemd daemon
	sudo systemctl daemon-reload

service-enable: service-reload ## Enable the service
	sudo systemctl enable $(SERVICE_NAME)

service-start: service-enable ## Start the service
	sudo systemctl start $(SERVICE_NAME)

service-stop: ## Stop the service
	sudo systemctl stop $(SERVICE_NAME)

service-restart: ## Restart the service
	sudo systemctl restart $(SERVICE_NAME)

service-status: ## Show the status of the service
	systemctl status $(SERVICE_NAME)

## Personal setup
GITCONFIG_SRC = $(REPO_ROOT)/config/.gitconfig
GITCONFIG_DST = $(HOME)/.gitconfig
BASH_PROFILE_SRC = $(REPO_ROOT)/config/.bash_profile
BASHRC_DST = $(HOME)/.bashrc

.PHONY: setup-all setup-gitconfig setup-bashrc
.PHONY: setup link-gitconfig bashrc

setup-all: setup-gitconfig setup-bashrc ## Run all personal setup steps

setup-gitconfig: ## Hard link repo .gitconfig into home
	ln -f $(GITCONFIG_SRC) $(GITCONFIG_DST)

setup-bashrc: ## Source repo .bash_profile from ~/.bashrc
	touch $(BASHRC_DST)
	grep -qxF 'source $(BASH_PROFILE_SRC)' $(BASHRC_DST) || \
		echo 'source $(BASH_PROFILE_SRC)' >> $(BASHRC_DST)

