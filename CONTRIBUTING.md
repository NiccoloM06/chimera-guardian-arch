# Contributing to Chimera Guardian Arch

First off, thank you for considering a contribution to Chimera Guardian Arch! We welcome all contributions, from simple bug reports to major feature proposals. This document outlines the standards and procedures to ensure a smooth and effective collaboration process.

Following these guidelines helps communicate that you respect the time of the developers managing and developing this open-source project. In return, we will reciprocate that respect by addressing your issue, assessing changes, and helping you finalize your pull requests.

## 📜 Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior.

---

## 🚀 How Can I Contribute?

There are several ways you can contribute to the project:

* **Reporting Bugs:** If you find a bug, please create a detailed issue using the "Bug Report" template.
* **Suggesting Enhancements:** Have an idea for a new feature or an improvement to an existing one? Create an issue using the "Feature Request" template.
* **Submitting Pull Requests:** If you want to contribute code, please follow the workflow described below.
* **Improving Documentation:** If you notice errors or areas for improvement in our documentation, feel free to submit a pull request.

---

## 🛠️ Your First Code Contribution: The Workflow

Contributing code to Chimera Guardian Arch is a straightforward process.

### 1. Find or Create an Issue

All work should be tied to a specific issue in the GitHub issue tracker.
* **Find an existing issue:** Look through the [issue list](https://github.com/USER/REPO/issues) for something you'd like to work on. Look for issues labeled `help-wanted` or `good-first-issue`.
* **Create a new issue:** If you have a new idea, create an issue first to discuss it with the maintainers. This ensures your work aligns with the project's goals before you spend time on it.

### 2. Fork the Repository

Create a personal fork of the main repository on GitHub.

### 3. Create a Feature Branch

From your fork, create a new branch for your work. A good branch name is descriptive and includes the issue number.
```bash
# Example:
git checkout -b feature/42-add-tui-dashboard
```

### 4. Make Your Changes

Write your code. Follow the coding standards outlined below. Ensure your code is clean, well-commented, and focused on solving the specific issue.

### 5. Run Local Tests & Linters

Before submitting your changes, you **must** ensure your code passes all quality checks. The `Makefile` provides convenient targets for this.
```bash
# Check code style and for potential bugs
make lint

# Run the automated test suite
make test
```
Fix any errors or warnings that these commands report.

### 6. Commit Your Changes

Write clear and concise commit messages. We follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification.
* **Format:** `<type>(<scope>): <subject>`
* **Examples:**
    * `feat(scripts): add rollback function to lib.sh`
    * `fix(config): correct typo in hyprland keybind`
    * `docs(readme): update installation instructions`

### 7. Submit a Pull Request

Push your feature branch to your fork and then open a pull request against the `main` branch of the main repository.
* **Use the Pull Request Template:** Fill out the provided template completely.
* **Link the Issue:** Make sure your pull request description includes the line `Closes #<issue_number>`.
* **Ensure CI Passes:** All automated checks (linting, testing) must pass for your pull request to be considered for merging.

---

## 📝 Coding Standards

* **Shell Scripts (Bash):**
    * All scripts must start with `#!/usr/bin/env bash` and include `set -euo pipefail`.
    * Use the logging functions from `scripts/lib.sh` (`log_info`, `log_error`, etc.) for all output.
    * Adhere to the [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html).
    * All scripts must pass `shellcheck`.
* **Python:**
    * Follow the [PEP 8](https://www.python.org/dev/peps/pep-0008/) style guide.
    * All code must pass `flake8`.
* **YAML/JSON:**
    * Use consistent indentation (2 spaces for YAML, 4 for JSON).
    * All YAML files must pass `yamllint`.

---

Thank you for helping make Chimera Guardian Arch better!