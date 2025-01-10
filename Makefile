# Makefile

help: # target details come from double hashtag comments after target name
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

clean:
	rm -rf _rendercv/rendercv_output

render: ## Render Resume to Jaeho_Cho_Resume/ and Jaeho_Cho_Resume.pdf
	cd _rendercv && rendercv render Jaeho_Cho_CV.yaml --use-local-latex-command "pdflatex" --pdf-path "../Jaeho_Cho_Resume.pdf" -nopng -nohtml

# render: ## Render Resume to Jaeho_Cho_Resume/ and Jaeho_Cho_Resume.pdf
# 	cd _rendercv && \
# 	sed -i 's/sb2nov/v0/' Jaeho_Cho_CV.yaml && \
# 	rendercv render Jaeho_Cho_CV.yaml --use-local-latex-command "pdflatex" --pdf-path "../Jaeho_Cho_Resume.pdf" -nopng -nohtml; \
# 	sed -i 's/v0/sb2nov/' Jaeho_Cho_CV.yaml

# renderserif: ## Render Resume with Serif Font for print
# 	cd _rendercv && \
# 	sed -i 's/sb2nov/v0/' Jaeho_Cho_CV.yaml && \
# 	sed -i 's/Roboto/RobotoSerif/' Jaeho_Cho_CV.yaml && \
# 	rendercv render Jaeho_Cho_CV.yaml --pdf-path "../Jaeho_Cho_Resume_Serif.pdf" -nopng -nohtml -serif ; \
# 	sed -i 's/v0/sb2nov/' Jaeho_Cho_CV.yaml