cd ~

If (! ((Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*).displayname -contains "Puppet Bolt") ) {
    $appname         = "Puppet Bolt" 
    $downloaduri     = "http://downloads.puppet.com/windows/puppet-bolt-x64-latest.msi"
    $downloadsuccess = $false
    $downloadfile    = "$Env:Temp\puppet-bolt-x64-latest.msi"
    $retryCount      = 5
    while ((-not $downloadsuccess) -and ($retryCount -ge 0)){
        try{
            (new-object System.Net.WebClient).DownloadFile($downloaduri, $downloadfile)
        } catch {
            Write-Error "Downloading $appname setup failed"
            Write-Host "Next attempt in 5 seconds"
            Start-Sleep -s 5

            $retryCount --
            if ($retryCount -eq 0) {
                Write-Host "Unable to successfully download $appname!"
                exit 1
            }
        } Finally {
            $downloadsuccess=$true
        }
    }

    $Arguments = @(
            "/i"
            "$Env:Temp\puppet-bolt-x64-latest.msi"
            "/qn"
            "/norestart"
        )
    Start-Process "msiexec.exe" -Wait -ArgumentList $Arguments
    Write-Host "Installed Puppet Bolt"
}

If (! ((Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*).displayname -contains "Microsoft Visual Studio Code") ) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $appname         = "VS Code" 
    $downloaduri     = "https://go.microsoft.com/fwlink/?Linkid=852157"
    $downloadsuccess = $false
    $downloadfile    = "$Env:Temp\VSCodeSetup-x64-latest.exe"
    $retryCount      = 5
    while ((-not $downloadsuccess) -and ($retryCount -ge 0)){
        try{
            (new-object System.Net.WebClient).DownloadFile($downloaduri, $downloadfile)
        } catch {
            Write-Error "Downloading $appname setup failed"
            Write-Host "Next attempt in 5 seconds"
            Start-Sleep -s 5

            $retryCount --
            if ($retryCount -eq 0) {
                Write-Host "Unable to successfully download $appname!"
                exit 1
            }
        } Finally {
            $downloadsuccess=$true
        }
    }

    $Arguments = @(
            "/VERYSILENT"
            "/SUPPRESSMSGBOXES"
            "/NORESTART"
            "/MERGETASKS=!runcode"
        )
    Start-Process "$Env:Temp\VSCodeSetup-x64-latest.exe" -Wait -ArgumentList $Arguments
    Write-Host "Installed VS Code"
}

If (! ((Get-ItemProperty HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*).displayname -contains "Google Chrome") ) {
    $appname         = "Google Chrome" 
    $downloaduri     = "http://dl.google.com/chrome/install/latest/chrome_installer.exe"
    $downloadsuccess = $false
    $downloadfile    = "$Env:Temp\ChromeInstaller.exe"
    $retryCount      = 5
    while ((-not $downloadsuccess) -and ($retryCount -ge 0)){
        try{
            (new-object System.Net.WebClient).DownloadFile($downloaduri, $downloadfile)
        } catch {
            Write-Error "Downloading $appname setup failed"
            Write-Host "Next attempt in 5 seconds"
            Start-Sleep -s 5

            $retryCount --
            if ($retryCount -eq 0) {
                Write-Host "Unable to successfully download $appname!"
                exit 1
            }
        } Finally {
            $downloadsuccess=$true
        }
    }

    Start-Process "$Env:Temp\ChromeInstaller.exe" -Wait -ArgumentList @("/silent", "/install")
    Write-Host "Installed Google Chrome"
}

$RegPath = "HKLM:SOFTWARE\Policies\Microsoft\Windows Defender"
If (!(Test-Path $RegPath)) {
  New-Item -Path $RegPath
  Write-Host "Created Windows Defender reg key"
}

If (!((Get-ItemProperty -Path $RegPath -Name "DisableAntiSpyware" -ErrorAction SilentlyContinue).DisableAntiSpyware -eq 1)) {
  New-ItemProperty -Path $RegPath -Name "DisableAntiSpyware" -PropertyType DWORD -Value 1 -Force
  Write-Host "Created DisableAntiSpyware reg value"
  Restart-Computer -Force -AsJob -Confirm:$false
}
