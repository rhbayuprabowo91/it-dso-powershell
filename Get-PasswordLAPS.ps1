# Configuration
$config = @{
    Domain = $env:USERDNSDOMAIN  # Gets current domain automatically
}

# Get credentials
$username = Read-Host "Please enter your username"
$password = Read-Host "Please enter your password" -MaskInput
$enkpassword = ConvertTo-SecureString $password -AsPlainText -Force
$creden = New-Object System.Management.Automation.PSCredential ($username, $enkpassword)

while ($true) {
    $hostname = Read-Host "Please enter hostname"
    try {
        $passwordremote = Get-LapsADPassword -Identity $hostname -Credential $creden -Domain $config.Domain -AsPlainText | Select-Object -ExpandProperty Password
        Write-Host "Password is: $passwordremote"
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Please ensure:"
        Write-Host "- The hostname exists in the domain"
        Write-Host "- You have appropriate permissions"
        Write-Host "- LAPS is properly configured in your environment"
    }
    
    $continue = Read-Host "Do you want to check another computer? (Y/N)"
    if ($continue -ne "Y") {
        break
    }
}
