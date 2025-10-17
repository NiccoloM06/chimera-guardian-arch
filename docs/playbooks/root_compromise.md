# Incident Response Playbook: Suspected Root Compromise

**Document Version:** 1.0
**Date:** 2025-10-17
**System:** Chimera Guardian Arch

**WARNING:** A root compromise is the most severe security incident. Act quickly, methodically, and assume the attacker has full control. Do NOT trust any software running on the compromised system.

---

## 1. Phase 1: Detection & Initial Assessment

* **Indicators of Compromise (IoC):**
    * Unexpected AIDE alerts (`aide-check` reports critical file changes).
    * Critical Falco alerts indicating privilege escalation or kernel module loading.
    * LKRG alerts (`journalctl -k`) indicating kernel integrity violations.
    * Unexpected outbound network traffic detected by OpenSnitch or external monitoring.
    * Unexplained system reboots or service crashes.
    * Files modified/created unexpectedly (especially in `/tmp`, `/dev/shm`, `/root`, `/etc`).
    * Unrecognized processes running as root (`ps aux | grep root`).
    * Login attempts from unknown IPs (`journalctl -u sshd`).
    * Guardian Daemon status (`/run/chimera/state.json`) showing `ALERT`.

* **Initial Assessment:**
    * **DO NOT** attempt extensive investigation directly on the live system. Assume all tools are compromised.
    * **Record Observations:** Note the time, specific IoCs observed, and any actions taken. Use pen and paper or a separate, trusted device.

## 2. Phase 2: Containment

The primary goal is to prevent the attacker from causing further damage or exfiltrating more data.

* **Isolate the System:**
    * **IMMEDIATELY disconnect the system from ALL networks.** Unplug the Ethernet cable and disable Wi-Fi.
    * **DO NOT gracefully shut down the system yet.** This could destroy volatile evidence (RAM).

* **Consider Volatile Data:** If a formal forensic investigation is required, a memory dump might be necessary *before* powering down. This requires specialized tools and expertise (e.g., using `avml` or `LiME` from a trusted USB drive). For most users, proceed to the next step.

## 3. Phase 3: Evidence Preservation (Optional but Recommended)

If you need to understand *how* the compromise occurred, preserve the state of the system.

* **Power Off Forcefully:** Hold the power button down until the machine shuts off. This helps preserve the state of memory slightly better than a graceful shutdown, though volatile data is largely lost.
* **Image the Disk:**
    * Boot the affected machine using a **trusted live forensic environment** (e.g., Kali Linux live USB, Paladin, CAINE). **DO NOT** boot the compromised Chimera system.
    * Connect a sterile external storage device with sufficient space.
    * Use `dd` or `ewfacquire` (from the live environment) to create a **bit-for-bit forensic image** of the entire compromised NVMe drive onto the external storage. Mount the source drive read-only (`-o ro`) if possible during imaging.
    ```bash
    # Example using dd (ensure /dev/nvme0n1 is the compromised drive and /dev/sdX is the sterile destination)
    # dd if=/dev/nvme0n1 of=/mnt/external_drive/compromised_image.dd bs=4M status=progress conv=noerror,sync
    ```
    * **Document Everything:** Record the imaging tool used, start/end times, and calculate cryptographic hashes (MD5, SHA256) of both the source drive (if possible before imaging) and the resulting image file.

## 4. Phase 4: Eradication & Recovery

Assume the entire system is untrustworthy. **The only safe way forward is a complete wipe and reinstall.**

* **Wipe the Drive:** Using the trusted live environment (from Phase 3) or the Arch Linux installation USB:
    * Use `gparted` or `dd` to **securely wipe** the NVMe drive. Overwriting with zeros (`dd if=/dev/zero of=/dev/nvme0n1 bs=4M status=progress`) is usually sufficient for SSDs due to TRIM/garbage collection.
* **Reinstall Chimera Guardian Arch:** Follow the `DEPLOYMENT_CHECKLIST.md` meticulously:
    1. Install a fresh, minimal, **encrypted** Arch Linux base using `archinstall`.
    2. Clone a fresh copy of the Chimera Guardian Arch framework repository.
    3. Run `make install`.
    4. Perform the manual GRUB/fstab steps.
    5. Reboot.
    6. Run `make finalize`.
    7. **Secure the NEW AIDE baseline** onto your write-protected external medium.
* **Restore Data:**
    * **ONLY restore user data files** (`Documents`, `Pictures`, etc.) from backups taken *before* the suspected compromise date.
    * **DO NOT restore system configuration files (`~/.config`, `/etc`)** unless you are absolutely certain they were not modified by the attacker. It is safer to reconfigure manually or use the fresh defaults provided by `make finalize`.
    * **Scan restored data** with malware scanners from a trusted environment before fully integrating it.
* **Change ALL Passwords:** Assume all credentials stored or used on the compromised system are now known to the attacker. Change passwords for online accounts, SSH keys, GPG keys, etc.

## 5. Phase 5: Post-Incident Analysis & Hardening

* **Analyze Evidence (if preserved):** If you created a forensic image, analyze it using tools like Autopsy, Volatility (if you have a memory dump), and manual log review to determine the attack vector and attacker actions.
* **Review Logs:** Check logs from external devices (firewalls, routers) for suspicious connections around the time of the compromise.
* **Identify Weakness:** Determine how the compromise occurred (e.g., vulnerable software, weak password, phishing).
* **Apply Lessons Learned:** Update security policies, strengthen configurations, and improve user awareness based on the findings. Re-evaluate the security profiles (`standard`, `secure`, `paranoid`) and triggers.
```