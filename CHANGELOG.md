# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased] - v38 (Overlord Edition)

### Added
- **Unified CLI (`overlord`):** New central entry point for all framework operations.
- **Centralized Logging (`scripts/core/logger.sh`):** Timestamped, leveled logging to file and console.
- **AI Anomaly Detection (`ai/anomaly.py`):** Basic Isolation Forest model for log analysis with daemon signaling.
- **Self-Healing (`rollback` in `logger.sh`):** Basic `trap` implementation for error handling and potential rollback.
- **Script Integrity Verification (`checksums.txt`):** Added checksum verification at the start of `install.sh`.
- **DevOps Enhancements:** Added `VERSION` file, `tests/` directory with `bats` and `pytest` examples, and expanded `.github/` workflows.
- **Enhanced TUI (`tui/dashboard.sh`):** Upgraded TUI with more options and integration with `make` targets.
- **Professional Documentation:** Added `system_overview.md`, consolidating architecture and deployment, added Mermaid diagrams and badges to `README.md`.

### Changed
- Refactored `install.sh` to be a dispatcher calling platform-specific scripts (though only Arch is implemented).
- Renamed main installation/finalization scripts to `scripts/ops/`.
- Renamed shared library to `scripts/core/logger.sh`.
- `README.md` rewritten to focus on the `overlord` CLI.

---

## [34.0.0] - 2025-10-16 - Monarch Edition

This release represents a complete architectural refactoring into a professional, modular framework.

### Added
- **`Makefile` as the universal entrypoint** for all major operations (`install`, `finalize`, `backup`, `update`, `healthcheck`, `theme`, `rollback`).
- **`scripts/lib.sh`**, a shared library for centralized logging (timestamped, colored), error handling (`trap rollback`), and dependency checking.
- **Automatic Rollback:** `trap` mechanism integrated into `lib.sh`.
- **`scripts/modules/healthcheck.sh`** for generating a comprehensive security status report (JSON output).
- **`scripts/rollback-system.sh`** for granular restoration of configurations from backups.
- **Dynamic Theming (`themes/`):** Added a structured system for themes, selectable via the `.env` file. Each theme now has a `manifest.yml`.
- **Configuration Overrides (`config-overrides/`):** Support for machine-specific configurations.
- **Professional Documentation (`docs/`):** Added `architecture.md`, `CHANGELOG.md`, and `incident_response.md`.
- **CI/CD (`.github/`):** Added workflows for automated linting (`shellcheck`, `yamllint`) and testing (`bats`).
- **Integrity Verification (`checksums.txt`):** Critical scripts are now checksummed.

### Changed
- **Project Structure:** Refactored into a modular structure (config, scripts/modules, themes, etc.).
- **`install.sh`:** Became a smart dispatcher validating the environment and calling internal modules.
- **Logging:** All scripts now use the centralized logging functions from `lib.sh`.
- **`backup-configs.sh`:** Upgraded to create versioned, compressed snapshots in `~/.chimera_backups/`.
- **`README.md`:** Rewritten to reflect the `Makefile`-based workflow, including badges and a Mermaid diagram.

---
## [Prior Versions] - v1 to v33

### Added
- Initial post-installation script concept.
- Integration of core security tools (`linux-hardened`, `ufw`, `aide`, `opensnitch`, `dnscrypt-proxy`, `tor`, `i2p`).
- BlackArch repository integration.
- Hyprland desktop environment with pre-configured Waybar, Rofi, Kitty.
- `guardian-ctl` for managing security levels.
- Virtualization suite with pre-configured VM profiles (`disposable`, `work`, `tor`, `cyberlab`).
- Professional software stack (Neovim, VS Code, Docker, Wireshark, etc.).
- Performance optimizations for NVMe.
- `update-chimera` utility for system maintenance.
- `zsh_functions` for custom commands.
- Powerlevel10k integration with Kali theme.
- Comprehensive documentation (`SYSTEM_GUIDE`, `DEPLOYMENT_CHECKLIST`).
- Progress bar and detailed logging during installation.