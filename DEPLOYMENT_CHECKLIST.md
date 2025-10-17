# Full Deployment Checklist for Chimera Guardian Arch

This document provides a definitive, step-by-step procedure for deploying the Chimera Guardian Arch platform. Follow each stage in the specified order to ensure a secure and fully functional installation.

---

## STAGE 0: Prerequisites

Verify you have the following before you begin.

- [ ] **Installation Medium:** A bootable USB drive with the official Arch Linux ISO.
- [ ] **Internet Connection:** A working network connection (a wired connection is recommended for the installation phase).
- [ ] **Data Backup:** Ensure the target drive contains no important data. It will be completely erased.
- [ ] **Project Repository:** Access to this repository to clone the framework files.

---

## STAGE 1: Base Arch Linux Operating System Installation

This is the most critical foundation. Pay close attention to the highlighted steps.

1.  **[ ] Boot the System** from the Arch Linux USB drive.

2.  **[ ] Launch the Guided Installer:** Once in the live environment, run the command:
    ```bash
    archinstall
    ```

3.  **[ ] Follow the Installer Prompts**, making these specific choices:
    * **Disk configuration:** Select the target drive and choose the option to **"Wipe all selected drives..."**.
    * **‼️ Disk encryption:** When asked if you want to encrypt the disk, **SELECT "YES"**. This is a **mandatory** step. Set a strong passphrase for the disk encryption.
    * **Bootloader:** Select `grub`.
    * **User account:** Create your non-root user. When asked "Should <your_user> be a superuser (sudo)?", **SELECT "YES"**.
    * **Profile:** ‼️ Select the **`Minimal`** profile. Do not install any desktop environment.
    * **Network:** Choose **"Copy ISO network configuration to installation"**.

4.  **[ ] Begin Installation:** Confirm your settings and let `archinstall` complete the process.

5.  **[ ] Reboot the System:** When the installation finishes, choose **"no"** when asked to `chroot`. Then, exit the installer, remove the USB drive, and reboot the machine.

---

## STAGE 2: First Boot & Framework Deployment

1.  **[ ] Unlock the Disk:** At boot, you will be prompted for the LUKS encryption passphrase you set earlier. Enter it to proceed.

2.  **[ ] Login** with the username and password you created.

3.  **[ ] Clone the Project Repository:**
    ```bash
    # Install git first
    sudo pacman -S --noconfirm git

    # Clone the project
    git clone https://URL_OF_YOUR_REPO/chimera-guardian-arch.git
    cd chimera-guardian-arch
    ```

4.  **[ ] Configure the Environment:** Copy the example `.env` file and edit it to set your username and desired theme.
    ```bash
    cp .env.example .env
    nano .env
    ```

---

## STAGE 3: Main System Installation (via Makefile)

This phase automates the installation of all software, themes, and configurations.

1.  **[ ] Run the Main Installer:** Execute the primary `install` target from the `Makefile`.
    ```bash
    make install
    ```
2.  **[ ] Interact with the Script:** The script will guide you through the hardware driver selection process and then display a progress bar as it installs everything.

---

## STAGE 4: ⚠️ CRITICAL MANUAL ACTIONS (BEFORE REBOOT)

These steps must be performed manually as they are unique to your system and critical for booting.

1.  **[ ] Configure the Bootloader (GRUB):**
    * Open the file: `sudo nano /etc/default/grub`
    * Add `lsm=landlock,lockdown,yama,apparmor,bpf` inside the quotes of the `GRUB_CMDLINE_LINUX_DEFAULT` line.
    * Run `sudo grub-mkconfig -o /boot/grub/grub.cfg` to apply the changes.

2.  **[ ] Optimize `/etc/fstab` for Performance:**
    * Open the file: `sudo nano /etc/fstab`
    * Find the line for your root partition (`/`) and change the option `relatime` to **`noatime`**.
    * If you used **BTRFS**, also add the `compress=zstd` option on the same line.

3.  **[ ] Reboot the System:**
    * Run `sudo reboot`.

---

## STAGE 5: ✅ GUIDED FINALIZATION (AFTER REBOOT)

This final step securely initializes the intrusion detection system and links your configurations.

1.  **[ ] Unlock the Disk and Login** with your user.

2.  **[ ] Navigate to the Project Folder:**
    ```bash
    cd chimera-guardian-arch
    ```

3.  **[ ] Run the Finalization Script:**
    ```bash
    make finalize
    ```
    The script will guide you through creating the AIDE baseline.

4.  **[ ] SECURE THE AIDE BASELINE:** This is your last critical task. Copy the file `/var/lib/aide/aide.db.gz` to a secure, write-protected external medium. Refer to the `SYSTEM_GUIDE.md` for detailed instructions on how to do this.

---

## STAGE 6: Final Commissioning and Verification

Your system is now operational. Perform these final checks.

- [ ] **Install Firefox Add-ons:** Open Firefox and install `uBlock Origin` and `NoScript` from the official Mozilla add-ons website.
- [ ] **Test Quick Functions:** Open a terminal and test the custom commands:
    * `update` (it will ask for your sudo password).
    * `gdn-paranoid` (and then `gdn-standard` to return to normal).
    * `vms` (the Virtual Machine Manager should launch).
- [ ] **Launch the TUI:** Run `make tui` to open the TUI Control Center and verify it works.

---

**INSTALLATION COMPLETE.** You are now in full control of your digital fortress.