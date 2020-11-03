#!powershell
#Requires -Module Ansible.ModuleUtils.Legacy

# ansible-playbook update-zabbix-agent.yml --extra-vars "$Version = 5.2.0"

$Version = "5.2.0"

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0


Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip {
    param([string]$zipfile, [string]$outpath)
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

$result = @{}
Set-Attr $result "msg" ""
Set-Attr $result "changed" $false

$ServiceName = 'Zabbix Agent'
$ServiceObj = Get-Service -name "Zabbix Agent"
$TempDir = 'C:\Users\Default\AppData\Local\Temp\Zabbix\'
$Url = 'https://www.zabbix.com/downloads/' + $Version + '/zabbix_agent-' + $Version + '-windows-amd64-openssl.zip'
$ZipPath = $TempDir + 'zabbix_agent-' + $Version + '-windows-amd64-openssl.zip'
$DownloadedBin = 'C:\Users\Default\AppData\Local\Temp\Zabbix\bin\*'
$OriginalBin = 'C:\Zabbix\bin'
[System.IO.Directory]::CreateDirectory($TempDir) | Out-Null
$IsDirectoryEmpty = Get-ChildItem $TempDir | Measure-Object

if ($IsDirectoryEmpty.count -ne 0) {
    Get-ChildItem -Path $TempDir -Include * | Remove-Item -recurse
    Invoke-WebRequest $Url -OutFile $ZipPath
    Unzip $ZipPath $TempDir
    $result.msg = "Downloaded and unzipped."
    }
    else {
        Invoke-WebRequest $Url -OutFile $ZipPath
        Unzip $ZipPath $TempDir
        $result.msg = "Downloaded and unzipped."
    }

Stop-Service -Name $ServiceName
if ($ServiceObj.Status -eq 'Stopped') {
    Copy-Item -Path $DownloadedBin -Destination $OriginalBin -PassThru | Out-Null
    $result.msg = "Bin files replaced."
    }
    else {
        Stop-Service -Name $ServiceName
        Start-Sleep -s 2
        Copy-Item -Path $DownloadedBin -Destination $OriginalBin -PassThru | Out-Null
        $result.msg = "Bin files replaced."
    }

Start-Service -Name $ServiceName
[System.IO.Directory]::Delete($TempDir, $true) | Out-Null
$result.changed = $true
$result.msg = "Succesfully updated Zabbix Agent"
Exit-Json $result
