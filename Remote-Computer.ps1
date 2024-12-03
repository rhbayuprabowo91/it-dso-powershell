# Configuration
$config = @{
    Domain = $env:USERDNSDOMAIN  # Gets current domain automatically
    DefaultAdminAccount = "admdesktop"  # Can be changed as needed
}

function Get-MainMenu() {
    Clear-Host
    Write-Host "Remote Computer Access Tool"
    Write-Host "-------------------------"
    Write-Host "1. Use LAPS password"
    Write-Host "2. Use local/custom credentials"
    Write-Host "3. Exit"
    $menu = Read-Host "Please select an option"
    Return $menu
}

function Get-MenuLAPS() {
    $username = Read-Host "Please enter your domain username"
    $password = Read-Host "Please enter your password" -MaskInput
    $hostnameremote = Read-Host "Please enter target hostname"
    
    try {
        $enkpassword = ConvertTo-SecureString $password -AsPlainText -Force
        $passwordremote = Get-PasswordLAPS -Username $username -Password $enkpassword -Hostname $hostnameremote
        $enkPasswordremote = ConvertTo-SecureString $passwordremote -AsPlainText -Force
        $userremote = ".\$($config.DefaultAdminAccount)"
        
        Write-Host "Attempting to connect to $hostnameremote..."
        Invoke-RemoteComputer -Hostname $hostnameremote -User $userremote -Password $enkPasswordremote
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Please ensure:"
        Write-Host "- You have appropriate permissions"
        Write-Host "- The hostname exists in the domain"
        Write-Host "- LAPS is properly configured"
        Read-Host "Press Enter to continue"
    }
}

function Get-MenuLocal() {
    $username = Read-Host "Please enter username"
    $password = Read-Host "Please enter password" -MaskInput
    $hostnameremote = Read-Host "Please enter target hostname"
    
    try {
        $enkpassword = ConvertTo-SecureString $password -AsPlainText -Force
        Write-Host "Attempting to connect to $hostnameremote..."
        Invoke-RemoteComputer -User $username -Password $enkpassword -Hostname $hostnameremote
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Please ensure:"
        Write-Host "- The credentials are correct"
        Write-Host "- The hostname is reachable"
        Write-Host "- You have appropriate permissions"
        Read-Host "Press Enter to continue"
    }
}

function Invoke-RemoteComputer() {
    Param(
        [Parameter(Mandatory=$true)]
        [SecureString] $Password,
        
        [Parameter(Mandatory=$true)]
        [string] $User,
        
        [Parameter(Mandatory=$true)]
        [string] $Hostname
    )
    
    $CredenRemote = New-Object System.Management.Automation.PSCredential ($User, $Password)
    try {
        Enter-PSSession -ComputerName $Hostname -Credential $CredenRemote
    }
    catch {
        throw "Failed to establish remote session: $($_.Exception.Message)"
    }
}

function Get-PasswordLAPS() {
    Param(
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
        Return $PasswordRemote
    }
    catch {
        throw "Failed to retrieve LAPS password: $($_.Exception.Message)"
    }
}

# Main execution loop
do {
    $menu = Get-MainMenu
    switch ($menu) {
        "1" { Get-MenuLAPS }
        "2" { Get-MenuLocal }
        "3" { Write-Host "Exiting..."; break }
        default { Write-Host "Invalid option. Please try again." -ForegroundColor Yellow }
    }
} while ($menu -ne "3")