# Configuration
$config = @{
    Domain = $env:USERDNSDOMAIN
    DefaultAdminAccount = "admdesktop"
    LogPath = Join-Path $PSScriptRoot "logs\remote_access.log"
    CredentialCache = $true
    CacheTimeout = 30  # minutes
    ConnectionTimeout = 30  # seconds
    MaxRetries = 3
}

# Create logs directory if it doesn't exist
$logDir = Split-Path $config.LogPath -Parent
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info','Warning','Error')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Add-Content -Path $config.LogPath -Value $logMessage
    
    switch ($Level) {
        'Warning' { Write-Host $Message -ForegroundColor Yellow }
        'Error' { Write-Host $Message -ForegroundColor Red }
        default { Write-Host $Message }
    }
}

function Test-Connectivity {
    param([string]$Hostname)
    
    Write-Log "Testing connectivity to $Hostname" -Level Info
    $result = Test-Connection -ComputerName $Hostname -Count 1 -Quiet
    if (-not $result) {
        Write-Log "Cannot reach $Hostname" -Level Warning
    }
    return $result
}

function Test-RemoteAccess {
    param(
        [string]$Hostname,
        [System.Management.Automation.PSCredential]$Credential
    )
    
    try {
        $session = New-PSSession -ComputerName $Hostname -Credential $Credential -ErrorAction Stop
        Remove-PSSession $session
        return $true
    }
    catch {
        return $false
    }
}

function Get-CachedCredential {
    if (-not $config.CredentialCache) { return $null }
    
    $cachedCred = Get-Variable -Name "CachedRemoteCred" -ErrorAction SilentlyContinue
    if ($cachedCred -and (Get-Variable -Name "CachedRemoteTime" -ErrorAction SilentlyContinue)) {
        $timeElapsed = (Get-Date) - (Get-Variable -Name "CachedRemoteTime").Value
        if ($timeElapsed.TotalMinutes -lt $config.CacheTimeout) {
            return $cachedCred.Value
        }
    }
    return $null
}

function Set-CachedCredential {
    param($Credential)
    
    if (-not $config.CredentialCache) { return }
    
    Set-Variable -Name "CachedRemoteCred" -Value $Credential -Scope Script
    Set-Variable -Name "CachedRemoteTime" -Value (Get-Date) -Scope Script
}

function Show-Menu {
    param([string]$Title = "Remote Computer Access Tool")
    
    Clear-Host
    Write-Host "================ $Title ================"
    Write-Host "1: Use LAPS password"
    Write-Host "2: Use local/custom credentials"
    Write-Host "3: View connection history"
    Write-Host "4: Clear credential cache"
    Write-Host "5: Exit"
    Write-Host "==========================================="
}

function Get-MenuLAPS {
    Write-Log "LAPS authentication selected" -Level Info
    
    $username = Read-Host "Enter domain username"
    $password = Read-Host "Enter password" -MaskInput
    $hostnameremote = Read-Host "Enter target hostname"
    
    try {
        Write-Log "Attempting LAPS authentication for $hostnameremote" -Level Info
        
        # Test connectivity first
        if (-not (Test-Connectivity $hostnameremote)) {
            $continue = Read-Host "Host appears to be offline. Continue anyway? (Y/N)"
            if ($continue -ne "Y") { return }
        }
        
        $enkpassword = ConvertTo-SecureString $password -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential ($username, $enkpassword)
        
        Write-Host "Retrieving LAPS password..."
        $passwordremote = Get-PasswordLAPS -Username $username -Password $enkpassword -Hostname $hostnameremote
        $enkPasswordremote = ConvertTo-SecureString $passwordremote -AsPlainText -Force
        $userremote = ".\$($config.DefaultAdminAccount)"
        
        Write-Host "Establishing remote session..."
        Invoke-RemoteComputer -Hostname $hostnameremote -User $userremote -Password $enkPasswordremote
    }
    catch {
        Write-Log "LAPS authentication failed: $($_.Exception.Message)" -Level Error
        Write-Host "`nTroubleshooting steps:"
        Write-Host "1. Verify your domain credentials"
        Write-Host "2. Ensure LAPS is properly configured on the target"
        Write-Host "3. Check network connectivity"
        Write-Host "4. Verify you have LAPS read permissions"
        Read-Host "`nPress Enter to continue"
    }
}

function Get-MenuLocal {
    Write-Log "Local authentication selected" -Level Info
    
    $username = Read-Host "Enter username"
    $password = Read-Host "Enter password" -MaskInput
    $hostnameremote = Read-Host "Enter target hostname"
    
    try {
        Write-Log "Attempting local authentication for $hostnameremote" -Level Info
        
        # Test connectivity first
        if (-not (Test-Connectivity $hostnameremote)) {
            $continue = Read-Host "Host appears to be offline. Continue anyway? (Y/N)"
            if ($continue -ne "Y") { return }
        }
        
        $enkpassword = ConvertTo-SecureString $password -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential ($username, $enkpassword)
        
        Write-Host "Testing credentials..."
        if (Test-RemoteAccess -Hostname $hostnameremote -Credential $cred) {
            Write-Host "Credentials verified. Establishing remote session..."
            Invoke-RemoteComputer -User $username -Password $enkpassword -Hostname $hostnameremote
        }
        else {
            throw "Failed to authenticate with provided credentials"
        }
    }
    catch {
        Write-Log "Local authentication failed: $($_.Exception.Message)" -Level Error
        Write-Host "`nTroubleshooting steps:"
        Write-Host "1. Verify your credentials"
        Write-Host "2. Ensure the account has remote access permissions"
        Write-Host "3. Check if remote management is enabled on the target"
        Write-Host "4. Verify network connectivity"
        Read-Host "`nPress Enter to continue"
    }
}

function Show-ConnectionHistory {
    Write-Host "`nRecent Connection History"
    Write-Host "------------------------"
    
    Get-Content $config.LogPath | Select-String "Attempting|Success|Failed" | 
        Select-Object -Last 10 | ForEach-Object {
            $line = $_.ToString()
            if ($line -match "Success") {
                Write-Host $line -ForegroundColor Green
            }
            elseif ($line -match "Failed") {
                Write-Host $line -ForegroundColor Red
            }
            else {
                Write-Host $line
            }
        }
    
    Read-Host "`nPress Enter to continue"
}

function Clear-CredentialCache {
    Remove-Variable -Name "CachedRemoteCred" -ErrorAction SilentlyContinue
    Remove-Variable -Name "CachedRemoteTime" -ErrorAction SilentlyContinue
    Write-Host "Credential cache cleared"
    Write-Log "Credential cache cleared" -Level Info
    Read-Host "Press Enter to continue"
}

function Invoke-RemoteComputer {
    param(
        [Parameter(Mandatory=$true)]
        [SecureString] $Password,
        
        [Parameter(Mandatory=$true)]
        [string] $User,
        
        [Parameter(Mandatory=$true)]
        [string] $Hostname
    )
    
    $CredenRemote = New-Object System.Management.Automation.PSCredential ($User, $Password)
    $retry = 0
    $success = $false
    
    while (-not $success -and $retry -lt $config.MaxRetries) {
        try {
            $retry++
            Write-Host "Connection attempt $retry of $($config.MaxRetries)..."
            
            $session = New-PSSession -ComputerName $Hostname -Credential $CredenRemote -ErrorAction Stop
            Enter-PSSession -Session $session
            $success = $true
            
            Write-Log "Successfully connected to $Hostname" -Level Info
        }
        catch {
            Write-Log "Connection attempt $retry failed: $($_.Exception.Message)" -Level Warning
            if ($retry -lt $config.MaxRetries) {
                Write-Host "Retrying in 5 seconds..."
                Start-Sleep -Seconds 5
            }
            else {
                throw "Failed to establish remote session after $($config.MaxRetries) attempts: $($_.Exception.Message)"
            }
        }
    }
}

function Get-PasswordLAPS {
    param(
        [Parameter(Mandatory=$true)]
        [string] $Hostname,
        
        [Parameter(Mandatory=$true)]
        [string] $Username,
        
        [Parameter(Mandatory=$true)]
        [SecureString] $Password
    )
    
    $Creden = New-Object System.Management.Automation.PSCredential ($Username, $Password)
    try {
        $PasswordRemote = Get-LapsADPassword -Identity $Hostname -Credential $Creden -Domain $config.Domain -AsPlainText |
            Select-Object -ExpandProperty Password
        Write-Log "Successfully retrieved LAPS password for $Hostname" -Level Info
        Return $PasswordRemote
    }
    catch {
        Write-Log "Failed to retrieve LAPS password for $Hostname" -Level Error
        throw "Failed to retrieve LAPS password: $($_.Exception.Message)"
    }
}

# Main execution loop
Write-Log "Script started" -Level Info

do {
    Show-Menu
    $menu = Read-Host "`nSelect an option"
    
    switch ($menu) {
        "1" { Get-MenuLAPS }
        "2" { Get-MenuLocal }
        "3" { Show-ConnectionHistory }
        "4" { Clear-CredentialCache }
        "5" { 
            Write-Log "Script terminated by user" -Level Info
            Write-Host "Exiting..."
            break
        }
        default {
            Write-Host "Invalid option. Please try again." -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        }
    }
} while ($menu -ne "5")