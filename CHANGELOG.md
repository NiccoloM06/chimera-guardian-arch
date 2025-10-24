# Changelog

Tutte le modifiche significative a questo progetto saranno documentate in questo file.

Il formato si basa su [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
e questo progetto aderisce al [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased] - v51 (Dream Edition)

### Aggiunto
- **Strumenti di Prevenzione e Auditing Aggiuntivi:**
    - `fail2ban`: Installato e abilitato con una configurazione base (`jail.local`) per la protezione SSH.
    - `clamav`: Aggiunto per la scansione antivirus on-demand.
    - `chkrootkit`: Aggiunto per il rilevamento di rootkit.
    - `rkhunter`: Aggiunto come secondo scanner per rootkit.
    - `lynis`: Aggiunto per l'auditing di sicurezza approfondito del sistema.
- **`SYSTEM_GUIDE.md`:** Nuova sezione "11.0" per descrivere l'uso dei nuovi strumenti di auditing.
- **`README.md`:** Aggiornata la sezione "Funzionalità Principali" per includere i nuovi strumenti.

### Modificato
- **`scripts/ops/install.sh`:** Aggiornato per includere i nuovi pacchetti di sicurezza e la configurazione base di `fail2ban`.

---

## [50.0.0] - 2025-10-17 - Omega Foundation Edition

Questa versione implementa le fondamenta del sistema di monitoraggio in tempo reale e il TUI (Terminal User Interface) Control Center.

### Aggiunto
- **`scripts/daemons/guardian_daemon.sh`:** Servizio demone in background che monitora lo stato dei servizi critici (LKRG, OpenSnitch, Falco) e scrive in `/run/chimera/state.json`.
- **`tui/dashboard.sh`:** Un'interfaccia utente testuale interattiva (`make tui`) costruita con `gum` per gestire l'intero framework (aggiornamenti, livelli di sicurezza, VM, temi, etc.).
- **Integrazione Waybar:** Il file `config/waybar/config` è stato aggiornato con un modulo `custom/guardian` che legge lo stato del demone in tempo reale.
- **Stili Waybar:** Il file `config/waybar/style.css` è stato aggiornato con classi dinamiche (`.secure`, `.warn`, `.alert`) per il widget Guardian.

### Modificato
- **`scripts/ops/install.sh`:** Aggiornato per installare `gum` e `jq` (dipendenze per TUI/Daemon) e per installare e abilitare il nuovo `guardian-daemon.service`.
- **`Makefile`:** Aggiunto il target `tui` per lanciare la nuova dashboard.

---

## [49.0.0] - 2025-10-17 - Zenith II Edition

Questa versione espande massicciamente la suite di software preinstallato e rafforza il processo di installazione.

### Aggiunto
- **Controllo Dipendenze Robusto (`scripts/core/dependencies.sh`):** Un nuovo script che verifica e installa automaticamente le dipendenze essenziali del framework (`git`, `curl`, `aide`, `falco`, `auditd`, `rsync`, etc.) all'inizio dell'installazione.
- **Suite Privacy Avanzata:**
    - `protonmail-bridge` (AUR)
    - `torbrowser-launcher` (Official)
    - `firejail` (Official)
    - `veracrypt` (Official)
    - `mat2` (Official)
- **Suite Pentesting Essenziale:**
    - `metasploit` (BlackArch)
    - `burpsuite` (BlackArch)
    - `owasp-zap` (BlackArch)
    - `aircrack-ng` (Official)
    - `autopsy` (BlackArch)
    - `cutter` (Official)
    - `hash-identifier` (BlackArch)
    - `steghide` (Official)
    - `trivy` (Official)
- **Driver Wi-Fi Esterni (Opzionali):** Aggiunto uno step interattivo nello script di installazione (`STAGE 2.5`) per installare i driver DKMS comuni per adattatori Wi-Fi USB (Alfa, TP-Link, etc.).

### Modificato
- **`scripts/ops/install.sh`:** Ristrutturato per chiamare il nuovo script `dependencies.sh` e per includere tutti i nuovi pacchetti di sicurezza e privacy nelle liste di installazione `pacman` e `paru`.
- **`README.md` & `SYSTEM_GUIDE.md`:** Aggiornati per riflettere l'enorme ampliamento della suite software e le nuove funzionalità.

---

## [38.0.0] - 2025-10-17 - Overlord Edition

Refactoring architetturale completo in un framework SecureOps modulare e professionale.

### Aggiunto
- **CLI Unificata (`overlord`):** Nuovo entrypoint centrale per tutte le operazioni.
- **Libreria Core (`scripts/core/logger.sh`):** Logging centralizzato con timestamp e livelli.
- **Rollback Automatico (`trap 'rollback' ERR`):** Gestione sicura degli errori.
- **Controllo Integrità (`checksums.txt`):** Verifica dei checksum all'avvio.
- **Modulo AI (`ai/anomaly.py`):** Modello base di Isolation Forest per l'analisi dei log.
- **Configurazione Dichiarativa (`config/guardian/profiles/`):** Profili di sicurezza definiti in YAML.
- **Prompt Powerlevel10k (`.p10k.zsh`):** Aggiunto tema preconfigurato in stile Kali.
- **Documentazione Professionale:** Aggiunti `system_overview.md`, `architecture.md`, `incident_response.md`.

### Modificato
- **`Makefile`:** Sostituito dal CLI `overlord` come interfaccia utente principale (anche se il `Makefile` può rimanere per le operazioni di build).
- **Struttura Script:** Rifattorizzata in `scripts/core`, `scripts/ops`, `scripts/modules`.

---

## [Versioni Precedenti] - v1.0.0 a v37.0.0

### Aggiunto
- Concetto iniziale di script post-installazione.
- Hardening di base (`linux-hardened`, `ufw`, `aide`, `opensnitch`).
- Integrazione BlackArch.
- Ambiente desktop Hyprland, Waybar, Rofi, Kitty.
- `guardian-ctl` per 3 livelli di sicurezza.
- Suite di virtualizzazione (`vm-profiles`).
- Suite software base per sviluppatori.
- Ottimizzazioni performance NVMe.
- Funzioni `zsh_functions` e `fastfetch`.
- BTRFS e `snapper` per snapshot.