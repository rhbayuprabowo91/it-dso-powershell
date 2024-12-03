# PowerShell System Administration Toolkit

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![LAPS](https://img.shields.io/badge/LAPS-Required-yellow.svg)](https://www.microsoft.com/en-us/download/details.aspx?id=46899)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A comprehensive collection of PowerShell scripts for system administrators to streamline common IT tasks such as password management, network scanning, and remote access management.

## 📋 Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Security](#security)
- [Logging](#logging)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## ✨ Features

### Get-PasswordLAPS.ps1
Advanced LAPS password management tool with:
- Automatic domain detection
- Secure credential handling
- Credential caching with configurable timeout
- Comprehensive logging
- Connectivity testing
- Detailed error messages and troubleshooting

### Ping-Computer.ps1
Sophisticated network scanning utility featuring:
- Parallel IP scanning (PowerShell 7+)
- Configurable IP ranges
- DNS resolution
- CSV and HTML report generation
- Progress tracking
- Performance optimization

### Remote-Computer.ps1
Enhanced remote access management tool offering:
- Multiple authentication methods (LAPS/Local)
- Connection history tracking
- Credential caching
- Automatic retry mechanism
- Session validation
- Interactive menu system

## 🔧 Requirements

### System Requirements
- Windows PowerShell 5.1 or PowerShell 7+
- Windows Operating System
- Active Directory environment
- Administrator privileges

### Required PowerShell Modules
```powershell
# Check if modules are installed
Get-Module -ListAvailable -Name @('ActiveDirectory', 'AdmPwd.PS')

# Install required modules
Install-Module -Name AdmPwd.PS -Force
```

## 📥 Installation

1. Clone or download the repository:
```powershell
git clone https://github.com/yourusername/powershell-admin-toolkit.git
```

2. Ensure execution policy allows script execution:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

3. Verify LAPS installation:
```powershell
Get-Module AdmPwd.PS -ListAvailable
```

## 🚀 Usage

### Get-PasswordLAPS.ps1
```powershell
# Run the script
.\Get-PasswordLAPS.ps1

# Follow the interactive prompts:
# 1. Enter domain credentials
# 2. Specify target hostname
# 3. View LAPS password
```

### Ping-Computer.ps1
```powershell
# Run the script
.\Ping-Computer.ps1

# Options:
# - Specify IP range
# - Enable/disable DNS lookup
# - Configure parallel execution
# - Export results to CSV/HTML
```

### Remote-Computer.ps1
```powershell
# Run the script
.\Remote-Computer.ps1

# Available options:
# 1. LAPS authentication
# 2. Local/custom credentials
# 3. View connection history
# 4. Manage credential cache
```

## ⚙️ Configuration

### Default Configuration
Each script includes a configuration section at the top:

```powershell
$config = @{
    Domain = $env:USERDNSDOMAIN
    LogPath = Join-Path $PSScriptRoot "logs"
    CredentialCache = $true
    CacheTimeout = 30  # minutes
}
```

### Customization
- Modify the config hashtable in each script
- Adjust timeouts, retries, and other parameters
- Configure logging paths and levels
- Set default values for common parameters

## 🔒 Security

### Features
- Secure credential handling using SecureString
- No hardcoded credentials
- Credential caching with timeouts
- Session validation
- Comprehensive logging for audit trails

### Best Practices
- Always use domain accounts with minimum required permissions
- Regularly rotate credentials
- Monitor and review logs
- Keep PowerShell and modules updated
- Use HTTPS for remote connections when possible

## 📝 Logging

### Log Locations
- LAPS access: `logs\laps_access.log`
- Network scans: `logs\network_scan.log`
- Remote access: `logs\remote_access.log`

### Log Levels
- Info: Normal operations
- Warning: Non-critical issues
- Error: Critical problems requiring attention

## ❗ Troubleshooting

### Common Issues

#### LAPS Password Retrieval Fails
- Verify domain connectivity
- Check LAPS installation
- Confirm user permissions
- Review error logs

#### Network Scan Issues
- Check network connectivity
- Verify IP range format
- Ensure sufficient permissions
- Monitor resource usage

#### Remote Access Problems
- Verify target computer is online
- Check Windows Remote Management
- Confirm firewall settings
- Review authentication logs

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- PowerShell Community
- Microsoft LAPS Team
- Active Directory Team

## 📞 Support

For support:
1. Check the troubleshooting guide
2. Review closed issues
3. Open a new issue with:
   - Script version
   - PowerShell version
   - Error messages
   - Logs
