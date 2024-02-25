#! /usr/bin/env sh
# Reference: https://github.com/botsunny/arch-plasma-minimal
# Reference: https://github.com/SixArm/unix-shell-script-tactics/tree/main/doc/print-output-with-printf-not-echo
# Reference: https://www.shellcheck.net/

# TODO: AUR (paru)
# TODO: Argument parser
# TODO: GitHub actions
# TODO: Detect disks
# TODO: Swap file
# TODO: Clean cache files automatically (https://ostechnix.com/recommended-way-clean-package-cache-arch-linux/) (pacman -Scc --noconfirm)
# TODO: Remove XDG directories (Desktop, Documents, Downloads, Music, Pictures, Public, Templates, Videos)

# =========================================
# ============== HACKERVERSE ==============
# =========================================
# Author: @cosasdepuma
# Description: This script installs a minimal Arch Linux system with some hacking tools
# License: MIT
# =========================================
# ============= INSTRUCTIONS ==============
# =========================================
# 1. Boot the Arch Linux ISO
# 2. Connect to the internet
# 3a. Run the following commands to download the installer:
#   curl -fsSLo hackverse.sh https://get.hackr.es/
#   sh hackverse.sh --help
# 3b. If you want to install the system directly, run:
#   curl -fsSLo- https://get.hackr.es/ | sh
# =========================================
# ============== DISCLAIMER ===============
# =========================================
# This script is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability,
# fitness for a particular purpose and noninfringement. In no event shall the authors or copyright holders be liable for any claim, damages or other
# liability, whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other dealings
# in the software. Use at your own risk.
# =========================================
# =============== WARNINGS ================
# =========================================
# 1. This script will erase all data on the main disk
# 2. This script is not intended for production systems
# 3. This script is not intended for physical machines
# 4. This script is not intended for UEFI systems
# 5. This script is not intended for NVIDIA systems
# 6. This script is not intended for non-English systems (except Spanish)
# =========================================
# =============== CHANGELOG ===============
# =========================================
# 2024-02: Initial version
# =========================================


# =========================================
# =============== ENV VARS ================
# =========================================

# Usage: export HACKVERSE_HOSTNAME='hackverse'
# Description: This variable sets the hostname
_hostname="${HACKVERSE_HOSTNAME:-hackverse}"

# Usage: export HACKVERSE_LOCALE='en'
# Description: This variable sets the locale
# Options: "es", "us"
_locale="${HACKVERSE_LOCALE:-us}"

# Usage: export HACKVERSE_LOGFILE='./hackverse.log'
# Description: This variable sets the log file
_logfile="${HACKVERSE_LOGFILE:-/var/log/hackverse.log}"

# Usage: export HACKVERSE_MOUNT='/tmp'
# Description: This variable sets the mount point
_mountpoint="${HACKVERSE_MOUNT:-/mnt}"

# USAGE: export HACKVERSE_PASSWORD='Sup3rStr0ngP45s!'
# Description: This variable sets the main user password
_password="${HACKVERSE_PASSWORD:-hacker}"

# Usage: export HACKVERSE_SUMETHOD='sudo'
# Description: This variable sets the superuser method
# Options: "doas", "sudo"
_sumethod="${HACKVERSE_SUMETHOD:-doas}"

# Usage: export HACKVERSE_TZ='Europe/Madrid'
# Description: This variable sets the timezone
_tz="${HACKVERSE_TZ:-Europe/Madrid}"

# Usage: export HACKVERSE_VERBOSE=1
# Description: This variable enables verbose mode
_verbose="${HACKVERSE_VERBOSE:-0}"

# Usage: export HACKVERSE_USER='hacker'
# Description: This variable sets the main username
_user="${HACKVERSE_USER:-hacker}"


# =========================================
# =============== MODIFIERS ===============
# =========================================

\set -o errexit # FIXME: Not working ???
\set -o noglob
\trap '\log_err "User interrupt. Exiting..."' INT QUIT TERM


# =========================================
# ================ LOGGER =================
# =========================================

# Usage: echo "This message will be printed to the stdout if VERBOSE is set and it also will be logged" | dbg
# Description: This function prints a message to the stdout if VERBOSE is set and logs it but the input must be piped
dbg() { \log | \verbose; }

# Usage: echo "This message will be logged" | log
# Description: This function logs a message and prints it to the stdout if VERBOSE is set
log() { while IFS= \read -r line; do \echo "$(\date -u) | ${line}" | \tee -a "${_logfile}"; done </dev/stdin; }

# Usage: log_err "This message will be logged and printed to the stderr"
# Description: This function logs a message, prints it to the stderr and exits with status 1
log_err() { >&2 \echo "---------------- ${*}" | \log; \exit 1; }

# Usage: log_dbg "This message will be printed to the stdout if VERBOSE is set and it also will be logged"
# Description: This function prints a message to the stdout if VERBOSE is set and logs it but the input must an argument
log_dbg() { >&1 \echo "++++++++++++++++ ${*}" | \dbg; }

# Usage: log_msg "This message will be logged and printed to the stdout"
# Description: This function logs a message and prints it to the stdout
log_msg() { >&1 \echo "${*}" | \log | \cut -d '|' -f 2-; }

# Usage: echo "This message will be printed to the stdout if VERBOSE is set" | verbose
# Description: This function prints a message to the stdout if VERBOSE is set
verbose() { while IFS= \read -r line; do \test "${_verbose}" -eq 0 || \echo "${line}"; done </dev/stdin; }


# =========================================
# ================ CHECKS =================
# =========================================

check_arguments() {
    check_content() { \test -n "${2}" || \log_err "Option '${1}' requires an argument"; }

    while :; do
        case "${1}" in
            -h|--help)
                \echo "Usage: ${0} [OPTION]..."
                \echo "Hackverse installer. This script installs a minimal Arch Linux system with some hacking tools"
                \echo; \echo "Options:";
                \echo "  -h, --help                 Show this help message";
                \echo "  -H, --hostname HOSTNAME    Set the hostname (default: hackverse, env: HACKVERSE_HOSTNAME)";
                \echo "  -l, --locale LOCALE        Set the locale [es,us] (default: us, env: HACKVERSE_LOCALE)";
                \echo "  -L, --logfile LOG_FILE     Set the log file (default: /var/log/hackverse.log, env: HACKVERSE_LOGFILE)";
                \echo "  -m, --mountpoint MOUNT     Set the mount point (default: /mnt, env: HACKVERSE_MOUNT)";
                \echo "  -p, --password PASSWORD    Set the main user password (default: hacker, env: HACKVERSE_PASSWORD)";
                \echo "  -S, --sumethod METHOD      Set the superuser method [doas,sudo] (default: doas, env: HACKVERSE_SUMETHOD)";
                \echo "  -T, --timezone TIMEZONE    Set the timezone (default: Europe/Madrid, env: HACKVERSE_TZ)";
                \echo "  -u, --user USERNAME        Set the main username (default: hacker, env: HACKVERSE_USER)";
                \echo "  -v, --verbose              Enable verbose mode";
                \exit 0;;
            -H|--hostname)  \check_content "${1}" "${2}"; _hostname="${2}";;
            -l|--locale)    \check_content "${1}" "${2}"; _locale="${2}";;
            -L|--logfile)   \check_content "${1}" "${2}"; _logfile="${2}";;
            -m|--mountpoint) \check_content "${1}" "${2}"; _mountpoint="${2}";;
            -p|--password)  \check_content "${1}" "${2}"; _password="${2}";;
            -S|--sumethod)  \check_content "${1}" "${2}"; _sumethod="${2}";;
            -T|--timezone)  \check_content "${1}" "${2}"; _tz="${2}";;
            -u|--user)      \check_content "${1}" "${2}"; _user="${2}";;
            -v|--verbose)   _verbose=1;;
            --) \shift; break;; # End of options
            *) break;;
        esac
        \shift
    done
}


# Usage: check_connection
# Description: This function checks if the system has internet connection and DNS resolution. If not, it exits with status 1
check_connection() {
    \log_msg '----------------- | Checking Internet | -----------------';
    \log_dbg 'Checking internet connection...'; \ping -c 1 -W 1 1.1.1.1 >/dev/null 2>&1 || \log_err 'No internet connection detected'
    \log_dbg 'Checking DNS resolution...'; \ping -c 1 -W 1 example.com >/dev/null 2>&1 || \log_err 'No DNS resolution detected'
}

# Usage: check_envvars
# Description: This function checks if the environment variables are set. If not, it exits with status 1
check_envvars() {
    \log_dbg 'Checking LOG_FILE...'; \test -n "${_logfile}" || \log_err 'LOG_FILE is not set'; \mkdir -p "$(\dirname "${_logfile}")" || \log_err "Cannot create $(\dirname "${_logfile}")"; \truncate -s 0 "${_logfile}" || \log_err "Cannot truncate '${_logfile}'"
    \log_msg '----------------- |   Checking Vars   | -----------------';
    \log_dbg 'Checking HOSTNAME...'; \test -n "${_hostname}" || \log_err 'HOSTNAME is not set'; \log_dbg "HOSTNAME=${_hostname}";
    \log_dbg 'Checking LOCALE...'; \test -n "${_locale}" || \log_err 'LOCALE is not set'; case "${_locale}" in "es"|"us") \log_dbg "LOCALE=${_locale}";; *) \log_err "Locale '${_locale}' is not supported";; esac
    \log_dbg 'Checking MOUNT_POINT...'; \test -n "${_mountpoint}" || \log_err 'MOUNT_POINT is not set'; mkdir -p "${_mountpoint}" || \log_err "Cannot create '${_mountpoint}'"; \log_dbg "MOUNT_POINT=${_mountpoint}"
    \log_dbg 'Checking PASSWORD...'; \test -n "${_password}" || \log_err 'PASSWORD is not set'; \log_dbg "PASSWORD=***********"
    \log_dbg 'Checking SU_METHOD...'; \test -n "${_sumethod}" || \log_err 'SU_METHOD is not set'; case "${_sumethod}" in "doas"|"sudo") \log_dbg "SU_METHOD=${_sumethod}";; *) \log_err "Superuser method '${_sumethod}' is not supported";; esac
    \log_dbg 'Checking TZ...'; \test -n "${_tz}" || \log_err 'TZ is not set'; \test -f "/usr/share/zoneinfo/${_tz}" || \log_err "Timezone ${_tz} is not valid"; \log_dbg "TZ=${_tz}"
    \log_dbg 'Checking USER...'; \test -n "${_user}" || \log_err 'USER is not set'; \test "${_user}" != "root" || \log_err 'USER cannot be set as root';  \log_dbg "USER=${_user}"
}

# Usage: check_superuser
# Description: This function checks if the user is root or has superuser privileges. If not, it exits with status 1
check_superuser() { \test "$(\id -u)" -eq 0 || \log_err "You must be root to run this script"; }

# Usage: case check_vm in "VMware"|"KVM"|"QEMU"|"Xen"|"VirtualBox"|"Hyper-V") echo "VM"; *) echo "Physical"; esac
# Description: This function checks if the system is a virtual machine and returns the hypervisor name
# Returns: The hypervisor name if the system is a virtual machine, "Physical" otherwise
check_vm() { \dmesg | \awk '/Hypervisor detected:/{ print $5 }'; }

# Usage: clean_previous_installation
# Description: This function cleans the previous installation
clean_previous_installation() {
    \log_dbg 'Unmounting partitions...'; \umount -R "${_mountpoint}" 2>&1 | \dbg
    \log_dbg 'Removing disk partitions...'; \parted /dev/sda rm 1  2>&1 | \dbg; \parted /dev/sda rm 2  2>&1 | \dbg
    \log_dbg 'Removing partition table...'; \yes | \parted /dev/sda mklabel msdos 2>&1 | \dbg
}

# Usage: if is_uefi; then echo "UEFI"; else echo "BIOS"; fi
# Description: This function checks if the system is UEFI
# Returns: 0 if the system is UEFI, 1 otherwise
is_uefi() { \test -d /sys/firmware/efi; }


# =========================================
# ================= DISKS =================
# =========================================

# Usage: prepare_disks
# Description: This function prepares the disks for the installation
# Disclaimer: This function was only tested on VMware virtual machines with BIOS
prepare_disks() {
    \log_msg '----------------- |  Preparing Disks  | -----------------'
    if \is_uefi; then \log_err 'UEFI is not supported yet'; else
        \log_dbg 'BIOS detected'
        case "$(\check_vm)" in
            "VMware") \log_dbg 'VMWare detected'; \prepare_disks_dos | \dbg ;;
            "KVM"|"QEMU"|"Xen"|"VirtualBox"|"Hyper-V") \log_err 'This virtual machine manufacturer is not supported yet';;
            *) \log_err 'Physical machine is not supported yet';;
        esac
    fi
}

# Usage: prepare_disks_dos
# Description: This function prepares the disks for the installation on BIOS systems (MS-DOS partition table)
prepare_disks_dos() {
    \log_dbg 'Creating partition table...'; \yes | \parted /dev/sda mklabel msdos 2>&1 | \dbg
    \log_dbg 'Creating partitions...'; \parted /dev/sda mkpart primary fat32 1MiB 512MiB 2>&1 | \dbg; \parted /dev/sda mkpart primary ext4 512MiB 100% 2>&1 | \dbg
    \log_dbg 'Formatting partitions...'; \mkfs.fat -F32 /dev/sda1 2>&1 | \dbg; \mkfs.ext4 /dev/sda2 2>&1 | \dbg
    \log_dbg 'Mounting partitions...'; \mount --mkdir /dev/sda2 "${_mountpoint}" | \dbg; \mount --mkdir /dev/sda1 "${_mountpoint}"/boot | \dbg
}


# =========================================
# ============= CONFIGURATION =============
# =========================================

# Usage: system_cfg_fstab
# Description: This function generates the /etc/fstab file
system_cfg_fstab() {
    \log_msg '----------------- |   Setting Fstab   | -----------------'
    \log_dbg 'Generating /etc/fstab...'; \genfstab -U -p "${_mountpoint}" | \tee "${_mountpoint}/etc/fstab" | \dbg
}

# Usage: system_cfg_keyboard
# Description: This function sets the keyboard layout
system_cfg_keyboard() {
    \log_msg '----------------- | Setting Keyboard  | -----------------'
    \log_dbg 'Setting keyboard layout...'; \echo "KEYMAP=${_locale}" | \tee "${_mountpoint}/etc/vconsole.conf" | \dbg
}

# Usage: system_cfg_locale
# Description: This function sets the locale
system_cfg_locale() {
    \log_msg '----------------- |   Setting Locale  | -----------------'
    case "${_locale}" in
        "es") \log_dbg 'Setting ES locale...'; \sed -i 's/#es_ES.UTF-8 UTF-8/es_ES.UTF-8 UTF-8/' "${_mountpoint}/etc/locale.gen";;
        "us") \log_dbg 'Setting EN locale...'; \sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' "${_mountpoint}/etc/locale.gen";;
        *) log_err "Locale ${_locale} is not supported";;
    esac
    \dbg < "${_mountpoint}/etc/locale.gen" 
    \log_dbg 'Generating locale...'; \arch-chroot "${_mountpoint}" /bin/sh -c "locale-gen" | \dbg
}

# Usage: system_cfg_networking
# Description: This function sets the hostname and the hosts file
system_cfg_networking() {
    \log_msg '----------------- |  Setting Network  | -----------------'
    \log_dbg 'Setting hostname...'; \echo "${_hostname}" | \tee "${_mountpoint}/etc/hostname" | \dbg
    \log_dbg 'Setting hosts file...';
    \echo "127.0.0.2 ${_hostname}.localdomain ${_hostname}.local ${_hostname}" | \tee -a "${_mountpoint}/etc/hosts" | \dbg
    \echo "127.0.0.1 localhost.localdomain localhost localhost4.localdomain localhost4" | \tee -a "${_mountpoint}/etc/hosts" | \dbg
    \echo "::1 localhost.localdomain localhost localhost6.localdomain localhost6" | \tee -a "${_mountpoint}/etc/hosts" | \dbg
}

# Usage: system_cfg_sumethod
# Description: This function installs and configures the superuser method
system_cfg_sumethod() {
    \log_msg '----------------- | Setting SU Method | -----------------'
    case "${_sumethod}" in
        "doas") \install_su_doas;;
        "sudo") \install_su_sudo;;
        *) \log_err "Superuser method '${_sumethod}' is not supported";;
    esac
}

# Usage: system_cfg_timezone
# Description: This function sets the timezone
system_cfg_timezone() {
    \log_msg '----------------- | Setting  Timezone | -----------------'
    \log_dbg 'Setting NTP...'; \timedatectl set-ntp true; \timedatectl status | \dbg;
    \log_dbg 'Setting timezone...'; \arch-chroot "${_mountpoint}" /bin/sh -c "ln -sf /usr/share/zoneinfo/${_tz} /etc/localtime";
    \log_dbg 'Setting hardware clock...'; \arch-chroot "${_mountpoint}" /bin/sh -c "hwclock --systohc"; \arch-chroot "${_mountpoint}" /bin/sh -c "hwclock --show" | \dbg
}

# Usage: system_cfg_user
# Description: This function creates the user and sets the password. If USER is 'root', it only sets the root password
system_cfg_user() {
    \log_msg '----------------- |   Setting  User   | -----------------'
    \log_dbg 'Creating user...'; \arch-chroot "${_mountpoint}" /bin/sh -c "useradd -m -g users -G wheel -s /bin/bash ${_user}" | \dbg
    \log_dbg 'Setting password...'; \echo "${_user}:${_password}" | \arch-chroot "${_mountpoint}" /bin/sh -c "chpasswd" | \dbg
}


# =========================================
# ============= INSTALLATION ==============
# =========================================

# Usage: install_pkgs_base
# Description: This function installs the base and development packages
install_pkgs_base() {
    \log_msg '----------------- |  Installing Base  | -----------------'
    \log_dbg 'Installing base and development packages...'; \pacstrap "${_mountpoint}" base base-devel 2>&1 | \dbg
}

# Usage: install_pkgs_dev
# Description: This function install some programming languages such as Golang, Java, Python3 and Rust, as well as Git
install_pkgs_dev() {
    \log_msg '----------------- |  Installing  Dev  | -----------------'
    \log_dbg 'Installing Git...'; \pacstrap "${_mountpoint}" git 2>&1 | \dbg
    \log_dbg 'Installing Golang...'; \pacstrap "${_mountpoint}" go 2>&1 | \dbg
    \log_dbg 'Installing Python...'; \pacstrap "${_mountpoint}" python3 python python-pipenv 2>&1 | \dbg
    \log_dbg 'Installing Rust...'; \pacstrap "${_mountpoint}" rustup 2>&1 | \dbg; \arch-chroot "${_mountpoint}" /bin/sh -c "rustup default stable" 2>&1 | \dbg
    \log_dbg 'Installing Rust as user'; \arch-chroot -u "${_user}" "${_mountpoint}" /bin/sh -c "HOME=/home/${_user} rustup default stable" 2>&1 | \dbg
}

# Usage: install_pkgs_grub
# Description: This function installs and configures the GRUB bootloader
install_pkgs_grub() {
    \log_msg '----------------- |  Installing GRUB  | -----------------'
    \log_dbg 'Installing GRUB...'; \pacstrap "${_mountpoint}" grub os-prober 2>&1 | \dbg
    if \is_uefi; then
        \log_dbg 'Installing UEFI bootloader...'; \pacstrap "${_mountpoint}" efibootmgr 2>&1 | \dbg
        \log_dbg 'Configuring UEFI bootloader...'; \arch-chroot "${_mountpoint}" /bin/sh -c "grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB" 2>&1 | \dbg
    else
        \log_dbg 'Installing BIOS bootloader...'; \pacstrap "${_mountpoint}" dosfstools mtools 2>&1 | \dbg
        \log_dbg 'Configuring BIOS bootloader...'; \arch-chroot "${_mountpoint}" /bin/sh -c "grub-install --target=i386-pc /dev/sda" 2>&1 | \dbg
    fi
    \log_dbg 'Configuring GRUB...'; \sed -i 's/GRUB_DISTRIBUTOR="Arch"/GRUB_DISTRIBUTOR="Hackverse"/' "${_mountpoint}/etc/default/grub"; \dbg < "${_mountpoint}/etc/default/grub"
    \log_dbg 'Generating GRUB configuration...'; \arch-chroot "${_mountpoint}" /bin/sh -c "grub-mkconfig -o /boot/grub/grub.cfg" 2>&1 | \dbg
}

# Usage: install_pkgs_linux
# Description: This function installs the packages for the Linux kernel
install_pkgs_linux() {
    \log_msg '----------------- | Installing Kernel | -----------------'
    \log_dbg 'Installing Linux kernel...'; \pacstrap -K "${_mountpoint}" linux linux-firmware linux-headers 2>&1 | \dbg
}

install_pkgs_kde() {
    \log_msg '----------------- |  Installing KDE   | -----------------'
    \log_dbg 'Installing KDE...'; \pacstrap "${_mountpoint}" 2>&1       \
        acpid ark cronie dolphin firefox flameshot gwenview kcalc kinit \
        kitty kvantum noto-fonts ntp okular phonon-qt5 phonon-qt5-vlc   \
        pipewire pipewire-alsa pipewire-jack pipewire-pulse             \
        plasma-desktop sddm tlp xf86-input-synaptics xsettingsd wireplumber | \dbg
    \log_dbg 'Enabling SDDM...'; \arch-chroot "${_mountpoint}" /bin/sh -c "systemctl enable sddm" | \dbg # Simple Desktop Display Manager
    \log_dbg 'Enabling TLP...'; \arch-chroot "${_mountpoint}" /bin/sh -c "systemctl enable tlp" | \dbg # Power management
    \log_dbg 'Enabling NTP...'; \arch-chroot "${_mountpoint}" /bin/sh -c "systemctl enable ntpd" | \dbg # Network Time Protocol
    \log_dbg 'Enabling acpid...'; \arch-chroot "${_mountpoint}" /bin/sh -c "systemctl enable acpid" | \dbg # Advanced Configuration and Power Interface
    \log_dbg 'Enabling cronie...'; \arch-chroot "${_mountpoint}" /bin/sh -c "systemctl enable cronie" | \dbg # Cron jobs
}


# =========================================
# =============== SERVICES ================
# =========================================

# Usage: install_pkgs_networkmanager
# Description: This function installs and configures the NetworkManager
install_service_networkmanager() {
    \log_msg '----------------- |   Installing NM   | -----------------'
    \log_dbg 'Installing NetworkManager...'; \pacstrap "${_mountpoint}" networkmanager network-manager-applet 2>&1 | \dbg
    \log_dbg 'Enabling NetworkManager...'; \arch-chroot "${_mountpoint}" /bin/sh -c "systemctl enable NetworkManager" | \dbg
}


# =========================================
# ================ DRIVERS ================
# =========================================

# Usage: install_drivers_cpu
# Description: This function installs the CPU microcode
install_drivers_cpu() {
    \log_msg '----------------- |  Installing  CPU  | -----------------'
    cpu="$(\awk -F: '/vendor_id/{ print $2; exit }' /proc/cpuinfo)"
    case "${cpu}" in
        *"GenuineIntel"*)
            \log_dbg 'Installing Intel microcode...'; \pacstrap "${_mountpoint}" intel-ucode 2>&1 | \dbg
            \log_dbg 'Installing Intel graphics drivers...'; \pacstrap "${_mountpoint}" mesa xf86-video-intel 2>&1 | \dbg ;;
        *"AuthenticAMD"*)
            \log_dbg 'Installing AMD microcode...'; \pacstrap "${_mountpoint}" amd-ucode 2>&1 | \dbg
            \log_dbg 'Installing AMD graphics drivers...'; \pacstrap "${_mountpoint}" mesa xf86-video-amdgpu 2>&1 | \dbg ;;
        *) \log_err "${cpu} CPU is not supported";;
    esac
}

# Usage: install_drivers_gpu
# Description: This function installs the GPU drivers
install_drivers_gpu() {
    \log_msg '----------------- |  Installing  GPU  | -----------------'
    \log_dbg 'Installing MESA drivers...'; \pacstrap "${_mountpoint}" mesa 2>&1| \dbg
    gpu="$(\lspci | \awk '/3D|VGA/{ print $5 }')"
    case "${gpu}" in
        *"VMware"*) \log_dbg 'Installing VMWare drivers...'; \pacstrap "${_mountpoint}" xf86-video-vmware 2>&1 | \dbg ;;
        *) \log_err "${gpu} GPU is not supported";;
    esac
}

# Usage: install_drivers_vm
# Description: This function installs the drivers for virtual machines
install_drivers_vm() {
    \log_msg '----------------- | Installing VM Gst | -----------------'
    case "$(\check_vm)" in
        *"VirtualBox"*) \log_dbg 'Installing VirtualBox drivers...'; \pacstrap "${_mountpoint}" virtualbox-guest-utils 2>&1 | \dbg; \arch-chroot "${_mountpoint}" /bin/sh -c "systemctl enable vboxservice" | \dbg ;;
        *"VMware"*) \log_dbg 'Installing VMWare drivers...'; \pacstrap "${_mountpoint}" open-vm-tools xf86-input-vmmouse gtkmm 2>&1 | \dbg; \arch-chroot "${_mountpoint}" /bin/sh -c "systemctl enable vmtoolsd" | \dbg ;;
        *"KVM"*|*"QEMU"*|*"Xen"*|*"Hyper-V"*) \log_err 'This virtual machine manufacturer is not supported yet';;
        *) \log_err 'Physical machine is not supported yet';;
    esac
}


# =========================================
# ============== SU METHODS ===============
# =========================================

# Usage: install_su_doas
# Description: This function installs and configures doas
install_su_doas() {
    \log_msg '----------------- |  Installing DoAs  | -----------------'
    \log_dbg 'Installing doas...'; \pacstrap "${_mountpoint}" doas 2>&1 | \dbg
    \log_dbg 'Configuring doas...'; \echo "permit persist setenv {XAUTHORITY LANG LC_ALL PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin} :wheel" | \tee "${_mountpoint}/etc/doas.conf" | \dbg
    \log_dbg 'Uninstalling sudo...'; \arch-chroot "${_mountpoint}" /bin/sh -c "pacman -Rcu sudo" 2>&1 | \dbg
    \log_dbg 'Linking sudo to doas...'; \arch-chroot "${_mountpoint}" /bin/sh -c "ln -sf /usr/bin/doas /usr/bin/sudo" | \dbg
}

# Usage: install_su_sudo
# Description: This function installs and configures sudo
install_su_sudo() {
    \log_msg '----------------- |  Installing Sudo  | -----------------'
    \log_dbg 'Installing sudo...'; \pacstrap "${_mountpoint}" sudo 2>&1 | \dbg
    \log_dbg 'Configuring sudo...'; \sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' "${_mountpoint}/etc/sudoers" | \dbg
    \log_dbg 'Configuring sudo insults...'; \echo 'Defaults insults' | \tee -a "${_mountpoint}/etc/sudoers" | \dbg
}


# =========================================
# ============== MAIN SCRIPT ==============
# =========================================

install_hackerverse() {
    \check_arguments "${@}"
    \clean_previous_installation
    \check_superuser
    \check_envvars
    \check_connection
    \prepare_disks
    \install_pkgs_base
    \install_pkgs_linux
    \system_cfg_keyboard
    \system_cfg_locale
    \system_cfg_timezone
    \install_pkgs_grub
    \install_drivers_cpu
    \install_drivers_gpu
    \install_drivers_vm
    \install_service_networkmanager
    \system_cfg_fstab
    \system_cfg_networking
    \system_cfg_sumethod
    \system_cfg_user
    \install_pkgs_dev
    \install_pkgs_kde
    \log_msg '--------------- |  Hackverse Installed  | ---------------'
    \log_msg "You can now reboot and login as '${_user}' with the password you set."
}
\install_hackerverse "${@}"
