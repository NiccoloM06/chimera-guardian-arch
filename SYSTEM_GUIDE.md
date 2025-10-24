# 📚 The Complete User Guide for Chimera Guardian Arch

Welcome to Chimera Guardian Arch. This is not just an operating system; it's a security platform designed to give you maximum control. This guide is your primary operational manual for understanding and mastering every component of your new environment.

---
## 🚀 Your First Steps: Post-Installation Checklist

You've completed the installation (`make install`) and finalization (`make finalize`). Excellent work. Now, follow this checklist to make the system truly yours and secure its components.

1.  **Secure Your Virtual Machines:**
    * Launch the "Virtual Machine Manager" (run `vms` in the terminal).
    * Start each VM (`disposable-debian`, `work-debian`, `tor-vm-debian`, `cyberlab-env`) one by one.
    * Open the console for each, log in as `root` with the password `changeme`.
    * **Immediately change the root password** in every VM using the `passwd` command.

2.  **Master the Essential Shortcuts:** Your desktop is a tiling window manager controlled primarily by the keyboard for maximum speed and efficiency. Review the table in the next section.

3.  **Run Your First System Update:** Open a terminal (`Super` + `Enter`) and run the `update` command. This ensures all software is on the latest version and familiarizes you with the maintenance workflow.

4.  **Train Your Firewall:** During the first update or when launching applications that need network access (like Firefox), **OpenSnitch** will prompt you for permission. **Allow** these connections. This is the system learning what normal network activity looks like.

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
| **Screenshot Full** | `Print Screen`              | Saves a screenshot to `~/Pictures`.                           |
| **Screenshot Region** | `Shift` + `Print Screen`    | Allows selecting an area to screenshot.                       |
| **Clipboard History** | `Super` + `V`               | Opens Rofi with your clipboard history.                       |

---
## 🛡️ The Core Defense: `guardian-cli` & The Security Levels

The `guardian-cli` utility, accessible via the `gdn-*` functions, is your switch for operational privacy. Each level provides clear feedback on what it enables and disables.

| Level (Command)      | Primary Use Case                | Technical Changes Notified                                                                                   |
| :------------------- | :------------------------------ | :----------------------------------------------------------------------------------------------------------- |
| **`gdn-standard`** 🟢 | **Fast & Secure Daily Use** | **ENABLES:** Direct Connection, Encrypted DNS (DNSCrypt). <br> **DISABLES:** Tor, Privoxy, MAC Spoof, Kill Switch. |
| **`gdn-secure`** 🟡   | **Selective Anonymous Browsing**| **ENABLES:** Tor Service, Privoxy Filter Proxy (on `127.0.0.1:8118`). <br> **DISABLES:** MAC Spoof, Kill Switch.    |
| **`gdn-paranoid`** 🔴 | **Total Anonymity & Max Security**| **ENABLES:** MAC Spoofing, System-wide Tor Transparent Proxy (Kill Switch). <br> **DISABLES:** Direct Connection, DNSCrypt. |
| **`gdn-cyberlab`** 🔬 | **Offensive Security Ops** | **ENABLES:** MAC Spoofing, Tor/Privoxy available. <br> **DISABLES:** DNSCrypt, Kill Switch. Firewall allows all outbound. |

**How to Use the `secure` Level:**
1.  Run `gdn-secure` in a terminal.
2.  Open Firefox -> Settings -> Network Settings.
3.  Select "Manual proxy configuration".
4.  Enter `127.0.0.1` in the "HTTP Proxy" field and `8118` in the port.
5.  Check "Also use this proxy for HTTPS". Now, only Firefox will route its traffic through Tor.

---
## 📦 Compartmentalization: Isolating Tasks with VMs

The best security practice is to isolate your activities. Use the `make vm profile=<name>` command to create dedicated environments.

### `disposable-vm` (The Sandbox)
* **Use Case:** Analyzing suspicious files, visiting untrusted websites.
* **Characteristics:** Non-persistent. Resets on every shutdown.
* **Creation:** `make vm profile=disposable`

### `work-vm` (The Vault)
* **Use Case:** Isolated development environment, managing sensitive credentials.
* **Characteristics:** Persistent. Changes are saved.
* **Creation:** `make vm profile=work`

### `tor-vm` (The Cloak)
* **Use Case:** Activities requiring maximum anonymity (sensitive research, etc.).
* **Characteristics:** Persistent. **All traffic** is automatically forced through Tor. Includes a desktop environment with Tor Browser and I2P-configured Firefox.
* **Creation:** `make vm profile=tor` (requires manual setup inside VM on first boot).

### `cyberlab-vm` (The Arsenal)
* **Use Case:** Dedicated environment for offensive security tools and penetration testing.
* **Characteristics:** Persistent. Requires a custom setup script (`vm-profiles/_cyberlab-assets/setup-cyberlab.sh`) to install tools.
* **Creation:** `make vm profile=cyberlab`

Manage your VMs using the **"Virtual Machine Manager"** application (run `vms`).

---
## 🕵️ The Silent Sentinels: AIDE, OpenSnitch, Falco & LKRG

Your system actively defends itself. Learn to interpret its signals.

### OpenSnitch (The Network Guardian)
* **What it does:** Prompts for permission the first time any program tries to connect to the internet.
* **How to use it:** **Allow** connections only for applications you trust and expect to access the network (e.g., Firefox). **Deny** anything unexpected or suspicious (e.g., `cat` trying to connect to a remote IP).

### AIDE (The File Integrity Guardian)
* **What it does:** Monitors critical system files for unauthorized changes.
* **The Workflow:**
    1.  **Periodic Check:** Run `aide-check` weekly. No output means the system is clean.
    2.  **After System Update:** It's **normal** for `aide-check` to report changed files after running `update`.
    3.  **Update Baseline:** After confirming changes are legitimate, run `aide-update` to accept the new state.
    4.  **Red Flag:** If `aide-check` reports unexpected changes *without* an update, investigate immediately – it's a strong indicator of compromise. Refer to `docs/incident_response.md`.

### Falco & auditd (The Syscall Auditors)
* **What they do:** Run in the background, monitoring system calls for suspicious behavior based on predefined rules.
* **How to use it:** You don't interact directly. If Falco detects a high-severity event, the **Guardian Daemon** will notice and potentially trigger an alert (desktop notification or change the Waybar icon color).

### LKRG (The Kernel Guardian)
* **What it does:** Linux Kernel Runtime Guard runs silently, monitoring the kernel itself for signs of exploitation in real-time.
* **How to use it:** You don't need to do anything. If LKRG detects a critical threat, it will print messages to the kernel log (`journalctl -k`) and may trigger an alert via the Guardian Daemon.

---
## ⚙️ Maintenance and System Management

Use the `make` targets or the `overlord tui` for system maintenance.

### System Updates
* **Command:** `update` (or `make update`)
* **Actions:** Updates OS packages, AUR packages, Exploit-DB, and cleans orphan dependencies.
* **‼️ Mandatory Follow-up:** Always run `aide-update` after every update.

### Configuration Backups
* **Command:** `make backup`
* **Action:** Creates a timestamped, compressed snapshot (`.tar.zst`) of your `~/.config` directory in `~/.chimera_backups/`.

### Configuration Rollback
* **Command:** `make rollback`
* **Action:** Restores your `~/.config` directory from the most recent backup snapshot.

### System Health Check
* **Command:** `make healthcheck`
* **Action:** Runs a comprehensive check of critical security services and system status.

---

## 10.0 Expanding Your Arsenal: The Pantheon Toolkit

Your Chimera system is the foundation. This section is a curated strategic guide to the elite tools required for professional security assessment, all installable from the Arch, BlackArch, or AUR repositories.

---

### 🌐 10.1 Information Gathering & OSINT
This phase is about passively and actively collecting intelligence on a target before an engagement.

| Tool | Repository | Description | Installation Command |
| :--- | :--- | :--- | :--- |
| **Nmap** | Arch Official | **The foundational tool for network reconnaissance.** The 'sonar' for a network: discovers hosts, open ports, services, and operating systems. | `sudo pacman -S nmap` |
| **Masscan** | BlackArch | **An asynchronous, extremely fast port scanner.** Designed for speed, it can scan vast network ranges (even the entire internet) for specific open ports in minutes. | `sudo pacman -S masscan` |
| **theHarvester**| BlackArch | **An Open Source Intelligence (OSINT) aggregator.** It gathers emails, subdomains, employee names, and open ports from public sources like search engines (Google, Bing) and security services (Shodan, Hunter.io). | `sudo pacman -S theharvester` |
| **subfinder** | BlackArch | **A high-performance, passive subdomain enumeration tool.** It uses multiple online sources to discover subdomains without sending any traffic to the target's servers, making it stealthy and fast. | `sudo pacman -S subfinder` |
| **httpx** | BlackArch | **A multi-purpose HTTP toolkit.** Often used after `subfinder`, it probes a list of hosts to determine which are running live web servers, gathers titles, status codes, and other useful metadata for further analysis. | `sudo pacman -S httpx` |
| **Amass** | BlackArch | **The most in-depth network mapping and external asset discovery tool.** It goes far beyond simple subdomain enumeration, using web scraping, certificate analysis, and API lookups to build a comprehensive map of a target's infrastructure. | `sudo pacman -S amass` |
| **dnsrecon** | BlackArch | **A powerful script for enumerating DNS records.** It performs zone transfers, brute-forces subdomains, and queries for all common record types (MX, SOA, A, AAAA, TXT, SRV). | `sudo pacman -S dnsrecon` |
| **Fierce** | BlackArch | A classic and reliable DNS reconnaissance tool, one of the originals in this space. | `sudo pacman -S fierce` |
| **Shodan (CLI)** | BlackArch | A command-line client for the Shodan search engine, allowing you to find exposed IoT devices, industrial control systems, and misconfigured services. | `sudo pacman -S shodan` |
| **Maltego** | BlackArch | **The premier graphical OSINT tool for link analysis.** It visualizes relationships between pieces of information (people, domains, companies, documents), helping you uncover hidden connections. | `sudo pacman -S maltego` |

---

### 🔬 10.2 Vulnerability Analysis
This phase involves actively probing systems for known weaknesses.

| Tool | Repository | Description | Installation Command |
| :--- | :--- | :--- | :--- |
| **Nuclei** | BlackArch | **A modern, template-based vulnerability scanner.** Its power lies in a huge community-driven repository of YAML templates that check for thousands of specific CVEs, misconfigurations, and security flaws. | `sudo pacman -S nuclei` |
| **SQLMap** | BlackArch | **The definitive tool for detecting and exploiting SQL injection vulnerabilities.** It can automate the entire process, from finding an injectable parameter to dumping database contents, and even achieving remote code execution. | `sudo pacman -S sqlmap` |
| **Nikto** | BlackArch | **A classic web server vulnerability scanner.** It checks for over 6700 potentially dangerous files/CGIs, outdated server versions, and server-specific problems. While noisy, it's excellent for initial assessments. | `sudo pacman -S nikto` |
| **Nessus** | AUR | **A leading commercial vulnerability scanner.** Known for its comprehensive plugin library and detailed reports, it's an industry standard for compliance and enterprise-level network assessments. | `paru -S nessus` |
| **GDB** | Arch Official | **The GNU Debugger.** While not a "scanner," it is the essential tool for analyzing program crashes, reverse engineering binaries, and understanding memory corruption vulnerabilities found during exploit development. | `sudo pacman -S gdb` |
| **Trivy** | Arch Official | **A comprehensive vulnerability scanner for containers.** Already installed, it is essential for checking Docker images and filesystems for known CVEs. | `Already Installed` |

---

### 🕸️ 10.3 Web Application Analysis
This phase focuses on in-depth testing of web applications, often with a proxy.

| Tool | Repository | Description | Installation Command |
| :--- | :--- | :--- | :--- |
| **Burp Suite** | BlackArch | **The industry-standard proxy for web application penetration testing.** It sits between your browser and the server, allowing you to intercept, inspect, and modify all HTTP/S traffic. | `Already Installed` |
| **OWASP ZAP** | BlackArch | **The best open-source alternative to Burp Suite.** Maintained by OWASP, it offers similar proxy capabilities and has powerful automation and scripting features. | `Already Installed` |
| **ffuf** | BlackArch | **Blazing fast, content-discovery web fuzzer.** Written in Go, it's designed for one job: rapidly brute-forcing directories, files, and subdomains to uncover hidden endpoints. | `sudo pacman -S ffuf` |
| **GoBuster** | BlackArch | **A versatile tool for bruteforcing URIs, DNS subdomains, and cloud storage buckets.** A fast, simple, and effective content discovery tool. | `sudo pacman -S gobuster` |
| **dirsearch** | BlackArch | A classic, powerful tool for bruteforcing web server directories and files. | `sudo pacman -S dirsearch` |
| **WhatWeb** | BlackArch | Identifies web technologies including CMS, frameworks, and analytics tools. | `sudo pacman -S whatweb` |
| **XSStrike** | BlackArch | **An advanced Cross-Site Scripting (XSS) detection and exploitation suite.** It goes beyond simple payloads by analyzing context and fuzzing parameters. | `sudo pacman -S xsstrike` |
| **NoSQLMap** | BlackArch | A tool for auditing and automating injection attacks on NoSQL databases. | `sudo pacman -S nosqlmap` |
| **Wfuzz** | BlackArch | A versatile web application fuzzer capable of complex payload generation. | `sudo pacman -S wfuzz` |

---

### 🔑 10.4 Password Attacks
This phase involves recovering credentials from hashes or attacking login portals.

| Tool | Repository | Description | Installation Command |
| :--- | :--- | :--- | :--- |
| **Hashcat** | BlackArch | **The world's fastest password cracker.** It leverages the power of GPUs to perform billions of hash calculations per second for offline cracking. | `sudo pacman -S hashcat` |
| **John the Ripper**| BlackArch | **A classic, highly flexible password cracker.** While Hashcat excels with GPUs, John is a master of CPU-based cracking and supports a massive number of hash types. | `sudo pacman -S john` |
| **Hydra** | BlackArch | **Fast network logon cracker for "online" attacks.** It performs dictionary or brute-force attacks against login portals for services like SSH, FTP, Telnet, web forms, etc. | `sudo pacman -S hydra` |
| **Kerbrute** | BlackArch | **A tool for bruteforcing and enumerating valid Active Directory accounts via Kerberos.** A key tool in the initial stages of an internal pentest. | `sudo pacman -S kerbrute` |
| **Crunch** | BlackArch | An advanced wordlist generator for creating custom password lists based on defined rules. | `sudo pacman -S crunch` |
| **Medusa** | BlackArch | Another fast, parallel, modular network logon cracker. | `sudo pacman -S medusa` |
| **Hash Identifier**| BlackArch | Helps identify the type of hash you are trying to crack. | `Already Installed` |
| **SecLists** | BlackArch | **The definitive collection of wordlists.** Provides lists for passwords, usernames, fuzzing, etc. Includes `rockyou.txt`. | `sudo pacman -S seclists` |

---

### 📶 10.5 Wireless & Network Attacks
This phase focuses on Wi-Fi auditing and Man-in-the-Middle (MITM) attacks.

| Tool | Repository | Description | Installation Command |
| :--- | :--- | :--- | :--- |
| **Aircrack-ng Suite**| Arch Official | **The complete suite for auditing Wi-Fi networks (WEP, WPA/WPA2).** Includes `airmon-ng`, `airodump-ng`, `aireplay-ng`. | `Already Installed` |
| **Bettercap** | BlackArch | **The "Swiss Army Knife" for network attacks.** A powerful, modular, and portable framework perfect for Man-in-the-Middle (MITM) attacks. | `sudo pacman -S bettercap` |
| **Wireshark** | Arch Official | The definitive network protocol analyzer. (Already installed) | `Already Installed` |
| **tcpdump** | Arch Official | The classic command-line packet analyzer for network monitoring. | `sudo pacman -S tcpdump` |
| **Kismet** | BlackArch | A powerful wireless network detector, sniffer, and intrusion detection system. | `sudo pacman -S kismet` |
| **hcxtools** | BlackArch | An advanced toolset for capturing and cracking WPA handshakes from client devices. | `sudo pacman -S hcxtools` |
| **Scapy** | BlackArch | A powerful Python-based packet manipulation program for crafting custom packets. | `sudo pacman -S scapy` |
| **Ettercap** | BlackArch | A classic graphical suite for Man-in-the-Middle attacks on a LAN. | `sudo pacman -S ettercap` |

---

### 💥 10.6 Exploitation & Post-Exploitation
This phase involves gaining and maintaining access to a compromised system.

| Tool | Repository | Description | Installation Command |
| :--- | :--- | :--- | :--- |
| **Metasploit** | BlackArch | **The world's most popular exploitation framework.** A massive database of exploits, payloads, and auxiliary modules. Essential. | `Already Installed` |
| **SearchSploit** | Arch Official | Offline command-line search for Exploit-DB. (Already installed) | `Already Installed` |
| **Impacket** | BlackArch | **A collection of Python classes for network protocols.** This is the secret weapon for pentesters in Windows environments, providing tools like `psexec.py`, `secretsdump.py`, etc. | `sudo pacman -S impacket` |
| **evil-winrm** | BlackArch | **The ultimate WinRM shell for hacking Windows.** Provides a powerful, fully-featured PowerShell session with command completion. | `sudo pacman -S evil-winrm` |
| **Responder** | BlackArch | A tool for LLMNR, NBT-NS, and mDNS poisoning attacks to capture hashes on a local network. | `sudo pacman -S responder` |
| **BloodHound** | BlackArch | **Visually maps Active Directory trust relationships** to find hidden attack paths to Domain Admin. | `sudo pacman -S bloodhound` |
| **Mimikatz** | BlackArch | **The quintessential tool for extracting plaintext passwords, hashes, and Kerberos tickets** from memory on Windows systems. | `sudo pacman -S mimikatz` |
| **Chisel** | BlackArch | A fast TCP/UDP tunnel, transported over HTTP, secured via SSH. Excellent for pivoting. | `sudo pacman -S chisel` |

---

### 🔩 10.7 Reverse Engineering & Forensics
This phase involves analyzing malware, binaries, and disk images.

| Tool | Repository | Description | Installation Command |
| :--- | :--- | :--- | :--- |
| **Ghidra** | BlackArch | The NSA's open-source, feature-rich software reverse engineering framework. | `sudo pacman -S ghidra` |
| **radare2** | Arch Official | A powerful, command-line framework for reverse engineering and analyzing binaries. | `sudo pacman -S radare2` |
| **Cutter** | Arch Official | A graphical user interface for radare2. (Already installed) | `Already Installed` |
| **Autopsy** | BlackArch | **The premier open-source graphical interface for digital forensics analysis** of disk images. | `Already Installed` |
| **Volatility3** | BlackArch | The industry standard framework for memory forensics and volatile data analysis. | `sudo pacman -S volatility3` |
| **Steghide** | Arch Official | A classic steganography tool for hiding data within images/audio. | `Already Installed` |
| **Binwalk** | Arch Official | A tool for analyzing, reverse engineering, and extracting firmware images. | `sudo pacman -S binwalk` |
| **GDB** | Arch Official | The GNU Debugger. (Already installed, see Vulnerability Analysis) | `sudo pacman -S gdb` |

---
## 11.0 Additional Security & Auditing Tools

Beyond the offensive tools, Chimera includes several tools for periodic checks and specific threat mitigation.

### 11.1 Malware & Rootkit Detection
* **ClamAV:** An open-source antivirus engine. Useful for scanning downloaded files.
    * **Update Database:** `sudo freshclam`
    * **Scan a Directory:** `clamscan -r /path/to/directory`
* **chkrootkit & rkhunter:** Tools to detect known rootkits. Run them periodically.
    * **Run Checks:** `sudo chkrootkit` or `sudo rkhunter --check`

### 11.2 Intrusion Prevention (Fail2ban)
* **What it does:** Monitors log files for repeated failed login attempts (initially configured for SSH) and automatically blocks the offending IP addresses.
* **Status:** Check blocked IPs with `sudo fail2ban-client status sshd`.

### 11.3 Security Auditing (Lynis)
* **What it does:** Performs an extensive security scan of your system and provides a report with findings and actionable suggestions.
* **Usage:** Run periodically to assess and improve your system's posture: `sudo lynis audit system`.

---
## 12.0 Additional Privacy Tools

* **Proton Mail Bridge:** Allows you to use a desktop email client with your end-to-end encrypted Proton Mail account.
* **VeraCrypt:** A tool for creating and managing cross-platform encrypted volumes (containers).
* **MAT2:** A command-line tool to remove sensitive metadata from your files before sharing them.
    * **Usage:** `mat2 your_file.jpg` (creates `your_file.cleaned.jpg`)