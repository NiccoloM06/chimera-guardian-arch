# Guida Completa: Installazione Base di Arch Linux con archinstall

Questo documento è il **Prerequisito Fondamentale** per il framework Chimera Guardian Arch. Segui questi passaggi per creare la base minimale e crittografata su cui verrà costruito il sistema.

**Obiettivo:** Creare un'installazione di Arch Linux minimale, con un disco completamente crittografato (LUKS) e un utente `sudo`.

---
## Fase 0: Preparazione e Avvio

1.  **Crea il Supporto di Avvio:** Scarica l'ultima ISO di Arch Linux dal [sito ufficiale](https://archlinux.org/download/) e usa uno strumento come [Rufus](https://rufus.ie/) o [Etcher](https://www.balena.io/etcher/) per creare una chiavetta USB avviabile.
2.  **Avvia il PC:** Inserisci la chiavetta USB, accendi il computer ed entra nel menu di avvio (Boot Menu) del tuo BIOS/UEFI (solitamente premendo `F12`, `F11`, `F10`, `F8` o `DEL` all'avvio).
3.  **Seleziona la Chiavetta USB:** Scegli di avviare dalla tua chiavetta USB (seleziona la voce UEFI, se disponibile).
4.  **Menu di Avvio Arch:** Vedrai un menu nero. Seleziona la prima opzione: **"Arch Linux install medium (x86_64, UEFI)"** e premi `Invio`.
5.  **Attendi il Prompt:** Dopo il caricamento, ti troverai davanti a una riga di comando che termina con `root@archiso ~ #`.

---
## Fase 1: Connessione a Internet e Aggiornamento dell'Installer

Questo è un passaggio cruciale per assicurarsi di avere l'ultima versione di `archinstall` con le correzioni di bug più recenti.

### 1. Imposta il Layout della Tastiera (Opzionale ma Raccomandato)
Per evitare problemi con le password:
```bash
loadkeys it
```

### 2. Connettiti a Internet

**Se usi un cavo Ethernet:**
La connessione è quasi sempre automatica. Verificalo:
```bash
ping -c 3 archlinux.org
```
Se ricevi risposta, sei connesso e puoi saltare al punto 3.

**Se usi il Wi-Fi:**
Useremo lo strumento integrato `iwctl`:
```bash
# 1. Avvia lo strumento
iwctl

# 2. Mostra i nomi dei tuoi dispositivi Wi-Fi (es. wlan0)
[iwctl]# device list

# 3. Scansiona le reti (sostituisci wlan0 con il tuo dispositivo)
[iwctl]# station wlan0 scan

# 4. Mostra le reti trovate
[iwctl]# station wlan0 get-networks

# 5. Connettiti alla tua rete (sostituisci "NomeReteWiFi")
[iwctl]# station wlan0 connect "NomeReteWiFi"

# 6. Inserisci la tua password quando richiesta
Password: [tua_password]

# 7. Esci dallo strumento
[iwctl]# exit
```
**Verifica la connessione:**
```bash
ping -c 3 archlinux.org
```
Se ricevi risposta, sei connesso.

### 3. Aggiorna `archinstall`
Questo è il passaggio fondamentale. Aggiorniamo il gestore pacchetti e `archinstall` stesso.
```bash
pacman -Sy archinstall
```

---
## Fase 2: Esecuzione di `archinstall` (Il Wizard Guidato)

Ora sei pronto per lanciare l'installer principale.

1.  **Avvia l'Installer:**
    ```bash
    archinstall
    ```
2.  **Segui il Menu Guidato:** Configura ogni opzione come segue. **Le voci contrassegnate con ‼️ sono critiche per il progetto Chimera.**

    * `Archinstall language`: `it` (o la tua lingua)
    * `Layout tastiera`: `it`
    * `Mirror`: Seleziona la tua regione (es. `Italy`) per velocizzare i download.
    * `Partizionamento dischi`:
        * Scegli il disco su cui vuoi installare (es. `/dev/nvme0n1`).
        * Seleziona l'opzione: **"Wipe all selected drives and use a best-effort default partition layout"** (Cancella tutto e usa un layout predefinito).
    * `Filesystem`: ‼️ Scegli **`btrfs`** per sfruttare gli snapshot (come da nostra discussione).
    * `Crittografia disco`: ‼️ **PASSAGGIO OBBLIGATORIO**
        * Seleziona **"Encrypt disk"** (o "Crittografa disco").
        * Inserisci una **password (passphrase) robusta**. Questa sarà la tua chiave per sbloccare il computer ad ogni avvio. Non dimenticarla!
    * `Bootloader`: ‼️ Seleziona **`grub`**.
    * `Hostname`: Scegli un nome per il tuo computer (es. `chimera-box`).
    * `Password di Root`: Imposta una password sicura per l'utente `root`.
    * `Account utente`: ‼️ **PASSAGGIO OBBLIGATORIO**
        * Seleziona "Add a user".
        * Inserisci il tuo nome utente (es. `niccolo`). **Questo sarà il `CHIMERA_USER` che inserirai nel file `.env` in seguito.**
        * Imposta la tua password.
        * Quando ti viene chiesto "Should this user be a superuser (sudo)?", **rispondi "Yes"**.
    * `Profilo`: ‼️ **PASSAGGIO PIÙ IMPORTANTE**
        * Seleziona `Minimal`.
        * **NON** selezionare `Desktop` o `xorg` o `kde`.
        * **NON** aggiungere pacchetti aggiuntivi (come `linux-hardened`) qui. Il sistema deve essere minimale.
    * `Scheda di rete`: Seleziona **"Copy ISO network configuration to installation"**.
    * `Fuso orario`: Seleziona la tua zona (es. `Europe/Rome`).

3.  **Installa:**
    * Seleziona l'opzione **"Install"**.
    * Controlla il riepilogo e premi `Invio` per confermare.
    * Attendi il completamento dell'installazione.

---
## Fase 3: Post-Installazione e Riavvio

1.  **Fine Installazione:** Al termine, l'installer ti chiederà se vuoi eseguire `chroot` nel nuovo sistema per fare modifiche.
2.  **Rispondi "no"**. Non è necessario, il framework Chimera gestirà tutto.
3.  **Riavvia:** Esci dall'installer e digita:
    ```bash
    reboot
    ```
4.  **Rimuovi la Chiavetta USB** non appena il computer si riavvia.

## Prossimi Passaggi

Al riavvio, ti verrà chiesta la password di crittografia (LUKS) che hai impostato. Dopo averla inserita, potrai effettuare il login con il tuo nome utente e password.

Ora sei pronto per procedere con la **Fase 2** della `DEPLOYMENT_CHECKLIST.md` del progetto Chimera (clonare il repository e avviare l'installazione del framework).