# Configuration
$config = @{
    Domain = $env:USERDNSDOMAIN
    LogPath = Join-Path $PSScriptRoot "logs\laps_access.log"
    CredentialCache = $true
    CacheTimeout = 30  # minutes
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

function Get-CachedCredential {
    if (-not $config.CredentialCache) { return $null }
    
    $cachedCred = Get-Variable -Name "CachedLAPSCred" -ErrorAction SilentlyContinue
    if ($cachedCred -and (Get-Variable -Name "CachedLAPSTime" -ErrorAction SilentlyContinue)) {
        $timeElapsed = (Get-Date) - (Get-Variable -Name "CachedLAPSTime").Value
        if ($timeElapsed.TotalMinutes -lt $config.CacheTimeout) {
            return $cachedCred.Value
        }
    }
    return $null
}

function Set-CachedCredential {
    param($Credential)
    
    if (-not $config.CredentialCache) { return }
    
    Set-Variable -Name "CachedLAPSCred" -Value $Credential -Scope Script
    Set-Variable -Name "CachedLAPSTime" -Value (Get-Date) -Scope Script
}

# Main execution
try {
    Write-Log "Starting LAPS password retrieval script" -Level Info
    
    # Try to get cached credentials
    $creden = Get-CachedCredential
    
    if (-not $creden) {
        $username = Read-Host "Please enter your username"
        $password = Read-Host "Please enter your password" -MaskInput
        $enkpassword = ConvertTo-SecureString $password -AsPlainText -Force
        $creden = New-Object System.Management.Automation.PSCredential ($username, $enkpassword)
        
        # Cache the credentials if enabled
        Set-CachedCredential $creden
    }
    else {
        Write-Log "Using cached credentials" -Level Info
    }
    
    while ($true) {
        $hostname = Read-Host "Please enter hostname"
        
        # Validate hostname
        if ([string]::IsNullOrWhiteSpace($hostname)) {
            Write-Log "Invalid hostname provided" -Level Warning
            continue
        }
        
        # Test connectivity
        if (-not (Test-Connectivity $hostname)) {
            $continue = Read-Host "Host appears to be offline. Continue anyway? (Y/N)"
            if ($continue -ne "Y") { continue }
        }
        
        try {
            Write-Log "Attempting to retrieve LAPS password for $hostname" -Level Info
            $passwordremote = Get-LapsADPassword -Identity $hostname -Credential $creden -Domain $config.Domain -AsPlainText | 
                Select-Object -ExpandProperty Password
            Write-Host "`nPassword for $hostname is: $passwordremote`n"
            Write-Log "Successfully retrieved LAPS password for $hostname" -Level Info
        }
        catch {
            Write-Log "Failed to retrieve LAPS password: $($_.Exception.Message)" -Level Error
            Write-Host "`nTroubleshooting steps:"
            Write-Host "1. Verify your permissions in Active Directory"
            Write-Host "2. Ensure LAPS is installed on the target computer"
            Write-Host "3. Check if the computer exists in the domain"
            Write-Host "4. Verify your network connectivity`n"
        }
        
        $continue = Read-Host "Do you want to check another computer? (Y/N)"
        if ($continue -ne "Y") {
            break
        }
    }
}
catch {
    Write-Log "Critical error: $($_.Exception.Message)" -Level Error
    Write-Host "Script terminated due to an unexpected error. Please check the log file for details."
}
finally {
    Write-Log "Script execution completed" -Level Info
    if ($config.CredentialCache) {
        Write-Log "Cached credentials will expire in $($config.CacheTimeout) minutes" -Level Info
    }
}
