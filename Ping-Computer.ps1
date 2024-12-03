# Configuration
$config = @{
    DefaultStartRange = 1
    DefaultEndRange = 254
    EnableDNS = $true
    MaxParallelJobs = 100
    LogPath = Join-Path $PSScriptRoot "logs\network_scan.log"
    OutputPath = Join-Path $PSScriptRoot "output"
    ExportResults = $true
    PingTimeout = 1000  # milliseconds
    PingRetries = 2
}

# Create necessary directories
$logDir = Split-Path $config.LogPath -Parent
$null = New-Item -ItemType Directory -Path $logDir -Force
$null = New-Item -ItemType Directory -Path $config.OutputPath -Force

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

function Test-InputValid {
    param([string]$IP)
    
    if ([string]::IsNullOrWhiteSpace($IP)) { return $false }
    
    $segment = $IP.Split(".")
    if ($segment.Count -eq 4) {
        foreach ($seg in $segment) {
            if ($seg -notmatch "^[\d\.]+$") { return $false }
            try {
                $num = [int]$seg
                if ($num -lt 0 -or $num -gt 255) { return $false }
            }
            catch {
                return $false
            }
        }
        return $true
    }
    return $false
}

function Get-NetworkInfo {
    param([string]$IP)
    
    $segments = $IP.Split(".")
    return @{
        Network = "$($segments[0]).$($segments[1]).$($segments[2])"
        FirstThreeOctets = "$($segments[0]).$($segments[1]).$($segments[2])"
        LastOctet = [int]$segments[3]
    }
}

function Ping-Core {
    param (
        [string]$Hostname,
        [bool]$DNSLookup = $true,
        [int]$Timeout = 1000,
        [int]$Retries = 2
    )
    
    $result = @{
        IP = $Hostname
        Status = "Offline"
        Hostname = ""
        ResponseTime = $null
    }
    
    try {
        $ping = Test-Connection -ComputerName $Hostname -Count $Retries -ErrorAction SilentlyContinue
        if ($ping) {
            $result.Status = "Online"
            $result.ResponseTime = ($ping | Measure-Object -Property ResponseTime -Average).Average
            
            if ($DNSLookup) {
                try {
                    $dnsResult = Resolve-DnsName -Name $Hostname -ErrorAction SilentlyContinue |
                        Select-Object -First 1 -ExpandProperty NameHost
                    $result.Hostname = $dnsResult
                }
                catch {
                    $result.Hostname = "DNS resolution failed"
                }
            }
        }
    }
    catch {
        Write-Log "Error pinging $Hostname: $($_.Exception.Message)" -Level Error
    }
    
    return $result
}

function Export-Results {
    param(
        [array]$Results,
        [string]$Network
    )
    
    if (-not $config.ExportResults) { return }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $csvPath = Join-Path $config.OutputPath "network_scan_${Network}_${timestamp}.csv"
    $htmlPath = Join-Path $config.OutputPath "network_scan_${Network}_${timestamp}.html"
    
    # Export to CSV
    $Results | Export-Csv -Path $csvPath -NoTypeInformation
    
    # Create HTML report
    $htmlHeader = @"
    <style>
        table { border-collapse: collapse; width: 100%; }
        th, td { padding: 8px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #4CAF50; color: white; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        tr:hover { background-color: #ddd; }
        .online { color: green; }
        .offline { color: red; }
    </style>
"@
    
    $htmlBody = $Results | ConvertTo-Html -Head $htmlHeader -PreContent "<h1>Network Scan Results</h1><p>Scan performed on $(Get-Date)</p>" |
        ForEach-Object { $_ -replace ">Online<", ' class="online">Online<' -replace ">Offline<", ' class="offline">Offline<' }
    
    $htmlBody | Out-File -FilePath $htmlPath
    
    Write-Log "Results exported to:"
    Write-Log "CSV: $csvPath"
    Write-Log "HTML: $htmlPath"
}

function Show-Progress {
    param(
        [int]$Current,
        [int]$Total,
        [string]$Activity = "Scanning network"
    )
    
    $percentComplete = ($Current / $Total) * 100
    Write-Progress -Activity $Activity -Status "$Current of $Total IPs scanned" -PercentComplete $percentComplete
}

# Main execution
try {
    Write-Log "Starting network scan" -Level Info
    
    $segmen = Read-Host "Please enter IP address (Example: 192.168.1.1)"
    if (-not (Test-InputValid -IP $segmen)) {
        throw "Invalid IP address format. Format should be: xxx.xxx.xxx.xxx where xxx is between 0 and 255"
    }
    
    $networkInfo = Get-NetworkInfo -IP $segmen
    
    # Get scan range
    $customRange = Read-Host "Do you want to specify a custom IP range? (Y/N)"
    if ($customRange -eq "Y") {
        do {
            $startRange = Read-Host "Enter start range (1-254)"
            $endRange = Read-Host "Enter end range (1-254)"
            $validRange = $startRange -match '^\d+$' -and $endRange -match '^\d+$' -and
                [int]$startRange -ge 1 -and [int]$startRange -le 254 -and
                [int]$endRange -ge 1 -and [int]$endRange -le 254 -and
                [int]$startRange -le [int]$endRange
            
            if (-not $validRange) {
                Write-Log "Invalid range. Please enter numbers between 1 and 254, with start <= end" -Level Warning
            }
        } while (-not $validRange)
    }
    else {
        $startRange = $config.DefaultStartRange
        $endRange = $config.DefaultEndRange
    }
    
    # DNS lookup option
    $dnsLookup = Read-Host "Enable DNS lookup? (Y/N)"
    $config.EnableDNS = $dnsLookup -eq "Y"
    
    Write-Log "Starting scan of $($networkInfo.Network).0/24 (Range: $startRange-$endRange)" -Level Info
    
    $results = @()
    $iprange = $startRange..$endRange
    $total = $iprange.Count
    $current = 0
    
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        Write-Log "Using parallel execution (PowerShell 7+)" -Level Info
        $results = $iprange | ForEach-Object -ThrottleLimit $config.MaxParallelJobs -Parallel {
            $ip = "$($using:networkInfo.FirstThreeOctets).$_"
            $result = & $using:PingCore -Hostname $ip -DNSLookup $using:config.EnableDNS -Timeout $using:config.PingTimeout -Retries $using:config.PingRetries
            
            # Update progress (note: this is per-thread)
            $parentProgress = @{
                Activity = "Scanning network"
                Status = "Processing IP: $ip"
                PercentComplete = ($_ / $using:total) * 100
            }
            Write-Progress @parentProgress
            
            $result
        }
    }
    else {
        Write-Log "Using sequential execution (PowerShell < 7)" -Level Info
        foreach ($ip1 in $iprange) {
            $ip = "$($networkInfo.FirstThreeOctets).$ip1"
            $results += Ping-Core -Hostname $ip -DNSLookup $config.EnableDNS -Timeout $config.PingTimeout -Retries $config.PingRetries
            
            $current++
            Show-Progress -Current $current -Total $total
        }
    }
    
    # Display results
    Write-Host "`nScan Results:"
    Write-Host "-------------"
    $results | ForEach-Object {
        $status = if ($_.Status -eq "Online") { "Online".PadRight(8) } else { "Offline".PadRight(8) }
        $hostname = if ($_.Hostname) { $_.Hostname } else { "N/A" }
        $responseTime = if ($_.ResponseTime) { "$($_.ResponseTime)ms" } else { "N/A" }
        Write-Host ("{0,-15} {1,-8} {2,-30} {3}" -f $_.IP, $status, $hostname, $responseTime)
    }
    
    # Export results
    Export-Results -Results $results -Network $networkInfo.Network
    
    # Summary
    $onlineCount = ($results | Where-Object { $_.Status -eq "Online" }).Count
    Write-Log "Scan completed. Found $onlineCount online hosts out of $total scanned." -Level Info
}
catch {
    Write-Log "Critical error: $($_.Exception.Message)" -Level Error
    Write-Host "Script terminated due to an unexpected error. Please check the log file for details."
}
finally {
    Write-Progress -Activity "Scanning network" -Completed
    Write-Log "Script execution completed" -Level Info
}