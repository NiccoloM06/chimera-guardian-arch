#!/usr/bin/env bash
set -euo pipefail

# =======================================================================================
#  SCRIPT DI INSTALLAZIONE PRINCIPALE | CHIMERA GUARDIAN ARCH (v51 Dream/Zenith II)
#  Installa tutti i pacchetti, configura i servizi e chiama i moduli di hardening.
# =======================================================================================

# --- Carica la libreria condivisa ---
# shellcheck source=../core/logger.sh
source "$(dirname "$0")/../core/logger.sh"

# --- Verifica il contesto di esecuzione ---
if [ "$(id -u)" -ne 0 ]; then
    log "ERROR" "Questo script deve essere eseguito come root o con sudo."
    exit 1
fi
if [ -z "${CHIMERA_USER:-}" ]; then
    log "ERROR" "Variabile CHIMERA_USER non definita. Assicurati che .env sia configurato."
    exit 1
fi
HOME_DIR=$(getent passwd "$CHIMERA_USER" | cut -d: -f6)
if [ -z "$HOME_DIR" ]; then
    log "ERROR" "Impossibile determinare HOME_DIR per l'utente '$CHIMERA_USER'."
    exit 1
fi

log "INFO" "Avvio dell'installazione principale del sistema per l'utente: $CHIMERA_USER"
log "INFO" "Il log completo dell'installazione è scritto in: $LOG_FILE"

# --- Esegui Controllo Dipendenze ---
log "INFO" "Verifica delle dipendenze del framework..."
bash "$CHIMERA_ROOT/scripts/core/dependencies.sh"
log "SUCCESS" "Controllo dipendenze completato."

# --- Controllo Integrità Script ---
log "INFO" "Verifica dell'integrità degli script..."
if ! sha256sum -c --status "$CHIMERA_ROOT/checksums.txt"; then
    log "ERROR" "Checksum validation failed! File critici modificati. Annullamento."
    exit 1 # Il trap attiverà il rollback
fi
log "SUCCESS" "Controllo integrità superato."

# --- Configurazione Logrotate ---
log "INFO" "Installazione e configurazione di logrotate..."
safe_exec "Installazione logrotate" pacman -S --noconfirm --needed logrotate
safe_exec "Copia configurazione logrotate" cp "$CHIMERA_ROOT/config/logrotate/chimera" /etc/logrotate.d/chimera

#--------------------------------------------------------------------------------
# STAGE 0: SELEZIONE DRIVER (INTERATTIVA)
#--------------------------------------------------------------------------------
log "INFO" "--- STAGE 0: SELEZIONE DRIVER HARDWARE ---"
safe_exec "Aggiornamento repository" pacman -Syu --noconfirm
safe_exec "Installazione firmware base" pacman -S --noconfirm linux-firmware sof-firmware

# Wi-Fi / Bluetooth
read -r -p "Installare i driver comuni per Wi-Fi (Broadcom) e Bluetooth? (y/N) " install_wifi
if [[ "$install_wifi" =~ ^([yY])$ ]]; then
    safe_exec "Installazione driver Wi-Fi/Bluetooth" pacman -S --noconfirm broadcom-wl-dkms bluez bluez-utils
fi

# Driver Grafici (Selezione Multipla)
log "INFO" "Selezione driver grafici (puoi scegliere più opzioni):"
GFX_DRIVERS="mesa" # Base

read -r -p "Installare driver Intel (mesa)? [Y/n] " install_intel
if [[ ! "$install_intel" =~ ^([nN])$ ]]; then log "INFO" "Driver Intel (mesa) selezionati."; fi

read -r -p "Installare driver AMD (mesa + xf86-video-amdgpu)? (y/N) " install_amd
if [[ "$install_amd" =~ ^([yY])$ ]]; then
    GFX_DRIVERS+=" xf86-video-amdgpu"
    log "INFO" "Driver AMD selezionati."
fi

read -r -p "Installare driver NVIDIA proprietari (nvidia-dkms)? (y/N) " install_nvidia
if [[ "$install_nvidia" =~ ^([yY])$ ]]; then
    GFX_DRIVERS+=" nvidia-dkms"
    log "INFO" "Driver NVIDIA selezionati."
fi

safe_exec "Installazione driver grafici selezionati" pacman -S --noconfirm "$GFX_DRIVERS"
log "SUCCESS" "Installazione driver grafici configurata."
sleep 1

#--------------------------------------------------------------------------------
# STAGE 1: COMPONENTI CORE DI SICUREZZA
#--------------------------------------------------------------------------------
log "INFO" "--- STAGE 1: INSTALLAZIONE COMPONENTI CORE DI SICUREZZA ---"
safe_exec "Installazione Kernel, UFW, DNSCrypt, I2P" pacman -S --noconfirm linux-hardened linux-hardened-headers ufw dnscrypt-proxy i2p

log "INFO" "Configurazione DNS Crittografato (DNSCrypt)..."
safe_exec "Abilitazione servizio DNSCrypt" systemctl enable dnscrypt-proxy.service
safe_exec "Impostazione resolver DNSCrypt" bash -c 'chattr -i /etc/resolv.conf 2>/dev/null || true; echo "nameserver 127.0.0.1" > /etc/resolv.conf && chattr +i /etc/resolv.conf'

log "INFO" "Configurazione Firewall (UFW)..."
safe_exec "Abilitazione servizio UFW" systemctl enable ufw.service
safe_exec "Impostazione policy UFW" bash -c 'ufw --force enable && ufw default deny incoming && ufw default allow outgoing'

log "INFO" "Abilitazione Servizio I2P..."
safe_exec "Abilitazione servizio I2P" systemctl enable i2p.service
log "SUCCESS" "Componenti core di sicurezza installati e configurati."

#--------------------------------------------------------------------------------
# STAGE 2: SETUP AUR & REPOSITORY BLACKARCH
#--------------------------------------------------------------------------------
log "INFO" "--- STAGE 2: CONFIGURAZIONE AUR E BLACKARCH ---"
safe_exec "Installazione base-devel" pacman -S --noconfirm base-devel

log "INFO" "Installazione AUR Helper (paru)..."
safe_exec "Clonazione e build di paru" sudo -u "$CHIMERA_USER" bash -c 'cd /tmp && git clone --depth=1 https://aur.archlinux.org/paru.git && cd paru && makepkg -si --noconfirm'

log "INFO" "Aggiunta repository BlackArch..."
cd /tmp
safe_exec "Download script BlackArch strap" curl -sO https://blackarch.org/strap.sh
# Esegui qui il checksum se hai il valore
safe_exec "Esecuzione script BlackArch strap" bash -c 'chmod +x strap.sh && ./strap.sh'
safe_exec "Aggiornamento repository post-BlackArch" pacman -Syu --noconfirm
log "SUCCESS" "AUR helper (paru) e repository BlackArch pronti."

#--------------------------------------------------------------------------------
# STAGE 2.5: OPTIONAL EXTERNAL WIFI DRIVERS (AUR)
#--------------------------------------------------------------------------------
log "INFO" "--- STAGE 2.5: DRIVER WI-FI ESTERNI OPZIONALI ---"
read -r -p "Vuoi tentare l'installazione dei driver comuni per adattatori USB Wi-Fi ESTERNI (es. Alfa, TP-Link, Panda)? (y/N) " install_external_wifi
if [[ "$install_external_wifi" =~ ^([yY])$ ]]; then
    log "INFO" "Tentativo di installazione driver Wi-Fi esterni da AUR..."
    EXTERNAL_WIFI_PACKAGES=(
        "rtl88xxau-aircrack-dkms-git"
        "rtl8812au-dkms-git"
        "rtl8188eus-dkms"
        "r8168-dkms"
        "rt3070-dkms"
        "mt7610u_wifi_sta_dkms"
        "mt7612u_wifi_sta_dkms"
        "carl9170-dkms"
    )
    safe_exec "Installazione driver Wi-Fi esterni via paru" sudo -u "$CHIMERA_USER" --preserve-env=CHIMERA_ROOT bash -c "paru -S --noconfirm --needed ${EXTERNAL_WIFI_PACKAGES[*]}" || log "WARN" "Alcuni driver Wi-Fi esterni potrebbero aver fallito l'installazione."
    log "SUCCESS" "Tentativo di installazione driver Wi-Fi esterni completato."
else
    log "INFO" "Installazione driver Wi-Fi esterni saltata."
fi
sleep 1

#--------------------------------------------------------------------------------
# STAGE 3: SUITE SOFTWARE PROFESSIONALE (AUR)
#--------------------------------------------------------------------------------
log "INFO" "--- STAGE 3: INSTALLAZIONE SOFTWARE PROFESSIONALE DA AUR ---"
safe_exec "Installazione suite software AUR" sudo -u "$CHIMERA_USER" --preserve-env=CHIMERA_ROOT bash -c 'paru -S --noconfirm protonmail-bridge visual-studio-code-bin postman-bin lazygit obsidian signal-desktop lkrg-dkms opensnitch-ebpf-module opensnitch btrfs-assistant btrfs-assistant-grub sddm-sugar-candy-git'
log "SUCCESS" "Suite software AUR installata."

#--------------------------------------------------------------------------------
# STAGE 4: DESKTOP, DEV, SECURITY & PRIVACY SUITE (REPO UFFICIALI/BLACKARCH)
#--------------------------------------------------------------------------------
log "INFO" "--- STAGE 4: INSTALLAZIONE AMBIENTE DESKTOP E APPLICAZIONI CORE ---"
safe_exec "Installazione applicazioni core" pacman -S --noconfirm \
    clamav chkrootkit rkhunter fail2ban lynis \
    gum jq \
    torbrowser-launcher firejail gnupg \
    metasploit burpsuite owasp-zap aircrack-ng autopsy cutter hash-identifier steghide trivy \
    openvpn wireguard-tools networkmanager-openvpn veracrypt mat2 \
    bibata-cursor-theme fastfetch zsh-theme-powerlevel10k \
    neovim wireshark-qt keepassxc zeal docker \
    vim chromium firefox hyprland sddm kitty waybar rofi mako swaybg swaylock \
    pipewire wireplumber pavucontrol thunar mpv btop networkmanager network-manager-applet \
    blueman tlp mousepad grim slurp cliphist loupe evince \
    ttf-jetbrains-mono-nerd papirus-icon-theme zsh zsh-completions zsh-syntax-highlighting zsh-autosuggestions \
    qemu-full virt-manager dnsmasq ebtables libguestfs \
    apparmor tor privoxy aide bubblewrap bleachbit macchanger iptables \
    gparted cdrtools snapper btrfs-progs audit falco \
    inotify-tools rsync pacman-contrib
log "SUCCESS" "Ambiente desktop e applicazioni core installate."

#--------------------------------------------------------------------------------
# STAGE 5: CONFIGURAZIONE SERVIZI DI SISTEMA E UTENTE
#--------------------------------------------------------------------------------
log "INFO" "--- STAGE 5: ABILITAZIONE SERVIZI E CONFIGURAZIONE TEMA/UTENTE ---"
safe_exec "Abilitazione SDDM" systemctl enable sddm.service
safe_exec "Abilitazione NetworkManager" systemctl enable NetworkManager.service
if [[ "$install_wifi" =~ ^([yY])$ ]]; then
    safe_exec "Abilitazione Bluetooth" systemctl enable bluetooth.service
fi
safe_exec "Abilitazione TLP" systemctl enable tlp.service
safe_exec "Abilitazione Libvirt" systemctl enable libvirtd.service
safe_exec "Abilitazione Docker" systemctl enable docker.service
safe_exec "Abilitazione Tor" systemctl enable tor.service
safe_exec "Abilitazione AppArmor" systemctl enable apparmor.service
safe_exec "Abilitazione OpenSnitch" systemctl enable opensnitchd.service
safe_exec "Abilitazione fstrim timer" systemctl enable fstrim.timer
safe_exec "Abilitazione Fail2ban" systemctl enable fail2ban.service

# Configura tema SDDM
log "INFO" "Configurazione tema SDDM..."
mkdir -p /etc/sddm.conf.d
cat <<EOF > /etc/sddm.conf.d/theme.conf
[Theme]
Current=sugar-candy
EOF

# Configura Utente
log "INFO" "Configurazione gruppi utente e shell..."
safe_exec "Aggiunta utente ai gruppi libvirt/docker" usermod -aG libvirt,docker "$CHIMERA_USER"
safe_exec "Impostazione shell utente a Zsh" chsh -s /bin/zsh "$CHIMERA_USER"

# Setup directory e wallpaper
mkdir -p /usr/share/backgrounds/chimera
safe_exec "Download wallpaper" wget -qO /usr/share/backgrounds/chimera/chimera-wallpaper.png https://www.kali.org/images/wallpapers/kali-dragon-16x9.png
mkdir -p "$HOME_DIR/Pictures"
chown -R "$CHIMERA_USER":"$CHIMERA_USER" "$HOME_DIR/Pictures"

# Configura BTRFS Snapshots (se applicabile)
if [ "$(findmnt -no FSTYPE /)" = 'btrfs' ]; then
    log "INFO" "Configurazione servizio snapshot BTRFS (Snapper)..."
    safe_exec "Creazione configurazione Snapper" snapper -c root create-config /
    safe_exec "Abilitazione timer Snapper" systemctl enable snapper-timeline.timer snapper-cleanup.timer
    safe_exec "Regolazione retention Snapper (hourly)" sed -i 's/TIMELINE_LIMIT_HOURLY=\"10\"/TIMELINE_LIMIT_HOURLY=\"5\"/' /etc/snapper/configs/root
    safe_exec "Regolazione retention Snapper (daily)" sed -i 's/TIMELINE_LIMIT_DAILY=\"10\"/TIMELINE_LIMIT_DAILY=\"7\"/' /etc/snapper/configs/root
fi
log "SUCCESS" "Servizi di sistema abilitati, tema e utente configurati."

#--------------------------------------------------------------------------------
# STAGE 6: CHIAMATA MODULI SPECIALIZZATI (HARDENING, AUDIT/FALCO)
#--------------------------------------------------------------------------------
log "INFO" "--- STAGE 6: APPLICAZIONE HARDENING DI SISTEMA E AUDITING ---"
safe_exec "Esecuzione modulo di hardening" bash "$CHIMERA_ROOT/scripts/modules/hardening_system.sh"
safe_exec "Esecuzione modulo installazione audit/Falco" bash "$CHIMERA_ROOT/scripts/modules/install_audit_falco.sh"

#--------------------------------------------------------------------------------
# STAGE 7: CONFIGURAZIONI FINALI DI SISTEMA
#--------------------------------------------------------------------------------
log "INFO" "--- STAGE 7: APPLICAZIONE CONFIGURAZIONI FINALI ---"
# Forwarding Privoxy -> Tor
if ! grep -q "forward-socks5 / 127.0.0.1:9050 ." /etc/privoxy/config; then
    safe_exec "Configurazione forwarding Privoxy" bash -c 'echo "forward-socks5 / 127.0.0.1:9050 ." >> /etc/privoxy/config'
fi

# Hardening Firefox
log "INFO" "Applicazione hardening base Firefox..."
if ! sudo -u "$CHIMERA_USER" firefox --headless --createprofile "default-release" >/dev/null 2>&1; then
     log "WARN" "Impossibile creare automaticamente il profilo Firefox."
else
    PROFILE_DIR=$(find "$HOME_DIR/.mozilla/firefox/" -name "*.default-release")
    if [ -n "$PROFILE_DIR" ]; then
        cat <<'EOF' > "$PROFILE_DIR/user.js"
user_pref("toolkit.telemetry.enabled", false);
user_pref("privacy.resistFingerprinting", true);
user_pref("media.peerconnection.enabled", false);
EOF
        chown "$CHIMERA_USER":"$CHIMERA_USER" "$PROFILE_DIR/user.js"
        log "SUCCESS" "Hardening base Firefox applicato."
    else
        log "WARN" "Impossibile trovare la directory del profilo Firefox per applicare user.js."
    fi
fi

# Copia script personalizzati
log "INFO" "Installazione utility di sistema personalizzate..."
safe_exec "Copia guardian-cli" cp "$CHIMERA_ROOT/scripts/guardian-cli.sh" /usr/local/bin/guardian-cli
safe_exec "Copia update-chimera" cp "$CHIMERA_ROOT/scripts/update-chimera" /usr/local/bin/update-chimera
safe_exec "Copia sandbox-run" cp "$CHIMERA_ROOT/scripts/sandbox-run.sh" /usr/local/bin/sandbox-run
safe_exec "Impostazione permessi eseguibili utility" chmod +x /usr/local/bin/*

# Configurazione Fail2ban base
log "INFO" "Applicazione configurazione base Fail2ban per SSH..."
cat <<EOF > /etc/fail2ban/jail.local
[DEFAULT]
bantime = 1h
maxretry = 5
findtime = 10m

[sshd]
enabled = true
EOF

log "SUCCESS" "Configurazioni finali di sistema applicate."

#--------------------------------------------------------------------------------
# STAGE 8: CREAZIONE MOTD PER FINALIZZAZIONE
#--------------------------------------------------------------------------------
log "INFO" "Creazione messaggio di benvenuto per il prossimo login..."
cat <<'EOF' | sudo tee /etc/motd > /dev/null
################################################################
#     Benvenuto in Chimera Guardian Arch (Base Installata)     #
################################################################
#                                                              #
#  ‼️  AZIONE RICHIESTA: Riavvia ed esegui 'make finalize'     #
#                                                              #
#  per completare l'hardening e il collegamento delle config.  #
#                                                              #
################################################################
EOF

log "SUCCESS" "Fase di installazione base del sistema completata."