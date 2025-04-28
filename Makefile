
.DEFAULT_GOAL := install-prompt

.PHONY: install-prompt
install-prompt: ## Default target - Prompts user with a list of available installations
	@selected_options=$$(whiptail --title "Installation Options" \
		--checklist "Use arrow keys to navigate, space to select/deselect, and enter to confirm:" \
		15 78 6 \
		"dotfiles" "Install dotfiles (symlinks configuration files)" OFF \
		"slack" "Install Slack messaging app" OFF \
		"vscode" "Install Visual Studio Code editor" OFF \
		"iterm2" "Install iTerm2 terminal emulator" OFF \
		"nvim-config" "Install Neovim and configuration from theroymind/config.nvim" OFF \
		"git-cof" "Install git-cof Checking out branches by story number" OFF \
		3>&1 1>&2 2>&3); \
	if [ $$? -eq 0 ]; then \
		selected_options=$$(echo $$selected_options | tr -d '"'); \
		if [ -n "$$selected_options" ]; then \
			echo "\nYou selected: $$selected_options"; \
			if whiptail --title "Confirm Installation" --yesno "Do you want to proceed with the installation?" 8 60 3>&1 1>&2 2>&3; then \
				echo "\nProcessing selections..."; \
				for option in $$selected_options; do \
					echo "\nInstalling $$option..." && \
					make install-$$option; \
				done; \
				if echo "$$selected_options" | grep -q "dotfiles"; then \
					echo "\nConfiguring dotfiles..."; \
					make replace-tokens; \
				fi; \
				echo "\nInstallation complete!"; \
			else \
				echo "Installation canceled."; \
			fi; \
		else \
			echo "No options selected. Installation canceled."; \
		fi; \
	else \
		echo "Installation canceled."; \
	fi

.PHONY: all
all: dotfiles replace-tokens install-slack install-vscode install-iterm2 install-nvim-config install-git-cof ## Installs the bin and etc directory files and the dotfiles.

.PHONY: dotfiles
dotfiles: ## Installs the dotfiles.
	ln -fs $(CURDIR) $(HOME)/.dotfiles;
	ln -fs $(CURDIR)/.gitconfig $(HOME)/.gitconfig;
	ln -fs $(CURDIR)/.gitignore_global $(HOME)/.gitignore;
	ln -fs $(CURDIR)/.tmux.conf $(HOME)/.tmux.conf;
	ln -fs $(CURDIR)/.vimrc $(HOME)/.vimrc;
	ln -fs $(CURDIR)/.zshrc $(HOME)/.zshrc;

.PHONY: help

FILES := $(HOME)/.gitconfig $(HOME)/.dotfiles/.dockerfunc # List of files in which to replace tokens
.PHONY: replace-tokens
replace-tokens:
	@echo "Enter the name:"
	@read name; \
	echo "Enter the email:"; \
	read email; \
	echo "Enter the user directory:"; \
	read user_dir; \
	for file in $(FILES); do \
		if [ -f "$$file" ] && [ ! -L "$$file" ]; then \
			sed -i '' "s/{NAME}/$$name/g" $$file; \
			sed -i '' "s/{EMAIL}/$$email/g" $$file; \
			sed -i '' "s/{USER_DIRECTORY}/$$user_dir/g" $$file; \
			echo "Replaced tokens in $$file."; \
		elif [ -L "$$file" ]; then \
			real_path=$$(readlink $$file); \
			sed -i '' "s/{NAME}/$$name/g" $$real_path; \
			sed -i '' "s/{EMAIL}/$$email/g" $$real_path; \
			sed -i '' "s/{USER_DIRECTORY}/$$user_dir/g" $$real_path; \
			echo "Replaced tokens in symlinked $$file, original file $$real_path."; \
		else \
			echo "Skipping $$file, not a regular file."; \
		fi; \
	done

.PHONY: install-iterm2
install-iterm2:
	@echo "Checking for Homebrew..."
	@if ! which brew > /dev/null 2>&1; then \
		echo "Homebrew is not installed. Installing Homebrew..."; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
		echo "Homebrew installed."; \
	fi; \
	echo "Checking for iTerm2..."
	@if ! brew list --cask | grep -q iterm2; then \
		echo "iTerm2 is not installed. Installing iTerm2..."; \
		brew install --cask iterm2; \
		echo "iTerm2 installed."; \
	else \
		echo "iTerm2 is already installed."; \
	fi

.PHONY: install-vscode
install-vscode:
	@echo "Checking for Homebrew..."
	@if ! which brew > /dev/null 2>&1; then \
		echo "Homebrew is not installed. Installing Homebrew..."; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
		echo "Homebrew installed."; \
	fi; \
	echo "Checking for Visual Studio Code..."
	@if ! brew list --cask | grep -q '^visual-studio-code$$'; then \
		echo "Visual Studio Code is not installed. Installing Visual Studio Code..."; \
		brew install --cask visual-studio-code; \
		echo "Visual Studio Code installed."; \
	else \
		echo "Visual Studio Code is already installed."; \
	fi

.PHONY: install-slack
install-slack:
	@echo "Checking for Homebrew..."
	@if ! which brew > /dev/null 2>&1; then \
		echo "Homebrew is not installed. Installing Homebrew..."; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
		echo "Homebrew installed."; \
	fi; \
	echo "Checking for Slack..."
	@if ! brew list --cask | grep -q '^slack$$'; then \
		echo "Slack is not installed. Installing Slack..."; \
		brew install --cask slack; \
		echo "Slack installed."; \
	else \
		echo "Slack is already installed."; \
	fi

.PHONY: install-nvim-config
install-nvim-config: ## Installs Neovim configuration from theroymind/config.nvim (includes Neovim installation)
	@echo "Installing Neovim configuration..."
	@if [ -d "$(HOME)/.config/nvim" ]; then \
		echo "Backing up existing Neovim configuration..."; \
		mv "$(HOME)/.config/nvim" "$(HOME)/.config/nvim.backup.$$(date +%Y%m%d%H%M%S)"; \
	fi
	@mkdir -p "$(HOME)/.config"
	@git clone git@github.com:theroymind/config.nvim.git "$(HOME)/.config/nvim"
	@echo "Neovim configuration cloned. Running make in the configuration directory..."
	@if [ -f "$(HOME)/.config/nvim/Makefile" ] || [ -f "$(HOME)/.config/nvim/makefile" ]; then \
		cd "$(HOME)/.config/nvim" && make; \
		echo "Neovim configuration make completed."; \
	else \
		echo "No Makefile found in the Neovim configuration directory. Skipping make."; \
	fi
	@echo "Neovim configuration installed."

.PHONY: install-git-cof
install-git-cof: ## Installs the git-cof command for finding and checking out branches by ticket number
	@echo "Installing git-cof command..."
	sudo cp $(CURDIR)/bin/git-cof /usr/local/bin/git-cof
	sudo chmod +x /usr/local/bin/git-cof
	@echo "git-cof installed."

.PHONY: help
help: ## Display this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
