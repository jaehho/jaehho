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

## Setup (bootstrap = install + setup + setup-env)
bootstrap: ## Full setup: install packages, stow configs, prompt for secrets
	./bootstrap.sh --profile $(PROFILE)

install: ## Install system packages for current profile
	./scripts/install-packages.sh $(PROFILE)

setup: ## Stow configs and enable services for current profile
	./scripts/apply-profile.sh $(PROFILE)

clean: ## Reverse setup: unstow packages, disable services, remove hooks
	./scripts/clean-profile.sh $(PROFILE)

status: ## Show current dotfiles state
	@echo "Profile: $(PROFILE)"
	@echo ""
	@echo "Stowed packages:"
	@for pkg in stow/*/; do \
		pkg_name=$$(basename "$$pkg"); \
		first_file=$$(find "$$pkg" -type f -print -quit 2>/dev/null); \
		if [ -n "$$first_file" ]; then \
			rel="$${first_file#stow/$$pkg_name/}"; \
			if [ -L "$$HOME/$$rel" ]; then \
				echo "  $$pkg_name: stowed"; \
			else \
				echo "  $$pkg_name: not stowed"; \
			fi; \
		else \
			echo "  $$pkg_name: empty"; \
		fi; \
	done
	@echo ""
	@echo "Services:"
	@for svc in systemd/*.service.tmpl; do \
		[ -f "$$svc" ] || continue; \
		svc_name=$$(basename "$$svc" .service.tmpl); \
		if systemctl is-enabled "$$svc_name.service" 2>/dev/null | grep -q 'enabled'; then \
			echo "  $$svc_name: enabled"; \
		else \
			echo "  $$svc_name: disabled"; \
		fi; \
	done

## Stow (bootstrap stows all profile packages; these are for ad-hoc use)
stow-%: ## Stow a single package (e.g., make stow-nvim)
	pre_dirty=$$(git diff --name-only -- stow/$*/ 2>/dev/null); \
	stow -d stow -t ~ --no-folding --adopt $* && \
	git diff --name-only -- stow/$*/ 2>/dev/null | while IFS= read -r f; do \
		[ -z "$$f" ] && continue; \
		echo "$$pre_dirty" | grep -qxF "$$f" || git checkout -- "$$f"; \
	done

unstow-%: ## Unstow a single package (e.g., make unstow-nvim)
	stow -d stow -t ~ -D $*

## Environment (included in bootstrap)
-include $(REPO_ROOT)/.env
ENV_SAMPLE       = $(REPO_ROOT)/.env.sample
ENV_DST          = $(REPO_ROOT)/.env

.PHONY: setup-env

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
