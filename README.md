# PowerShell System Administration Tools

A collection of PowerShell scripts for system administrators to help with common IT tasks such as password management, network scanning, and remote access.

## Scripts Overview

### 1. Get-PasswordLAPS.ps1
Script for retrieving LAPS (Local Administrator Password Solution) passwords from domain-joined computers.
- Automatically detects current domain
- Secure password handling
- Error handling with helpful messages
- Exit option after each password retrieval

### 2. Ping-Computer.ps1
Advanced network scanning tool with configurable options.
- Full subnet scanning (configurable range)
- IP address validation
- Optional DNS resolution
- Parallel execution in PowerShell 7
- Progress feedback
- Supports both PowerShell 5.1 and 7+

### 3. Remote-Computer.ps1
Interactive remote access tool with multiple authentication methods.
- Menu-driven interface
- Support for LAPS and custom credentials
- Configurable default admin account
- Comprehensive error handling
- Automatic domain detection

## Requirements

### General Requirements
- Windows PowerShell 5.1 or PowerShell 7+
- Domain environment with proper permissions
- LAPS PowerShell module (for LAPS functionality)

### For LAPS Features
- Active Directory environment
- LAPS installed and configured in the domain
- Appropriate permissions to read LAPS passwords

### For Network Scanning
- Network access to target subnets
- Appropriate firewall rules for ICMP
- DNS resolution (optional)

### For Remote Access
- Remote management enabled on target computers
- Appropriate network connectivity
- Required permissions for remote access

## Configuration

### Get-PasswordLAPS.ps1
- Automatically uses current domain
- No manual configuration required

### Ping-Computer.ps1
Configurable options include:
- Custom IP ranges
- DNS lookup toggle
- Parallel execution settings (PowerShell 7)

### Remote-Computer.ps1
Configuration in script header:
```powershell
$config = @{
    Domain = $env:USERDNSDOMAIN
    DefaultAdminAccount = "admdesktop"
}
```

## Usage

### Get-PasswordLAPS.ps1
1. Run the script
2. Enter domain credentials
3. Enter target hostname
4. View LAPS password
5. Choose to continue or exit

### Ping-Computer.ps1
1. Run the script
2. Enter target IP address
3. Choose to use custom range (optional)
4. Enable/disable DNS lookup
5. View results

### Remote-Computer.ps1
1. Run the script
2. Choose authentication method:
   - LAPS password
   - Local/custom credentials
3. Enter required credentials
4. Connect to remote system

## Security Features
- Secure password handling using SecureString
- Masked password input
- Proper credential object usage
- Error handling with security-conscious messages
- No hardcoded credentials or domains
