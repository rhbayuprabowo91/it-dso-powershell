function Get-MainMenu() {
    Write-Host "1. Menggunakan password LAPS"
    Write-Host "2. Menggunakan pasword local / custom"
    Write-Host "3. Keluar"
    $menu = Read-Host "Silahkan masukkan menu yang anda inginkan "
    Return $menu
}

function Get-MenuLAPS() {
    $username = Read-Host "Silahkan masukkan nik (IT Area)"
    $password = Read-Host "Silahkan masukkan password (IT Area)" -MaskInput
    $hostnameremote = Read-Host "Silahkan masukkan hostname yang akan diremote"
    $enkpassword = ConvertTo-SecureString $password -AsPlainText -Force
    $passwordremote = Get-PasswordLAPS -Username $username -Password $enkpassword -Hostname $hostnameremote
    $enkPasswordremote = ConvertTo-SecureString $passwordremote -AsPlainText -Force
    $userremote = ".\admdesktop"
    Invoke-RemoteComputer -Hostname $hostnameremote -User $userremote -Password $enkPasswordremote
    
}

function Get-MenuLocal() {
    $username = Read-Host "Silahkan masukkan username"
    $password = Read-Host "Silahkan masukkan password" -MaskInput
    $hostnameremote = Read-Host "Silahkan masukkan hostname yang akan diremote"
    $enkpassword = ConvertTo-SecureString $password -AsPlainText -Force
    Invoke-RemoteComputer -User $username -Password $enkpassword -Hostname $hostnameremote
}

function Invoke-RemoteComputer() {
    Param(
        [SecureString] $Password,
        $User,
        $Hostname
    )
    $CredenRemote = New-Object System.Management.Automation.PSCredential ($User, $Password)
    Enter-PSSession -ComputerName $Hostname -Credential $CredenRemote
}

function Get-PasswordLAPS() {
    Param(
        $Hostname,
        $Username,
        [SecureString] $Password
    )
    $Creden = New-Object System.Management.Automation.PSCredential ($Username, $Password)
    $PasswordRemote = Get-LapsADPassword -Identity $Hostname -Credential $Creden -Domain 'adira.co.id' -AsPlainText | Select-Object -ExpandProperty Password
    Return $PasswordRemote
}

$menu = Get-MainMenu
$menu
if ($menu -eq 1) {
    Get-MenuLAPS
} elseif ($menu -eq 2) {
    Get-MenuLocal
} else {
    
}