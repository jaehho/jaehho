.SILENT:
.IGNORE:

help: ## Show this help message
	echo "Available targets:"
	echo "=================="
	grep -E '(^[a-zA-Z_-]+:.*?## .*$$|^# Section: )' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; \
		     /^# Section:/ {gsub("^# Section: ", ""); print "\n\033[1;35m" $$0 "\033[0m"}; \
		     /^[a-zA-Z_-]+:/ {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Section: Systemd Service Management
SERVICE_NAME = ice.service
SERVICE_SRC  = $(HOME)/jaehho/$(SERVICE_NAME)
SERVICE_DST  = /etc/systemd/system/$(SERVICE_NAME)

.PHONY: link reload enable start stop restart status

link: ## Link the service file to systemd directory
	sudo ln -sf $(SERVICE_SRC) $(SERVICE_DST)

reload: ## Reload systemd daemon
	sudo systemctl daemon-reload

enable: reload ## Enable the service
	sudo systemctl enable $(SERVICE_NAME)

start: enable ## Start the service
	sudo systemctl start $(SERVICE_NAME)

stop: ## Stop the service
	sudo systemctl stop $(SERVICE_NAME)

restart: ## Restart the service
	sudo systemctl restart $(SERVICE_NAME)

status: ## Show the status of the service
	systemctl status $(SERVICE_NAME)
