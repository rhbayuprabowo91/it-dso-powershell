# Get PowerShell version
$VersiPS = ((Get-Variable PSVersionTable -ValueOnly).PSVersion).Major

function Test-InputValid() {
    Param($IP)
    $segment = $IP.Split(".")
    if ($segment.Count -eq 4) {
        foreach ($seg in $segment) {
            if ($seg -notmatch "^[\d\.]+$") {
                Return $False
            }
            if ([int]$seg -lt 0 -or [int]$seg -gt 255) {
                Return $False
            }
        }
        Return $True
    }
    Return $False
}

function Ping-Core {
    param (
        $hostname,
        $DNSLookup = $true
    )
    $iphost = $hostname
    $result = Test-Connection -ComputerName $iphost -Count 3 -Quiet
    
    if ($result) {
        if ($DNSLookup) {
            try {
                $computername = Resolve-DnsName -Name $iphost -ErrorAction SilentlyContinue | 
                    Select-Object -ExpandProperty NameHost
            }
            catch {
                $computername = "DNS resolution failed"
            }
        }
        else {
            $computername = "DNS lookup disabled"
        }
        Write-Output "$iphost | Online | $computername"
    }
    else {
        Write-Output "$iphost | Offline"
    }
}

function Ping() {
    Param(
        $IP,
        $PingCore,
        $StartRange = 1,
        $EndRange = 254,
        $DNSLookup = $true
    )
    $splitIP = $IP.Split(".")
    $ipname = $splitIP[0] + "." + $splitIP[1] + "." + $splitIP[2] + "."
    $iprange = $StartRange..$EndRange

    Write-Host "Starting network scan from $($ipname)$StartRange to $($ipname)$EndRange"
    Write-Host "DNS Lookup is $($DNSLookup ? 'enabled' : 'disabled')"

    if ($VersiPS -ge 7) {
        $iprange | ForEach-Object -ThrottleLimit 100 -Parallel {
            $hostname = $($using:ipname) + $_
            ${Function:Ping-Core} = $using:PingCore
            Ping-Core -hostname $hostname -DNSLookup $using:DNSLookup
        }
    }
    else {
        Write-Host "Running in sequential mode (PowerShell < 7)"
        foreach ($ip1 in $iprange) {
            $hostname = $ipname + $ip1
            Ping-Core -hostname $hostname -DNSLookup $DNSLookup
        }
    }
}

# Configuration options
$config = @{
    DefaultStartRange = 1
    DefaultEndRange = 254
    EnableDNS = $true
}

# Main execution
Write-Host "Network Scanner"
Write-Host "---------------"
$segmen = Read-Host "Please enter IP address (Example: 192.168.1.1)"

if (Test-InputValid -IP $segmen) {
    $customRange = Read-Host "Do you want to specify a custom IP range? (Y/N)"
    if ($customRange -eq "Y") {
        $startRange = Read-Host "Enter start range (1-254)"
        $endRange = Read-Host "Enter end range (1-254)"
        if (![int]::TryParse($startRange, [ref]$null) -or ![int]::TryParse($endRange, [ref]$null) -or 
            [int]$startRange -lt 1 -or [int]$startRange -gt 254 -or 
            [int]$endRange -lt 1 -or [int]$endRange -gt 254 -or 
            [int]$startRange -gt [int]$endRange) {
            Write-Host "Invalid range specified. Using default range (1-254)"
            $startRange = $config.DefaultStartRange
            $endRange = $config.DefaultEndRange
        }
    }
    else {
        $startRange = $config.DefaultStartRange
        $endRange = $config.DefaultEndRange
    }

    $dnsLookup = Read-Host "Enable DNS lookup? (Y/N)"
    $config.EnableDNS = $dnsLookup -eq "Y"

    Write-Host "Processing, please wait..."
    $pingcore = ${Function:Ping-Core}.ToString()
    Ping -IP $segmen -PingCore $pingcore -StartRange $startRange -EndRange $endRange -DNSLookup $config.EnableDNS
}
else {
    Write-Host "Invalid IP address format. Please try again!" -ForegroundColor Red
    Write-Host "Format should be: xxx.xxx.xxx.xxx where xxx is between 0 and 255"
}