iwr -Uri "http://downloads.puppet.com/windows/puppet-bolt-x64-latest.msi" -OutFile ~/puppet-bolt-x64-latest.msi
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
iwr -Uri "https://go.microsoft.com/fwlink/?Linkid=852157" -OutFile ~/VSCodeSetup-x64-latest.exe

cd ~

$Arguments = @(
        "/i"
        "$((Get-Location).Path)\puppet-bolt-x64-latest.msi"
        "/qn"
        "/norestart"
    )
Start-Process "msiexec.exe" -Wait -ArgumentList $Arguments

$Arguments = @(
        "/VERYSILENT"
        "/SUPPRESSMSGBOXES"
        "/NORESTART"
        "/MERGETASKS=!runcode"
    )
Start-Process "$((Get-Location).Path)\VSCodeSetup-x64-latest.exe" -Wait -ArgumentList $Arguments

$RegPath = "HKLM:SOFTWARE\Policies\Microsoft\Windows Defender"
If (!(Test-Path $RegPath)) {
  New-Item -Path $RegPath
}

If (!((Get-ItemProperty -Path $RegPath -Name "DisableAntiSpyware" -ErrorAction SilentlyContinue).DisableAntiSpyware -eq 1)) {
  New-ItemProperty -Path $RegPath -Name "DisableAntiSpyware" -PropertyType DWORD -Value 1 -Force
  Restart-Computer -Force -AsJob
}
