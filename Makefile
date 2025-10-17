# =======================================================================================
#  MAKEFILE | CHIMERA GUARDIAN ARCH (Monarch Edition)
#  Universal entrypoint for installation, maintenance, and management.
# =======================================================================================

# Load environment variables from .env file to be used by scripts.
# The '-' prefix prevents errors if the file doesn't exist yet (e.g., before initial setup).
-include .env

# Use Zsh as the default shell for executing commands within the Makefile.
SHELL := /bin/zsh

# Define colors for user feedback directly within the Makefile output.
INFO := \033[1;34m
SUCCESS := \033[1;32m
WARN := \033[1;33m
ERR := \033[1;31m
NC := \033[0m

# Define all targets as "phony" to prevent conflicts with files of the same name
# and to ensure they always run when called. This is a best practice.
.PHONY: all help install finalize link backup update clean logs checksums healthcheck theme rollback validate pre-install-hook pre-backup-hook

# The default target that runs when 'make' is called without arguments.
all: help

# ---------------------------------------------------------------------------------------
#  USER-FACING TARGETS
# ---------------------------------------------------------------------------------------

help:
	@echo "Usage: make [TARGET]"
	@echo ""
	@echo "Core Targets:"
	@echo "  install    - Run the full, fresh system installation (requires sudo)."
	@echo "  finalize   - Run the post-reboot finalization (requires sudo)."
	@echo "  update     - Securely update the entire system (OS, AUR, Exploit-DB)."
	@echo ""
	@echo "Management Targets:"
	@echo "  healthcheck- Run a full system security and status check."
	@echo "  backup     - Create a versioned, compressed snapshot of your ~/.config directory."
	@echo "  rollback   - Restore configurations from the most recent backup."
	@echo "  link       - (Re)create symbolic links for all configuration files."
	@echo "  theme      - Apply a different theme (e.g., 'make theme theme=nord')."
	@echo ""
	@echo "Utility Targets:"
	@echo "  logs       - Tail the main installation log file."
	@echo "  checksums  - Regenerate the script integrity checksums file."
	@echo "  clean      - Clean up temporary build directories."
	@echo "  validate   - Validate the .env configuration file."

# Runs the main installation process. Depends on validation and pre-install hooks.
install: validate pre-install-hook
	@echo "$(INFO)[INFO] Starting Chimera Guardian Arch fresh installation...$(NC)"
	@sudo ./install.sh --fresh # Uses the universal entrypoint script
	@bash ./hooks/post-install.sh

# Runs the post-reboot finalization process.
finalize: validate
	@echo "$(INFO)[INFO] Finalizing Chimera system...$(NC)"
	@sudo ./install.sh --finalize # Uses the universal entrypoint script

# Links configuration files based on the THEME variable in .env.
link: validate
	@echo "$(INFO)[INFO] Linking configuration files for theme: $(THEME)...$(NC)"
	@./link-configs.sh

# Creates a backup of the user's configurations. Depends on pre-backup hook.
backup: pre-backup-hook
	@echo "$(INFO)[INFO] Backing up current configurations...$(NC)"
	@./scripts/backup-configs.sh

# Updates the system. Depends on validation.
update: validate
	@echo "$(INFO)[INFO] Starting system-wide update...$(NC)"
	@bash ./hooks/pre-update.sh
	@sudo ./scripts/update-chimera # Calls the specific update script
	@bash ./hooks/post-update.sh

# Runs the system health check module.
healthcheck: validate
	@echo "$(INFO)[INFO] Running system health check...$(NC)"
	@sudo ./scripts/modules/healthcheck.sh

# Switches the system theme. Requires the 'theme' variable to be passed.
# Example: make theme theme=nord
theme: validate
	@echo "$(INFO)[INFO] Switching theme to $(theme)...$(NC)"
	@./switch-theme.sh $(theme) # Assumes a switch-theme.sh script exists

# Restores the system from the latest backup.
rollback:
	@echo "$(INFO)[INFO] Starting system rollback from latest backup...$(NC)"
	@./scripts/rollback-system.sh

# ---------------------------------------------------------------------------------------
#  DEVELOPER & UTILITY TARGETS
# ---------------------------------------------------------------------------------------

# Tails the installation log file.
logs:
	@echo "$(INFO)[INFO] Tailing installation log... (Press Ctrl+C to exit)$(NC)"
	@tail -f logs/chimera-install-*.log

# Regenerates the checksums file for script integrity verification.
checksums:
	@echo "$(INFO)[INFO] Regenerating checksums file...$(NC)"
	@find ./scripts -type f -name "*.sh" | xargs sha256sum > checksums.txt
	@echo "$(SUCCESS)[OK]   checksums.txt regenerated.$(NC)"

# Cleans temporary directories (currently only 'work/').
clean:
	@echo "$(INFO)[INFO] Cleaning up temporary work directories...$(NC)"
	@rm -rf work/

# ---------------------------------------------------------------------------------------
#  INTERNAL HOOKS & VALIDATION (not intended for direct user interaction)
# ---------------------------------------------------------------------------------------

# Validates the .env file configuration.
validate:
	@echo "$(INFO)[INFO] Validating environment configuration...$(NC)"
	@bash ./scripts/modules/validate_env.sh

# Runs the pre-installation hook script.
pre-install-hook:
	@echo "$(INFO)[INFO] Running pre-installation hook...$(NC)"
	@bash ./hooks/pre-install.sh

# Runs the pre-backup hook script.
pre-backup-hook:
	@echo "$(INFO)[INFO] Running pre-backup hook...$(NC)"
	@bash ./hooks/pre-backup.sh