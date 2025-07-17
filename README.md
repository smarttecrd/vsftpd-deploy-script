# vsftpd Deploy & Management Script

This is an interactive Bash script for automated installation, configuration, and management of vsftpd (Very Secure FTP Daemon) on Ubuntu servers with secure system user management and advanced shell validation.

---

## ✅ Features

- **Automated vsftpd Installation**: Installs and configures vsftpd with secure defaults
- **Custom Passive Port Configuration**: Configure passive mode port ranges for firewall compatibility
- **Secure Password Generation**: Automatically generates 18-character secure passwords using `pwgen`
- **Secure User Management**: Creates FTP users with proper shell validation and `/etc/shells` management
- **Advanced Shell Validation**: Validates shells against `/etc/shells` and offers to register new ones
- **Directory Binding**: Mount/bind external folders into user FTP directories
- **Chroot Security**: Users are restricted to their home directories
- **Backup Configuration**: Automatically backs up original vsftpd configuration
- **Interactive Interface**: User-friendly menu system with cancellation support (`Ctrl+C`)

---

## ⚙️ Requirements

- Ubuntu Server (18.04 or later)
- Root privileges
- `bash`
- Internet connection for package installation
- `pwgen` (automatically installed with vsftpd)

---

## 🚀 Usage

```bash
# Download the script
curl -O https://raw.githubusercontent.com/smarttecrd/vsftpd-deploy-script/main/vsftpd-deploy.sh

# Make it executable
chmod +x vsftpd-deploy.sh

# Run as root
sudo ./vsftpd-deploy.sh
```

### Menu Options

The script provides an interactive menu with the following options:

1. **Setup and Configure vsftpd**
   - Installs vsftpd package
   - Installs pwgen package
   - Configures secure defaults
   - Sets up passive port ranges
   - Creates necessary directories and permissions

2. **Add FTP User**
   - Creates new FTP users with secure defaults
   - Generates secure 18-character passwords automatically
   - Validates and manages user shells
   - Automatically adds users to vsftpd userlist
   - Sets proper directory permissions

3. **Mount/Bind Folder into User Home**
   - Binds external directories to user FTP directories
   - Automatically updates `/etc/fstab` for persistence
   - Validates source directories before mounting

4. **Exit**
   - Clean exit with contact information

---

## 🔧 Configuration Details

### Default vsftpd Configuration

The script configures vsftpd with these secure settings:

- **Anonymous access**: Disabled
- **Local users**: Enabled
- **Chroot jail**: Enabled for all local users
- **Write permissions**: Enabled
- **Passive mode**: Configurable port range (default: 50000-50010)
- **Logging**: Comprehensive FTP protocol and transfer logging
- **User isolation**: Each user restricted to `/srv/ftp/$USER`

### User Management

- **Default shell**: `/bin/false` (prevents local login)
- **Home directory**: `/srv/ftp/$USERNAME`
- **Primary group**: `ftp`
- **Secondary group**: `www-data`
- **Directory permissions**: `750` (owner read/write/execute, group read/execute)
- **Password generation**: Secure 18-character passwords using `pwgen` with uppercase, lowercase, numbers, and symbols

### Shell Validation

The script includes advanced shell validation that:
- Checks if shells are registered in `/etc/shells`
- Offers to register new shells automatically
- Supports custom shells while maintaining security
- Defaults to `/bin/false` for maximum security

### Password Security

The script automatically generates secure passwords with the following characteristics:
- **Length**: 18 characters
- **Complexity**: Includes uppercase letters, lowercase letters, numbers, and special symbols
- **Tool**: Uses `pwgen` for cryptographically secure generation
- **Flexibility**: Users can accept generated password or provide their own
- **Fallback**: Manual password entry if `pwgen` is not available

---

## 🔐 Security Features

- **Chroot Environment**: Users cannot access files outside their home directory
- **Shell Validation**: Ensures only valid shells are used
- **Secure Defaults**: Uses `/bin/false` shell to prevent local login
- **Strong Password Generation**: Automatically generates 18-character secure passwords
- **Permission Management**: Proper file and directory permissions
- **User Isolation**: Each FTP user has isolated environment
- **Logging**: Comprehensive activity logging for security monitoring

---

## 📁 Directory Structure

After installation, the following structure is created:

```
/srv/ftp/                     # Main FTP directory
├── username1/                # Individual user directories
├── username2/
└── ...

/etc/vsftpd.conf             # Main configuration file
/etc/vsftpd.conf.bak         # Backup of original configuration
/etc/vsftpd.userlist         # Allowed FTP users list
/var/log/vsftpd.log          # FTP activity logs
```

---

## 🔥 Firewall Configuration

If you're using a firewall, ensure these ports are open:

```bash
# FTP control port
sudo ufw allow 21/tcp

# Passive mode ports (adjust range as configured)
sudo ufw allow 50000:50010/tcp
```

---

## 🛠️ Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure you're running the script as root
2. **Port Conflicts**: Check if configured passive ports are available
3. **Firewall Blocking**: Ensure FTP ports are open in your firewall
4. **Mount Issues**: Verify source directories exist before binding
5. **Password Generation**: If `pwgen` is not available, install vsftpd first or enter passwords manually

### Logs

Check vsftpd logs for troubleshooting:
```bash
sudo tail -f /var/log/vsftpd.log
sudo journalctl -u vsftpd -f
```

---

## 📝 License

MIT License - See [LICENSE](LICENSE) file for details.

---

## 👋 About

Made with love from the Dominican Republic by **SmartTec**  
Visit us at [smarttec.com.do](https://smarttec.com.do)

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
