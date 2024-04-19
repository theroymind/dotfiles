SHELL := bash

.PHONY: all
all: dotfiles ## Installs the bin and etc directory files and the dotfiles.

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

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
