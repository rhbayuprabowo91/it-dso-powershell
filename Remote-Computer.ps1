

$username=Read-Host "Silahkan masukkan nik (IT Area)"
$password=Read-Host "Silahkan masukkan password (IT Area)" -MaskInput
$hostnameremote=Read-Host "Silahkan masukkan hostname yang akan diremote"
$enkpassword=ConvertTo-SecureString $password -AsPlainText -Force
$creden = New-Object System.Management.Automation.PSCredential ($username, $enkpassword)
try {
    $passwordremote=Get-LapsADPassword -Identity $hostnameremote -Credential $creden -Domain 'adira.co.id' -AsPlainText | Select-Object -ExpandProperty Password
    $enkPasswordremote = ConvertTo-SecureString $passwordremote -AsPlainText -Force
    $userremote=".\admdesktop"
    $credenremote = New-Object System.Management.Automation.PSCredential ($userremote, $enkPasswordremote)
    Enter-PSSession -ComputerName $hostnameremote -Credential $credenremote
}
catch {
    Write-Host $_.Exception.Message
}





