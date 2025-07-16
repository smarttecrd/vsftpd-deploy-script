#!/bin/bash

################################################################################
# vsftpd Deploy & Management Script
# Sequential installer and manager for vsftpd on Ubuntu servers.
#
# Steps:
# 1. Setup and configure vsftpd
# 2. Add FTP user
# 3. Mount/bind folder into user FTP home
#
# Author: SmartTec
# License: MIT
################################################################################

set -e

GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

PASV_MIN_PORT=50000
PASV_MAX_PORT=50010

if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Error:${RESET} This script must be run as root."
    exit 1
fi

pause() {
    echo -e "\nPress [ENTER] to continue or [Ctrl+C] to cancel..."
    read -r
}

prompt_pasv_ports() {
    echo
    echo -e "${YELLOW}[Passive Ports Configuration]${RESET}"
    read -rp "Enter PASV minimum port [default: 50000]: " input_min
    read -rp "Enter PASV maximum port [default: 50010]: " input_max

    PASV_MIN_PORT=${input_min:-50000}
    PASV_MAX_PORT=${input_max:-50010}

    echo -e "${GREEN}Passive ports set to: $PASV_MIN_PORT - $PASV_MAX_PORT${RESET}"
}

prompt_nonempty() {
    local PROMPT="$1"
    local RESULT=""
    while true; do
        read -rp "$PROMPT" RESULT
        if [ -n "$RESULT" ]; then
            echo "$RESULT"
            return 0
        else
            echo -e "${RED}This field cannot be empty. Press [Ctrl+C] to cancel.${RESET}"
        fi
    done
}

prompt_shell() {
    local SHELL_PATH=""
    while true; do
        read -rp "Enter shell for user [default: /bin/false]: " SHELL_PATH
        SHELL_PATH=${SHELL_PATH:-/bin/false}
        
        if grep -q "^$SHELL_PATH$" /etc/shells; then
            echo -e "${GREEN}Shell set to: $SHELL_PATH${RESET}"
            echo "$SHELL_PATH"
            return 0
        else
            echo -e "${YELLOW}Shell '$SHELL_PATH' is not registered in /etc/shells.${RESET}"
            read -rp "Do you want to add it to /etc/shells? [y/N]: " ADD_SHELL
            
            if [[ "$ADD_SHELL" =~ ^[Yy]$ ]]; then
                echo "$SHELL_PATH" >> /etc/shells
                echo -e "${GREEN}Shell '$SHELL_PATH' added to /etc/shells successfully.${RESET}"
                echo "$SHELL_PATH"
                return 0
            else
                echo -e "${YELLOW}Please enter a different shell path or press Enter for default.${RESET}"
            fi
        fi
    done
}

install_vsftpd() {
    if dpkg -l | grep -qw vsftpd; then
        echo -e "${YELLOW}vsftpd is already installed. Skipping installation.${RESET}"
    else
        echo -e "${GREEN}Installing vsftpd...${RESET}"
        apt update
        apt install -y vsftpd
    fi

    if [ ! -f /etc/vsftpd.conf.bak ]; then
        cp /etc/vsftpd.conf /etc/vsftpd.conf.bak
        echo "Original vsftpd.conf backed up."
    fi

    prompt_pasv_ports

    cat > /etc/vsftpd.conf <<EOF
listen=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES
chroot_local_user=YES
allow_writeable_chroot=YES
local_umask=002
user_sub_token=\$USER
local_root=/srv/ftp/\$USER
userlist_enable=YES
userlist_file=/etc/vsftpd.userlist
userlist_deny=NO
pasv_min_port=$PASV_MIN_PORT
pasv_max_port=$PASV_MAX_PORT
xferlog_enable=YES
xferlog_file=/var/log/vsftpd.log
xferlog_std_format=YES
log_ftp_protocol=YES
dual_log_enable=YES
EOF

    touch /etc/vsftpd.userlist
    chmod 600 /etc/vsftpd.userlist

    mkdir -p /srv/ftp
    chmod 755 /srv/ftp

    if ! getent group ftp > /dev/null; then
        groupadd ftp
        echo "Group 'ftp' created."
    fi

    systemctl enable vsftpd
    systemctl restart vsftpd

    echo -e "${GREEN}vsftpd is installed and configured successfully.${RESET}"
    pause
}

add_ftp_user() {
    echo -e "\n${YELLOW}[Ctrl+C to cancel]${RESET}"

    USERNAME=$(prompt_nonempty "Enter new FTP username: ")

    if id "$USERNAME" &>/dev/null; then
        echo -e "${YELLOW}User '$USERNAME' already exists.${RESET}"
    else
        PASSWORD=$(prompt_nonempty "Enter password for user '$USERNAME': ")
        
        echo
        SHELL=$(prompt_shell)

        mkdir -p /srv/ftp/"$USERNAME"

        useradd -m \
            -d /srv/ftp/"$USERNAME" \
            -s "$SHELL" \
            -g ftp \
            -G www-data \
            "$USERNAME"

        echo "$USERNAME:$PASSWORD" | chpasswd

        chown "$USERNAME":ftp /srv/ftp/"$USERNAME"
        chmod 750 /srv/ftp/"$USERNAME"

        echo "$USERNAME" >> /etc/vsftpd.userlist

        echo -e "${GREEN}User '$USERNAME' created successfully.${RESET}"
    fi

    pause
}

mount_bind_folder() {
    echo -e "\n${YELLOW}[Ctrl+C to cancel]${RESET}"

    USERNAME=$(prompt_nonempty "Enter existing FTP username: ")

    if ! id "$USERNAME" &>/dev/null; then
        echo -e "${RED}User '$USERNAME' does not exist.${RESET}"
        return
    fi

    while true; do
        SOURCE=$(prompt_nonempty "Enter full path of the folder to mount (source folder): ")
        if [ -d "$SOURCE" ]; then
            break
        else
            echo -e "${RED}Source folder does not exist. Press [Ctrl+C] to cancel.${RESET}"
        fi
    done

    TARGET="/srv/ftp/$USERNAME/$(basename "$SOURCE")"
    mkdir -p "$TARGET"

    if mountpoint -q "$TARGET"; then
        echo -e "${YELLOW}Folder is already mounted.${RESET}"
        return
    fi

    mount --bind "$SOURCE" "$TARGET"
    echo "$SOURCE $TARGET none bind 0 0" >> /etc/fstab

    echo -e "${GREEN}Mounted '$SOURCE' into '$TARGET'.${RESET}"
    pause
}

show_menu() {
    while true; do
        clear
        echo -e "${GREEN}vsftpd Deploy & Management Script${RESET}"
        echo "-----------------------------------------"
        echo "1) Setup and Configure vsftpd"
        echo "2) Add FTP User"
        echo "3) Mount/Bind Folder into User Home"
        echo "4) Exit"
        echo

        read -rp "[Ctrl+C to cancel] Choose an option [1-4]: " OPTION

        case "$OPTION" in
            1)
                install_vsftpd
                ;;
            2)
                add_ftp_user
                ;;
            3)
                mount_bind_folder
                ;;
            4)
                # Final message
                echo -e "\n--- Made with love from the Dominican Republic by SmartTec ---"
                echo "Visit us at https://smarttec.com.do"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option.${RESET}"
                pause
                ;;
        esac
    done
}

# Start script
show_menu
