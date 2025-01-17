help: ## Show this help message
	@echo "Available targets:"
	@echo "=================="
	@grep -E '(^[a-zA-Z_-]+:.*?## .*$$|^# Section: )' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; \
		     /^# Section:/ {gsub("^# Section: ", ""); print "\n\033[1;35m" $$0 "\033[0m"}; \
		     /^[a-zA-Z_-]+:/ {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

compile: ## Compile a file once
	@typst compile resume/main.typ Jaeho_Cho_Resume.pdf

watch: ## Compile a file on every change
	@typst watch resume/main.typ Jaeho_Cho_Resume.pdf