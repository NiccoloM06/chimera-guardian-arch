# Playbook di Risposta agli Incidenti: Sospetta Compromissione di Root

**Versione Documento:** 1.0
**Data:** 17 Ottobre 2025
**Sistema:** Chimera Guardian Arch

**ATTENZIONE:** Una compromissione a livello di root è l'incidente di sicurezza più grave. Agire rapidamente, in modo metodico, e presumere che l'attaccante abbia il controllo completo. NON fidarsi di alcun software in esecuzione sul sistema compromesso.

---

## Fase 1: Rilevamento e Valutazione Iniziale

* **Indicatori di Compromissione (IoC):**
    * Alert AIDE inattesi (`aide-check` riporta modifiche a file critici).
    * Alert Falco critici che indicano privilege escalation o caricamento di moduli kernel sospetti.
    * Alert LKRG (`journalctl -k`) che indicano violazioni dell'integrità del kernel.
    * Traffico di rete in uscita inatteso rilevato da OpenSnitch o monitoraggio esterno.
    * Riavvi di sistema o crash di servizi inspiegabili.
    * File modificati/creati in modo inatteso (specie in `/tmp`, `/dev/shm`, `/root`, `/etc`).
    * Processi non riconosciuti in esecuzione come root (`ps aux | grep root`).
    * Tentativi di login da IP sconosciuti (`journalctl -u sshd`).
    * Stato del Guardian Daemon (`/run/chimera/state.json`) che mostra `ALERT`.

* **Valutazione Iniziale:**
    * **NON** tentare indagini approfondite direttamente sul sistema live. Presumere che tutti gli strumenti siano compromessi.
    * **Registrare le Osservazioni:** Annotare ora, IoC specifici osservati e qualsiasi azione intrapresa. Usare carta e penna o un dispositivo separato e fidato.

## Fase 2: Contenimento

L'obiettivo primario è impedire all'attaccante di causare ulteriori danni o esfiltrare altri dati.

* **Isolare il Sistema:**
    * **SCOLLEGARE IMMEDIATAMENTE il sistema da TUTTE le reti.** Staccare il cavo Ethernet e disabilitare il Wi-Fi.
    * **NON spegnere il sistema in modo controllato per ora.** Ciò potrebbe distruggere prove volatili (RAM).

* **Considerare Dati Volatili:** Se è richiesta un'indagine forense formale, potrebbe essere necessario un dump della memoria *prima* dello spegnimento. Ciò richiede strumenti e competenze specialistiche (es. usare `avml` o `LiME` da una USB fidata). Per la maggior parte degli utenti, procedere al passo successivo.

## Fase 3: Preservazione delle Prove (Opzionale ma Raccomandato)

Se è necessario capire *come* è avvenuta la compromissione, preservare lo stato del sistema.

* **Spegnimento Forzato:** Tenere premuto il pulsante di accensione fino allo spegnimento della macchina. Questo aiuta a preservare lo stato della memoria leggermente meglio di uno shutdown controllato, sebbene i dati volatili siano in gran parte persi.
* **Imaging del Disco:**
    * Avviare la macchina interessata usando un **ambiente live forense fidato** (es. Kali Linux live USB, Paladin, CAINE). **NON** avviare il sistema Chimera compromesso.
    * Collegare un dispositivo di archiviazione esterno sterile con spazio sufficiente.
    * Usare `dd` o `ewfacquire` (dall'ambiente live) per creare un'**immagine forense bit-per-bit** dell'intero drive NVMe compromesso sull'archivio esterno. Montare il drive sorgente in sola lettura (`-o ro`) se possibile durante l'imaging.
    ```bash
    # Esempio con dd (assicurarsi che /dev/nvme0n1 sia il drive compromesso e /dev/sdX quello esterno sterile)
    # dd if=/dev/nvme0n1 of=/mnt/external_drive/compromised_image.dd bs=4M status=progress conv=noerror,sync
    ```
    * **Documentare Tutto:** Registrare lo strumento di imaging usato, ora di inizio/fine, e calcolare gli hash crittografici (MD5, SHA256) sia del drive sorgente (se possibile prima dell'imaging) sia del file immagine risultante.

## Fase 4: Eradicazione e Ripristino

Presumere che l'intero sistema non sia affidabile. **L'unica via sicura è una cancellazione completa e una reinstallazione.**

* **Cancellare il Drive:** Usando l'ambiente live fidato (dalla Fase 3) o la USB di installazione di Arch Linux:
    * Usare `gparted` o `dd` per **cancellare in modo sicuro** il drive NVMe. La sovrascrittura con zeri (`dd if=/dev/zero of=/dev/nvme0n1 bs=4M status=progress`) è solitamente sufficiente per gli SSD a causa del TRIM/garbage collection.
* **Reinstallare Chimera Guardian Arch:** Seguire meticolosamente la `DEPLOYMENT_CHECKLIST.md`:
    1. Installare una base Arch Linux **minimale e crittografata** usando `archinstall`.
    2. Clonare una copia fresca del repository del framework Chimera Guardian Arch.
    3. Eseguire `make install`.
    4. Eseguire i passaggi manuali per GRUB/fstab.
    5. Riavviare.
    6. Eseguire `make finalize`.
    7. **Mettere in sicurezza la NUOVA baseline AIDE** sul proprio supporto esterno protetto da scrittura.
* **Ripristinare i Dati:**
    * **Ripristinare SOLO i file di dati utente** (`Documenti`, `Immagini`, etc.) da backup effettuati *prima* della data sospetta della compromissione.
    * **NON ripristinare file di configurazione di sistema (`~/.config`, `/etc`)** a meno che non si sia assolutamente certi che non siano stati modificati dall'attaccante. È più sicuro riconfigurare manualmente o usare i default freschi forniti da `make finalize`.
    * **Scansionare i dati ripristinati** con scanner antimalware da un ambiente fidato prima di integrarli completamente.
* **Cambiare TUTTE le Password:** Presumere che tutte le credenziali memorizzate o usate sul sistema compromesso siano ora note all'attaccante. Cambiare password per account online, chiavi SSH, chiavi GPG, etc.

## Fase 5: Analisi Post-Incidente e Rafforzamento

* **Analizzare le Prove (se preservate):** Se è stata creata un'immagine forense, analizzarla usando strumenti come Autopsy, Volatility (se si dispone di un dump della memoria), e revisione manuale dei log per determinare il vettore d'attacco e le azioni dell'attaccante.
* **Revisionare i Log:** Controllare i log da dispositivi esterni (firewall, router) per connessioni sospette intorno al momento della compromissione.
* **Identificare la Debolezza:** Determinare come è avvenuta la compromissione (es. software vulnerabile, password debole, phishing).
* **Applicare le Lezioni Apprese:** Aggiornare le policy di sicurezza, rafforzare le configurazioni e migliorare la consapevolezza degli utenti in base ai risultati. Rivalutare i profili di sicurezza (`standard`, `secure`, `paranoid`) e i trigger.