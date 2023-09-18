$username=Read-Host "Silahkan masukkan nik (IT Area)"
$password=Read-Host "Silahkan masukkan password (IT Area)" -MaskInput
$enkpassword=ConvertTo-SecureString $password -AsPlainText -Force
$creden = New-Object System.Management.Automation.PSCredential ($username, $enkpassword)
while ($true) {
    $hostname=Read-Host "Silahkan masukkan hostname"
    $passwordremote=Get-LapsADPassword -Identity $hostname -Credential $creden -Domain 'adira.co.id' -AsPlainText | Select-Object -ExpandProperty Password
    Write-Host "Passwordnya adalah: $passwordremote"
}

