$VersiPS = ((Get-Variable PSVersionTable -ValueOnly).PSVersion).Major
function Test-InputValid() {
    Param($IP)
    $segment = $IP.Split(".")
    if ($segment.Count -eq 4) {
        foreach ($seg in $segment) {
            if ($seg -notmatch "^[\d\.]+$") {
                Return $False
            }
        }
        Return $True
    }
    Return $False
}

function Ping-Core {
    param ($hostname)
    $iphost = $hostname
    $result = Test-Connection -ComputerName $iphost -Delay 1 -Count 3 -Quiet
    
    if ($result) {
        # $iphost + " is Online"
        # $computername = Resolve-DnsName -Name $iphost -ErrorAction SilentlyContinue | select -Expand NameHost
        $computername = Resolve-DnsName -Name $iphost -ErrorAction SilentlyContinue | Select-Object -ExpandProperty NameHost
        #$hostname + " | " + $computername
        Write-Output "$iphost | $result | $computername "
    }
    else {
        #$hostname + " is Offline"
    }
}
function Ping() {
    Param(
        $IP,
        $PingCore
    )
    $splitIP = $IP.Split(".")
    $ipname = $splitIP[0] + "." + $splitIP[1] + "." + $splitIP[2] + "."

    if ($VersiPS -eq 7) {
        $iprange | Foreach-Object -ThrottleLimit 100 -Parallel {
            $hostname = $($using:ipname) + $_
            ${Function:Ping-Core} = $using:PingCore
            Ping-Core -hostname $hostname
        }
    } else {        
        foreach ($ip1 in $iprange) {
           $hostname  = $ipname + $ip1
           Ping-Core -hostname $hostname
        }
    }
}

$segmen = Read-Host "Silahkan masukkan IP  (Contoh-> 10.71.70.1 )"
$iprange = 1..254

# $Segmen = "10.71.124."
if (Test-InputValid -IP $segmen) {
    Write-Output "Silahkan tunggu, sedang diproses...."
    $pingcore = ${Function:Ping-Core}.ToString()
    Ping -IP $segmen -PingCore $pingcore
}
else {
    Write-Output "Input IP tidak sesuai, silahkan coba lagi!"
}