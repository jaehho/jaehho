SHELL := /bin/bash

export PATH := $(HOME)/.local/bin:$(PATH)
.SILENT:
.DEFAULT_GOAL := help

REPO_ROOT := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
PROFILE ?= $(shell cat ~/.dotfiles-profile 2>/dev/null || echo common)

## General
help: ## Show this help message
	echo "Available targets:"
	echo "=================="
	grep -hE '(^[a-zA-Z_%-]+:.*?## .*$$|^## )' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; \
		     /^## / {gsub("^## ", ""); print "\n\033[1;35m" $$0 "\033[0m"}; \
		     /^[a-zA-Z_%-]+:/ {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

test: ## Run bats test suite for tmux status scripts
	@if ! command -v bats &>/dev/null; then \
		echo "bats not found — install with:"; \
		echo "  git clone https://github.com/bats-core/bats-core.git /tmp/bats-core"; \
		echo "  /tmp/bats-core/install.sh ~/.local"; \
		exit 1; \
	fi
	bats scripts/tmux/tests/

## Setup (bootstrap = install + setup + setup-env-files)
bootstrap: ## Full setup: install packages, stow configs, prompt for secrets
	./bootstrap.sh --profile $(PROFILE)

install: ## Install system packages for current profile
	./scripts/install-packages.sh $(PROFILE)

setup: ## Stow configs and enable services for current profile
	./scripts/apply-profile.sh $(PROFILE)

## Stow (bootstrap stows all profile packages; these are for ad-hoc use)
stow-%: ## Stow a single package (e.g., make stow-nvim)
	stow -d stow -t ~ --no-folding $*

unstow-%: ## Unstow a single package (e.g., make unstow-nvim)
	stow -d stow -t ~ -D $*

## Environment (included in bootstrap)
-include $(REPO_ROOT)/.env
ENV_SAMPLE       = $(REPO_ROOT)/.env.sample
ENVRC_SAMPLE     = $(REPO_ROOT)/.envrc.sample
ENV_DST          = $(REPO_ROOT)/.env
ENVRC_DST        = $(REPO_ROOT)/.envrc

.PHONY: setup-env setup-envrc setup-env-files

setup-envrc: ## Generate .envrc
	@if [ -f $(ENVRC_DST) ]; then \
		if diff -q $(ENVRC_DST) $(ENVRC_SAMPLE) >/dev/null 2>&1; then \
			echo ".envrc is up to date."; \
		else \
			diff -u --color=always \
				--label "current .envrc" --label "new .envrc (from sample)" \
				$(ENVRC_DST) $(ENVRC_SAMPLE) || true; \
			echo; \
			read -rp "Regenerate .envrc? [y/N]: " ans < /dev/tty; \
			if [ "$$ans" = "y" ] || [ "$$ans" = "Y" ]; then \
				rm $(ENVRC_DST); \
				cp $(ENVRC_SAMPLE) $(ENVRC_DST); \
				echo ".envrc regenerated."; \
			else \
				echo "Keeping existing .envrc."; \
			fi; \
		fi; \
	else \
		cp $(ENVRC_SAMPLE) $(ENVRC_DST); \
		echo ".envrc created."; \
	fi

setup-env: ## Generate .env interactively
	@if [ -f $(ENV_DST) ]; then \
		masked=$$(mktemp); \
		awk '{ if ($$0 ~ /PASSWORD|SECRET|KEY|TOKEN/) { split($$0,a,"="); print a[1] "=****" } else { print } }' $(ENV_DST) > "$$masked"; \
		if diff -q "$$masked" $(ENV_SAMPLE) >/dev/null 2>&1; then \
			rm "$$masked"; \
			echo ".env is up to date."; \
			exit 0; \
		fi; \
		diff -u --color=always \
			--label "current .env (secrets masked)" --label "new .env (from sample)" \
			"$$masked" $(ENV_SAMPLE) || true; \
		rm "$$masked"; \
		echo; \
		read -rp "Delete and regenerate .env? [y/N]: " ans < /dev/tty; \
		if [ "$$ans" = "y" ] || [ "$$ans" = "Y" ]; then \
			rm $(ENV_DST); \
		else \
			echo "Keeping existing .env."; \
			exit 0; \
		fi; \
	fi; \
	if [ ! -f $(ENV_DST) ]; then \
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

setup-env-files: setup-envrc setup-env ## Generate both .env and .envrc

