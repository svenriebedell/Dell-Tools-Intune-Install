<#
_author_ = Sven Riebe <sven_riebe@Dell.com>
_twitter_ = @SvenRiebe
_version_ = 1.0.0
_Dev_Status_ = Test
Copyright (c)2026 Dell Inc. or its subsidiaries. All Rights Reserved.

No implied support and test in test environment/device before using in any production environment.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
#>

<#

Change Log
    1.0.0   initial version

#>

<#
.Synopsis
   This PowerShell is installing Dell Management Tools, the installer file need to be stored in the same directory like this script.

.DESCRIPTION
   This PowerShell will install/Update a Dell Tool on a Windows Device

      This script support the following applications
        - Dell Core Services
        - Dell SupportAssist (only Version 5.x and higher)
        - Dell SupportAssist OS Recovery Plugin for Dell Update
        - Dell Display and Peripheral Manager
        - Dell Device Management Agent (Agent for Dell Device Management Console for Peripherals updates)
        - Dell Command | Update (Universal App and Classic)
        - Dell Command | Configure
        - Dell Command | Endpoint Configure for Microsoft Intune
        - Dell Command | Monitor
        - Dell Trusted Device
        - Dell Optimizer
        - Dell Pair
        - Dell Peripheral Core
        - Dell Digital Delivery
        - Microsoft Windows Desktop Runtime (because some Dell tools require this as preparation)

        .Parameter DellTool
        Value is the Name of Dell Application to looking for like example Dell Trusted Device

        .Parameter UninstallOldVersion
        Value is True or False to uninstall the old version of the Dell Tool (becareful to clean an existing installation because of some tools doing a deregistration or requrie a reboot)

        .Example
        This will install Dell Command | Update but not uninstall the old version
        UniversialDellInstall.ps1 -DellTool 'Dell Command | Update' -UninstallOldVersion $False

        .Example
        This will install Dell Command | Update and uninstall the old version
        UniversialDellInstall.ps1 -DellTool 'Dell Command | Update' -UninstallOldVersion $True

#>

param(
            [Parameter(mandatory=$false)][ValidateSet("Dell Core Services","Dell Digital Delivery","Dell Peripheral Core","Dell SupportAssist","Dell SupportAssist OS Recovery Plugin for Dell Update","Dell Display and Peripheral Manager","Dell Device Management Agent","Dell Command | Update","Dell Command | Configure","Dell Command | Endpoint Configure for Microsoft Intune","Dell Command | Monitor","Dell Trusted Device","Dell Optimizer","Dell Device Management Agent","Dell Pair","Microsoft Windows Desktop Runtime 6","Microsoft Windows Desktop Runtime 8","Microsoft Windows Desktop Runtime 9","Microsoft Windows Desktop Runtime 10")][String]$DellTool,
            [Parameter(mandatory=$false)][ValidateSet("true","false")][string]$UninstallOldVersion
    )

# Fallback if parameters are not provided by script call
if (-not $DellTool)  { $DellTool  = "Dell SupportAssist" }
if (-not $UninstallOldVersion) { $UninstallOldVersion = "false" }

$DEPLOYMENTKEY = "Add your Deploymentkey you have used at the deployment package creator" #only required for Dell SupportAssist MSI deployment
$DCDMGROUPTOKEN = "Add your Group token" #only required for Dell Client Device Manager

##############################################
#### Function section                     ####
##############################################

function Test-SoftwareInstalled
    {
        param(
                    [Parameter(mandatory=$false)][string]$NamePattern,
                    [Parameter(mandatory=$false)][ValidateSet("Equal","Not equal","Less than","Less than or equal","Greater than","Greater than or equal")][String]$ISPattern,
                    [Parameter(mandatory=$false)][Version]$VersionPattern
            )

        # Uninstall-Path (64-bit & 32-bit)
        $paths = @(
                    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
                    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
                )


        # cover name conversion of Dell SupportAssist for Business PCs to Dell SupportAssist.
        if($NamePattern -eq "Dell Supportassist" -and [Version]$VersionPattern -lt "5.0")
            {
                $NamePattern = "Dell Supportassist*Business*PCs"
            }

        $items = foreach ($path in $paths)
            {
                try
                    {
                        If ($NamePattern -ne "Microsoft Windows Desktop Runtime*(x64)*")
                            {
                                Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | Where-Object {$_.DisplayName -like $NamePattern}
                            }
                        else
                            {
                                If ($path -like $paths[1])
                                    {
                                        Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | Where-Object {$_.DisplayName -like $NamePattern}
                                    }
                            }
                    }
                catch
                    {
                        Write-Output "Path no found" | Out-Null
                    }
            }

        #Checking be different operators if displayversion match
        if($ISPattern -eq "Equal")
            {
                $match = $items | Where-Object {[version]$_.DisplayVersion -eq [version]$VersionPattern}
            }
        elseif($ISPattern -eq "Not equal")
            {
                $match = $items | Where-Object {[version]$_.DisplayVersion -ne [version]$VersionPattern}
            }
        elseif($ISPattern -eq "Less than")
            {
                $match = $items | Where-Object {[version]$_.DisplayVersion -lt [version]$VersionPattern}
            }
        elseif($ISPattern -eq "Less than or equal")
            {
                $match = $items | Where-Object {[version]$_.DisplayVersion -le [version]$VersionPattern}
            }
        elseif($ISPattern -eq "Greater than")
            {
                $match = $items | Where-Object {[version]$_.DisplayVersion -gt [version]$VersionPattern}
            }
        elseif($ISPattern -eq "Greater than or equal")
            {
                $match = $items | Where-Object {[version]$_.DisplayVersion -ge [version]$VersionPattern}
            }

        return $match
    }

function Get-FileVersion
    {
        param (
                [Parameter(Mandatory=$true)][string]$FileName,
                [Parameter(Mandatory=$true)][ValidateSet("MSI", "EXE")][string]$FileType
        )

        $FullPath = Resolve-Path $FileName

        if (-not (Test-Path -Path $FullPath))
            {
                Write-Information "File not found: $FullPath" -InformationAction Continue
                return $null
            }

        switch ($FileType)
            {
                "MSI"
                    {
                        try
                            {
                                $WindowsInstaller = New-Object -com WindowsInstaller.Installer
                                $Database = $WindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $Null, $WindowsInstaller, @($FullPath.Path, 0))
                                $Query = "SELECT Value FROM Property WHERE Property = 'ProductVersion'"
                                $View = $database.GetType().InvokeMember("OpenView", "InvokeMethod", $Null, $Database, ($Query))
                                $View.GetType().InvokeMember("Execute", "InvokeMethod", $Null, $View, $Null) | Out-Null
                                $Record = $View.GetType().InvokeMember( "Fetch", "InvokeMethod", $Null, $View, $Null )
                                $fileVersion = $Record.GetType().InvokeMember( "StringData", "GetProperty", $Null, $Record, 1 )
                                return $fileVersion
                            }
                        catch
                            {
                                Write-Information "Failed to get MSI file version. Error: $_" -InformationAction Continue
                                return $false
                            }
                    }
                "EXE"
                    {
                        try
                            {
                                [Version]$fileVersion = (Get-Item -Path $FullPath).VersionInfo.ProductVersion
                                return $fileVersion
                            }
                        catch
                            {
                                Write-Information "Failed to get EXE file version. Error: $_" -InformationAction Continue
                                return $false
                            }
                    }
            }
    }

function Install-DellTool
    {
        param (
                [Parameter(Mandatory=$true)][string]$InstallString,
                [Parameter(Mandatory=$true)][string]$FullPathFile,
                [Parameter(Mandatory=$true)][ValidateSet("MSI", "EXE")][string]$FileType
        )

        $SupportAssist = @(
                            [PSCustomObject]@{Type = "MST"; InstallSwitch = "ADDLOCAL='BASE,CORE,FULL,HWDIAGS,INSIGHTS,RAAS' TRANSFORMS='.\SupportAssistConfiguration.mst' DEPLOYMENTKEY='$DEPLOYMENTKEY' SOURCE=TechDirect /norestart /qn /l+ 'c:\temp\SupportAssistMsi.log'"}
                        )

        If($FileType -eq "MSI")
            {
                # Install MSI
                try
                    {
                        If ($FullPathFile -notlike "*SupportAssist*")
                            {
                                Start-Process msiexec.exe -ArgumentList "/i `"$FullPathFile`" $InstallString /qn /norestart" -Wait -NoNewWindow
                                Write-Information "Successfully installed $FullPathFile" -InformationAction Continue
                            }
                        else
                            {
                                #check for MST file
                                $MSTFound = Test-Path .\SupportAssistConfiguration.mst

                                If($MSTFound -eq $true)
                                    {
                                        # create log path
                                        try
                                            {
                                                New-Item -Path C:\temp -ItemType Directory -ErrorAction Stop
                                            }
                                        catch
                                            {
                                                Write-Verbose "Logging path exist" -Verbose
                                            }

                                        # build Support MSI install agrumentlist
                                        $Argument = $SupportAssist | Where-Object {$_.type -eq "MST"} | Select-Object -ExpandProperty InstallSwitch
                                        $ArgumentList = "/i '"+ $FileNamePath + "' " + $Argument
                                        $ArgumentList = $ArgumentList.Replace("'",'"')
                                        $ArgumentList = $ArgumentList.Replace(".\","")

                                        Start-Process msiexec.exe -ArgumentList $ArgumentList -Wait -NoNewWindow
                                    }
                                else
                                    {
                                        # Install without MST File
                                        $ArgumentList = $InstallString.Replace("'",'"')
                                        $FullPathFile = $FullPathFile.Replace(".\","")
                                        Start-Process .\$FullPathFile -ArgumentList $InstallString -Wait -NoNewWindow
                                    }

                                Write-Information "Successfully installed $FullPathFile" -InformationAction Continue
                            }
                    }
                catch
                    {
                        Write-Information "Failed to install $FullPathFile. Error: $_" -InformationAction Continue
                    }
            }
        ElseIf($FileType -eq "EXE")
            {
                # Install EXE
                try
                    {
                        If ($FullPathFile -notlike "*DellDeviceManagementAgent.SubAgent*" -or $FullPathFile -notlike "*SupportAssist*")
                            {
                                Start-Process "$FullPathFile" -ArgumentList "$InstallString /S" -Wait -NoNewWindow
                                Write-Information "Successfully installed $FullPathFile" -InformationAction Continue
                            }
                        else
                            {
                                If ($FullPathFile -notlike "*SupportAssist*")
                                    {
                                        # build Support EXE install agrumentlist
                                        $ArgumentList = $InstallString.Replace("'",'"')
                                        $FullPathFile = $FullPathFile.Replace(".\","")
                                        Start-Process .\$FullPathFile -ArgumentList $InstallString -Wait -NoNewWindow
                                    }
                                else
                                    {
                                        #check for MST file
                                        $MSTFound = Test-Path .\SupportAssistConfiguration.mst

                                        If($MSTFound -eq $true)
                                            {
                                                # create log path
                                                try
                                                    {
                                                        New-Item -Path C:\temp -ItemType Directory -ErrorAction Stop
                                                    }
                                                catch
                                                    {
                                                        Write-Verbose "Logging path exist" -Verbose
                                                    }

                                                # build Support MSI install agrumentlist
                                                $Argument = $SupportAssist | Where-Object {$_.type -eq "MST"} | Select-Object -ExpandProperty InstallSwitch
                                                Start-Process "$FullPathFile" -ArgumentList $Argument -Wait -NoNewWindow
                                            }
                                        else
                                            {
                                                # Install without MST File
                                                $ArgumentList = $InstallString.Replace("'",'"')
                                                $FullPathFile = $FullPathFile.Replace(".\","")
                                                Start-Process .\$FullPathFile -ArgumentList $InstallString -Wait -NoNewWindow
                                            }

                                        Write-Information "Successfully installed $FullPathFile" -InformationAction Continue
                                    }

                                Write-Information "Successfully installed $FullPathFile" -InformationAction Continue
                            }
                    }
                catch
                    {
                        Write-Information "Failed to install $FullPathFile. Error: $_" -InformationAction Continue
                    }
            }
    }

##############################################
#### variable section                     ####
##############################################
$DellSoftwareList = @(
                        [PSCustomObject]@{NameParameter = "Dell SupportAssist OS Recovery Plugin for Dell Update"; SearchString = "Dell*SupportAssist*OS*Recovery*Plugin*"; SetupSearchString = "Dell*SupportAssist*OS*Recovery*Plugin*"; SilentSwitch = "/S"; Sequence = 2; Type = "EXE"; InstallSwitch = "/S"}
                        [PSCustomObject]@{NameParameter = "Dell Core Services"; SearchString = "Dell*Core*Services"; SetupSearchString = "Dell*Core*Services"; SilentSwitch = "/qn"; Sequence = 3; Type = "EXE"; InstallSwitch = "/S"}
                        [PSCustomObject]@{NameParameter = "Dell SupportAssist"; SearchString = "Dell*Supportassist"; SetupSearchString = "SupportAssist*"; SilentSwitch = "/qn"; Sequence = 1; Type = "EXE"; InstallSwitch = "ADDLOCAL='BASE,CORE,FULL,HWDIAGS,INSIGHTS,RAAS' SOURCE=TechDirect /norestart /qn"}
                        [PSCustomObject]@{NameParameter = "Dell SupportAssist Remediation"; SearchString = "Dell*Supportassist*Remediation"; SetupSearchString = "SupportAssist*"; SilentSwitch = "/qn"; Sequence = 3; Type = "EXE"; InstallSwitch = "ADDLOCAL='BASE,CORE,FULL,HWDIAGS,INSIGHTS,RAAS' SOURCE=TechDirect /norestart /qn"}
                        [PSCustomObject]@{NameParameter = "Dell Display and Peripheral Manager"; SearchString = "Dell*Display*Peripheral*Manager"; SetupSearchString = "DDPM-Setup*"; SilentSwitch = "/uninst /silent"; Sequence = 1; Type = "EXE"; InstallSwitch = "/Silent"}
                        [PSCustomObject]@{NameParameter = "Dell Device Management Agent"; SearchString = "Dell*Device*Management*Agent"; SetupSearchString = "DellDeviceManagementAgent.SubAgent*"; SilentSwitch = "/qn"; Sequence = 1; Type = "EXE"; InstallSwitch = '/s /v"/qn GROUPTOKEN="{0}" URL="https://device.manage.dell.com" /lv* C:\ProgramData\Dell\DDMA_installer.log"' -f $DCDMGROUPTOKEN}
                        [PSCustomObject]@{NameParameter = "Dell Client Device Manager"; SearchString = "Dell*Device*Management*Agent"; SetupSearchString = "Dell_Client_Device_Manager*"; SilentSwitch = "/qn"; Sequence = 1; Type = "EXE"; InstallSwitch = "/S"}
                        [PSCustomObject]@{NameParameter = "Dell Command | Update"; SearchString = "Dell*Command*Update*"; SetupSearchString = "Dell*Command*Update*"; SilentSwitch = "/qn"; Sequence = 1; Type = "EXE"; InstallSwitch = "/S"}
                        [PSCustomObject]@{NameParameter = "Dell Command | Configure"; SearchString = "Dell*Command*Configure"; SetupSearchString = "Dell*Command*Configure"; SilentSwitch = "/qn"; Sequence = 1; Type = "EXE"; InstallSwitch = "/S"}
                        [PSCustomObject]@{NameParameter = "Dell Command | Endpoint Configure for Microsoft Intune"; SetupSearchString = "Dell-Command-Endpoint*"; SearchString = "Dell*Command*Endpoint*Configure*Intune"; SilentSwitch = "/qn"; Sequence = 1; Type = "EXE"; InstallSwitch = "/S"}
                        [PSCustomObject]@{NameParameter = "Dell Command | Monitor"; SearchString = "Dell*Command*Monitor"; SetupSearchString = "Dell*Command*Monitor"; SilentSwitch = "/qn"; Sequence = 1; Type = "EXE"; InstallSwitch = "/S"}
                        [PSCustomObject]@{NameParameter = "Dell Trusted Device"; SearchString = "Dell*Trusted*Device"; SetupSearchString = "Dell*Trusted*Device"; SilentSwitch = "/qn"; Sequence = 1; Type = "EXE"; InstallSwitch = "/S"}
                        [PSCustomObject]@{NameParameter = "Dell Optimizer"; SearchString = "Dell*Optimizer"; SetupSearchString = "Dell*Optimizer"; SilentSwitch = "/Silent"; Sequence = 1; InstallSwitch = "/S"}
                        [PSCustomObject]@{NameParameter = "Dell Device Management Agent"; SearchString = "Dell*Device*Management*Agent"; SetupSearchString = "Dell*Device*Management*Agent"; SilentSwitch = "/qn"; Sequence = 1; InstallSwitch = "/S"}
                        [PSCustomObject]@{NameParameter = "Dell Pair"; SearchString = "Dell*Pair"; SetupSearchString = "Dell*Pair"; SilentSwitch = "/S"; Sequence = 2; InstallSwitch = "/S"}
                        [PSCustomObject]@{NameParameter = "Dell Peripheral Core"; SearchString = "Dell*Peripheral*Core"; SetupSearchString = "Dell*Peripheral*Core"; SilentSwitch = "/qn"; Sequence = 3; InstallSwitch = "/S"}
                        [PSCustomObject]@{NameParameter = "Dell Digital Delivery"; SearchString = "Dell*Digital*Delivery*"; SetupSearchString = "Dell*Digital*Delivery*"; SilentSwitch = "/qn"; Sequence = 2; InstallSwitch = "/S"}
                        [PSCustomObject]@{NameParameter = "Microsoft Windows Desktop Runtime 6"; SearchString = "Microsoft*Windows*Desktop*Runtime*6*(x64)*"; SetupSearchString = "windowsdesktop-runtime*"; SilentSwitch = "/quiet /norestart"; Sequence = 9; InstallSwitch = "/install /quiet /norestart"}
                        [PSCustomObject]@{NameParameter = "Microsoft Windows Desktop Runtime 8"; SearchString = "Microsoft*Windows*Desktop*Runtime*8*(x64)*"; SetupSearchString = "windowsdesktop-runtime*"; SilentSwitch = "/quiet /norestart"; Sequence = 9; InstallSwitch = "/install /quiet /norestart"}
                        [PSCustomObject]@{NameParameter = "Microsoft Windows Desktop Runtime 9"; SearchString = "Microsoft*Windows*Desktop*Runtime*9*(x64)*"; SetupSearchString = "windowsdesktop-runtime*"; SilentSwitch = "/quiet /norestart"; Sequence = 9; InstallSwitch = "/install /quiet /norestart"}
                        [PSCustomObject]@{NameParameter = "Microsoft Windows Desktop Runtime 10"; SearchString = "Microsoft*Windows*Desktop*Runtime*10*(x64)*"; SetupSearchString = "windowsdesktop-runtime*"; SilentSwitch = "/quiet /norestart"; Sequence = 9; InstallSwitch = "/install /quiet /norestart"}
                    )

[version]$FileVersion = "0.0.0.0"

$FilePath = ".\"

##############################################
#### program section                      ####
##############################################

#### generate Logging Resources
try
    {
        [System.Diagnostics.EventLog]::CreateEventSource("Dell Software Install", "Dell")
        Write-Verbose "Event source Dell Software Install created for log Dell." -Verbose
    }
catch
    {
        Write-Verbose "Event source Dell Software Install exist." -Verbose
    }

# select the searchstring for function
$Software = $DellSoftwareList | where-object {$_.NameParameter -eq $DellTool}

# get Software details
$SoftwareDetails = Test-SoftwareInstalled -NamePattern $Software.SearchString -VersionPattern 0.0.0.0 -ISPattern "Greater than"

# get current version as far installed
$ProgramVersionCurrent = $SoftwareDetails.DisplayVersion | Sort-Object -Descending | Select-Object -First 1

# avoid error with ms eventlogs as far no older version was found
If ($null -eq $ProgramVersionCurrent)
    {
        [version]$ProgramVersionCurrent = "0.0.0.0"
    }

# get target version from installer
$Filename = Get-ChildItem -Path $FilePath | Where-Object {$_.Name -like "$($Software.SetupSearchString)*.exe" -or $_.Name -like "$($Software.SetupSearchString)*.msi"  } | Select-Object -ExpandProperty Name
$FileExtension = [System.IO.Path]::GetExtension($Filename) | ForEach-Object { $_.Replace(".", "") }

$FileNamePath = Join-Path $FilePath $Filename
$FileVersion = Get-FileVersion -FileType $FileExtension -FileName $Filename

# log Versions to eventlog
Write-Verbose "Current Version: $ProgramVersionCurrent" -Verbose
Write-Verbose "Target Version: $FileVersion" -Verbose

$UninstallData = [PSCustomObject]@{
                                        Software = $($Software.NameParameter)
                                        Version = $ProgramVersionCurrent.ToString()
                                        TargetVersion = $FileVersion.ToString()
                                        SelectUninstall = $UninstallOldVersion
                                    } | ConvertTo-Json

Write-EventLog -LogName Dell -Source "Dell Software Install" -EntryType Information -EventId 10 -Message $UninstallData

# Uninstall old version if requested
If($UninstallOldVersion -eq $true)
    {
        try
            {
                if($DellTool -notlike "Dell Trusted*")
                    {
                        if (Test-Path (Join-Path $FilePath UniversialDellUninstall.ps1))
                            {
                                Write-Verbose "UniversialDellUninstall.ps1 found" -Verbose

                                # snap-in uninstall universal script
                                & (Join-Path $FilePath UniversialDellUninstall.ps1) -DellTool "$DellTool"
                            }
                        else
                            {
                                Write-Verbose "UniversialDellUninstall.ps1 not found" -Verbose
                            }
                    }
                else
                    {
                        Write-Verbose "Dell Trusted Device required a restart after uninstall, that´s why this script support only an application upgrade to avoid a restart" -Verbose
                    }

            }
        catch
            {
                Write-Information "Uninstall process failed" -InformationAction Continue
            }
    }
Else
    {
        Write-Verbose "No uninstall requested application will be upgraded" -Verbose
    }

# compare versions if newer version is available
if ($FileVersion -gt $ProgramVersionCurrent)
    {
        Write-Verbose "Newer version of $($Software.NameParameter) is available. Current: $ProgramVersionCurrent, Target: $FileVersion" -Verbose

        # install new version
        Install-DellTool -InstallString $Software.InstallSwitch -FullPathFile $FileNamePath -FileType $FileExtension


        $UninstallResult = Test-SoftwareInstalled -NamePattern $Software.SearchString -VersionPattern 0.0.0.0 -ISPattern "Greater than"

            If ($null -ne $UninstallResult -and $FileVersion -gt $ProgramVersionCurrent)
                    {

                        Write-Verbose "Installation is successful" -Verbose

                        $UninstallData = [PSCustomObject]@{
                                                            Software = $($Software.NameParameter)
                                                            Version = $FileVersion.ToString()
                                                            Install = $true
                                                            Uninstall = $UninstallOldVersion
                                                            Reason = "Update/Install/Newer Version"
                                                        } | ConvertTo-Json

                        Write-EventLog -LogName Dell -Source "Dell Software Install" -EntryType Information -EventId 10 -Message $UninstallData
                    }
            Else
                    {
                        Write-Verbose "Installation is unsuccessful" -Verbose

                        $UninstallData = [PSCustomObject]@{
                                                            Software = $($SoftwareName).$NamePattern
                                                            Version = $FileVersion.ToString()
                                                            Install = $true
                                                            Uninstall = $UninstallOldVersion
                                                            Reason = "Older Version installed $ProgramVersion_current"
                                                            } | ConvertTo-Json

                        Write-EventLog -LogName Dell -Source "Dell Software Install" -EntryType Information -EventId 10 -Message $UninstallData
                    }
    }
else
    {
        Write-Verbose "No newer version of $($Software.NameParameter) is available. Current: $ProgramVersionCurrent, Target: $FileVersion" -Verbose

        $UninstallData = [PSCustomObject]@{
                                            Software = $($SoftwareName).$NamePattern
                                            Version = $ProgramVersionCurrent.ToString()
                                            Install = $false
                                            Uninstall = $UninstallOldVersion
                                            Reason = "No newer version available"
                                            } | ConvertTo-Json

        Write-EventLog -LogName Dell -Source "Dell Software Install" -EntryType Information -EventId 10 -Message $UninstallData
    }