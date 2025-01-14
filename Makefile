help: ## Show this help message
	@echo "Available targets:"
	@echo "=================="
	@grep -E '(^[a-zA-Z_-]+:.*?## .*$$|^# Section: )' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; \
		     /^# Section:/ {gsub("^# Section: ", ""); print "\n\033[1;35m" $$0 "\033[0m"}; \
		     /^[a-zA-Z_-]+:/ {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Section: rendercv
render: ## Render resume to Jaeho_Cho_Resume/ and Jaeho_Cho_Resume.pdf
	cd _rendercv && rendercv render Jaeho_Cho_CV.yaml --pdf-path "../Jaeho_Cho_Resume.pdf" -nomd -nopng -nohtml

clean: ## Remove generated files and directories
	rm -rf _rendercv/rendercv_output
