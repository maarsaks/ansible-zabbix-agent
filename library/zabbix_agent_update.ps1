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

function DownloadUnzipAgent {
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
}



function CheckDirExist {
$IsZabbixDirectoryEmpty = Test-Path $ZabbixAgentDir -PathType Any
    if ($IsZabbixDirectoryEmpty -eq $False) {
    [System.IO.Directory]::CreateDirectory($ZabbixAgentDir) | Out-Null
    [System.IO.Directory]::CreateDirectory($OriginalConf) | Out-Null
    [System.IO.Directory]::CreateDirectory($OriginalBin) | Out-Null
    Copy-Item -Path $DownloadedConf -Destination $OriginalConf -PassThru | Out-Null
    }

}

#$result = @{}
#Set-Attr $result "msg" ""
#Set-Attr $result "changed" $false

$ServiceName = 'Zabbix Agent'
$TempDir = 'C:\Users\Default\AppData\Local\Temp\Zabbix\'
$Url = 'https://www.zabbix.com/downloads/' + $Version + '/zabbix_agent-' + $Version + '-windows-amd64-openssl.zip'
$ZipPath = $TempDir + 'zabbix_agent-' + $Version + '-windows-amd64-openssl.zip'
$DownloadedBin = 'C:\Users\Default\AppData\Local\Temp\Zabbix\bin\*'
$DownloadedConf = 'C:\Users\Default\AppData\Local\Temp\Zabbix\conf\*'
$OriginalBin = 'C:\Zabbix\bin'
$OriginalConf = 'C:\Zabbix\conf'
$ZabbixAgentDir = 'C:\Zabbix\'
[System.IO.Directory]::CreateDirectory($TempDir) | Out-Null
$IsDirectoryEmpty = Get-ChildItem $TempDir | Measure-Object



try {
    $ServiceObj = Get-Service -name "Zabbix Agent"
    $ServiceExist = 'true'
    }
        catch {
            $ServiceExist = 'false'
        }



if ($ServiceExist -eq 'false') {
    write-host "nie ma :((((((((((((((((("
    CheckDirExist
    DownloadUnzipAgent
    Copy-Item -Path $DownloadedBin -Destination $OriginalBin -PassThru | Out-Null
    cmd /c "Netsh.exe advfirewall firewall add rule name=Zabbix program=%SystemDrive%\Zabbix\bin\zabbix_agentd.exe protocol=tcp localport=10050 dir=in enable=yes action=allow profile=public,private,domain" | Out-Null
    & cmd /c 'C:\Zabbix\bin\zabbix_agentd.exe --config C:\Zabbix\conf\zabbix_agentd.conf --install >nul 2>&1'
    }
    else {
        DownloadUnzipAgent
        Stop-Service -Name $ServiceName
        if ($ServiceObj.Status -eq 'Stopped') {
            CheckDirExist
            Copy-Item -Path $DownloadedBin -Destination $OriginalBin -PassThru | Out-Null
            $result.msg = "Bin files replaced."
            }
            else {
                Stop-Service -Name $ServiceName
                Start-Sleep -s 2
                Copy-Item -Path $DownloadedBin -Destination $OriginalBin -PassThru | Out-Null
                $result.msg = "Bin files replaced."
            }
    }

Start-Service -Name $ServiceName
[System.IO.Directory]::Delete($TempDir, $true) | Out-Null
#$result.changed = $true
#$result.msg = "Succesfully updated Zabbix Agent"
#Exit-Json $result
