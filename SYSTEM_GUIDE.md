# 📚 The Complete User Guide for Chimera Guardian Arch

Welcome to Chimera Guardian Arch. This is not just an operating system; it's a security platform designed to give you maximum control. This guide is your primary operational manual for understanding and mastering every component of your new environment.

---
## 🚀 Your First Steps: Post-Installation Checklist

You've completed the installation and finalization. Excellent work. Now, follow this checklist to make the system truly yours and secure its components.

1.  **Secure Your Virtual Machines:**
    * Launch the "Virtual Machine Manager" (run `vms` in the terminal).
    * Start each VM (`disposable-debian`, `work-debian`, `tor-vm-debian`) one by one.
    * Open the console for each, log in as `root` with the password `changeme`.
    * **Immediately change the root password** in every VM using the `passwd` command.

2.  **Master the Essential Shortcuts:** Your desktop is a tiling window manager controlled primarily by the keyboard for maximum speed and efficiency. Review the table in the next section.

3.  **Run Your First System Update:** Open a terminal (`Super` + `Enter`) and run the `update` command. This ensures all software is on the latest version and familiarizes you with the maintenance workflow.

4.  **Train Your Firewall:** During the first update, **OpenSnitch** will prompt you for permission for `pacman` and `paru` to connect to the internet. **Allow** these connections. This is the system learning what normal network activity looks like.

---
## 🖥️ Mastering the Desktop Environment (Hyprland)

Your environment is designed for focus and speed. Windows automatically arrange themselves to fill the screen. Use these keybinds to navigate. The `Super` key is the Windows key.



| Action                | Shortcut                    | Description                                                   |
| :-------------------- | :-------------------------- | :------------------------------------------------------------ |
| **Open Terminal** | `Super` + `Enter`           | The terminal (`kitty`) is your primary command center.        |
| **Launch Application**| `Super` + `D`               | Opens a menu (`rofi`) where you can type the name of any app. |
| **Close Window** | `Super` + `Q`               | Closes the currently active window.                           |
| **Move Focus** | `Super` + `Arrow Keys`      | Changes focus to the window on the left, right, up, or down.  |
| **Move Window** | `Super` + `Shift` + `Arrow Keys`| Swaps the active window's position with another.              |
| **Switch Workspace** | `Super` + `1`, `2`, `3`...  | Switches to a different virtual desktop.                      |
| **Move Window to WS** | `Super` + `Shift` + `1`, `2`... | Sends the active window to the specified workspace.           |
| **Lock Screen** | `Super` + `L`               | Engages the security screen locker (`swaylock`).              |

---
## 🛡️ The Core Defense: `guardian-cli` & The Security Levels

The `guardian-cli` utility, accessible via the `gdn-*` functions, is your switch for operational privacy. Each level provides clear feedback on what it enables and disables.

| Level (Command)      | Primary Use Case                | Technical Changes                                                                                                     |
| :------------------- | :------------------------------ | :-------------------------------------------------------------------------------------------------------------------- |
| **`gdn-standard`** 🟢 | **Fast & Secure Daily Use** | **ENABLES:** Direct Connection, Encrypted DNS (DNSCrypt). <br> **DISABLES:** Tor, Privoxy, MAC Randomization, Kill Switch. |
| **`gdn-secure`** 🟡   | **Selective Anonymous Browsing**| **ENABLES:** Tor Service, Privoxy Filter Proxy (on `127.0.0.1:8118`). <br> **DISABLES:** MAC Randomization, Kill Switch. |
| **`gdn-paranoid`** 🔴 | **Total Anonymity & Max Security**| **ENABLES:** MAC Randomization, System-wide Tor Transparent Proxy (Kill Switch). <br> **DISABLES:** Direct Connection, DNSCrypt. |

**How to Use the `secure` Level:**
1.  Run `gdn-secure` in a terminal.
2.  Open Firefox -> Settings -> Network Settings.
3.  Select "Manual proxy configuration".
4.  Enter `127.0.0.1` in the "HTTP Proxy" field and `8118` in the port.
5.  Check "Also use this proxy for HTTPS". Now, only Firefox will route its traffic through Tor.

---
## 📦 Compartmentalization: Isolating Tasks with VMs

The best security practice is to isolate your activities. Use the `overlord vm <profile>` command to create dedicated environments.

### `disposable-vm` (The Sandbox)
* **Use Case:** You've downloaded a suspicious file or need to visit an untrusted website. Instead of opening it on your main system, you start the `disposable-vm` and open it there. If it's malicious, it infects only the VM. When you shut it down, all traces are erased.
* **Characteristics:** Non-persistent. It resets to a clean state on every shutdown.

### `work-vm` (The Vault)
* **Use Case:** You're working on a development project with sensitive API keys and SSH credentials. Instead of storing them in your main home directory, you keep them exclusively within the `work-vm`. This isolates your professional credentials from everything else.
* **Characteristics:** Persistent. Your files and changes are saved.

### `tor-vm` (The Cloak)
* **Use Case:** You need to conduct sensitive research without linking it to your real identity. You start the `tor-vm`. Everything you do inside this machine—from web browsing to terminal commands—is **automatically and forcibly anonymized through the Tor network**.
* **Characteristics:** Persistent, with a pre-configured transparent Tor proxy and kill switch built into the VM itself. Includes a desktop environment with Tor Browser and I2P-configured Firefox.

### `cyberlab-vm` (The Arsenal)
* **Use Case:** A dedicated, persistent environment pre-configured for offensive security operations and penetration testing.
* **Characteristics:** Persistent. Requires a custom setup script (`vm-profiles/_cyberlab-assets/setup-cyberlab.sh`) to install tools.

---
## 🕵️ The Silent Sentinels: AIDE, OpenSnitch & LKRG

Your system actively defends itself. Learn to interpret its signals.

### OpenSnitch (The Network Guardian)
* **What it does:** The first time any program tries to connect to the internet, OpenSnitch will ask for your permission via a pop-up window.
* **How to use it:**
    * **✅ Good Example:** A prompt asks if `firefox.desktop` can connect to `github.com` on port 443 (HTTPS). This is normal. **Allow it.**
    * **❌ Bad Example:** A prompt asks if `/usr/bin/cat` can connect to a strange IP address. This is suspicious. **Deny it** and investigate.

### AIDE (The File Integrity Guardian)
* **What it does:** AIDE monitors critical system files for unauthorized changes.
* **The Workflow:**
    1.  **Periodic Check:** Once a week, run `aide-check`. No output means the system is clean.
    2.  **After a System Update:** It's **normal** for `aide-check` to report changed files after running `update`.
    3.  **Update the Baseline:** After confirming changes are legitimate, run `aide-update` to accept the new state.
    4.  **Red Flag:** If `aide-check` reports unexpected changes *without* an update, investigate immediately.

### LKRG (The Kernel Guardian)
* **What it does:** Linux Kernel Runtime Guard runs in the background, monitoring the kernel for signs of exploitation in real-time.
* **How to use it:** You don't need to do anything. If LKRG detects a critical threat, it may print messages to the kernel log (`journalctl -k`) and terminate the malicious process or trigger a system alert via the Guardian Daemon.

---
## ⚙️ Maintenance and System Management

Use the `overlord` command or `make` targets for system maintenance.

### System Updates
* **Command:** `update` (or `overlord update`, `make update`)
* **Actions:** Updates OS packages, AUR packages, Exploit-DB, and cleans orphan dependencies.
* **‼️ Mandatory Follow-up:** Always run `aide-update` after every update.

### Configuration Backups
* **Command:** `overlord backup` (or `make backup`)
* **Action:** Creates a timestamped, compressed snapshot of your `~/.config` directory in `~/.chimera_backups/`.

### Configuration Rollback
* **Command:** `overlord rollback` (or `make rollback`)
* **Action:** Restores your `~/.config` directory from the most recent backup snapshot. Use with caution.

### System Health Check
* **Command:** `overlord status` (or `make healthcheck`)
* **Action:** Runs a comprehensive check of critical security services and system status, outputting a JSON report.

---
## 📚 Further Reading

* **`README.md`:** Project overview and quick start guide.
* **`DEPLOYMENT_CHECKLIST.md`:** Detailed step-by-step installation instructions.
* **`PROJECT_INFO.md`:** High-level project specifications and goals.
* **`docs/architecture.md`:** In-depth explanation of the system's architecture.
* **`docs/incident_response.md`:** Playbook for handling security incidents.