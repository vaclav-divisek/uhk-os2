# Nasazení sandbox VM.
#   .\deploy.ps1                     -> vytvoří RG + VM s public IP (SSH povolen jen z tvé aktuální IP)
#   .\deploy.ps1 -NoPublicIp         -> odpojí a smaže public IP
#   .\deploy.ps1 -Destroy            -> smaže celou resource group
param(
    [string]$ResourceGroup = 'rg-linux-sandbox',
    [string]$Location = 'westeurope',
    [string]$SshKeyPath = "$HOME\.ssh\id_ed25519.pub",
    [switch]$NoPublicIp,
    [switch]$Destroy
)
$ErrorActionPreference = 'Stop'

if ($Destroy) {
    az group delete --name $ResourceGroup --yes --no-wait
    Write-Host "Mazání RG '$ResourceGroup' spuštěno."
    return
}

if (-not (Test-Path $SshKeyPath)) {
    Write-Host "SSH klíč $SshKeyPath neexistuje, generuji..."
    ssh-keygen -t ed25519 -f ($SshKeyPath -replace '\.pub$', '') -N '""'
}
$sshKey = (Get-Content $SshKeyPath -Raw).Trim()
$myIp = (Invoke-RestMethod -Uri 'https://api.ipify.org').Trim()
$enablePip = if ($NoPublicIp) { 'false' } else { 'true' }

az group create --name $ResourceGroup --location $Location --output none

az deployment group create `
    --resource-group $ResourceGroup `
    --template-file "$PSScriptRoot\main.bicep" `
    --parameters sshPublicKey="$sshKey" sshSourceAddressPrefix="$myIp/32" enablePublicIp=$enablePip `
    --query 'properties.outputs' --output json

# Bicep v incremental módu nesmaže odpojenou PIP, takže ji smažeme ručně.
if ($NoPublicIp) {
    az network public-ip delete --resource-group $ResourceGroup --name 'sandbox-pip'
    Write-Host 'Public IP odebrána.'
}
