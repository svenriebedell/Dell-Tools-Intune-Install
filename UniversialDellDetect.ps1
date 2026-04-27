<#
_author_ = Sven Riebe <sven_riebe@Dell.com>
_twitter_ = @SvenRiebe
_version_ = 1.0
_Dev_Status_ = Test_ready
Copyright ©2026 Dell Inc. or its subsidiaries. All Rights Reserved.

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
.Synopsis
   This PowerShell is for custom detection in Microsoft Intune or other solutions like this to detect Dell Tool by Name and Version.

.DESCRIPTION
   This PowerShell will check if the requested Dell Software is installed and checking if the Version is correct. As far the Software found by Name and the version is matched the script will return a "Found it"

   This script support the following applications
        - Dell Core Services
        - Dell SupportAssist (only Version 5.x and higher)
        - Dell SupportAssist Remediation
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

        .Parameter VersionIS
        Value is the operator for the version compare supported are:
            - Equal
            - Not equal
            - Less than
            - Less than or equal
            - Greater than
            - Greater than or equal

        .Parameter Version
        Value is the version of Dell Application to looking for like 5.6.0 or 2.2.0.19 depends on the tool.


        Changelog:
            1.0.0   Initial Version

        .Example
        This will looking if Dell Command | Update is installed and the version must be equal 5.6.0
        UniversialDellDetect.ps1 -DellTool 'Dell Command | Update' -VersionIS Equal -Version 5.6.0

#>


param(
            [Parameter(mandatory=$false)][ValidateSet("Dell Core Services", "Dell SupportAssist","Dell SupportAssist Remediation", "Dell SupportAssist OS Recovery Plugin for Dell Update", "Dell Display and Peripheral Manager", "Dell Command | Update", "Dell Command | Configure", "Dell Command | Endpoint Configure for Microsoft Intune", "Dell Command | Monitor", "Dell Trusted Device", "Dell Optimizer", "Dell Device Management Agent", "Dell Pair", "Dell Peripheral Core", "Dell Digital Delivery", "Microsoft Windows Desktop Runtime")][String]$DellTool,
            [Parameter(mandatory=$false)][ValidateSet("Equal","Not equal","Less than","Less than or equal","Greater than","Greater than or equal")][String]$VersionIS,
            [Parameter(mandatory=$false)][Version]$Version
    )

# Fallback if parameters are not provided by script call
if (-not $DellTool)  { $DellTool  = "Dell SupportAssist" }
if (-not $VersionIS) { $VersionIS = "Greater than or equal" }
if (-not $Version)   { $Version   = [Version]"5.0.1.2516" }

##################################################
# Varible Section                            #####
##################################################
$DellSoftwareList = @(
                        [PSCustomObject]@{NameParameter = "Dell SupportAssist OS Recovery Plugin for Dell Update"; SearchString = "Dell*SupportAssist*OS*Recovery*Plugin*"; SetupSearchString = "Dell*SupportAssist*OS*Recovery*Plugin*"; SilentSwitch = "/S"; Sequence = 2; Type = "EXE"; InstallSwitch = "/S"}
                        [PSCustomObject]@{NameParameter = "Dell Core Services"; SearchString = "Dell*Core*Services"; SetupSearchString = "Dell*Core*Services"; SilentSwitch = "/qn"; Sequence = 3; Type = "EXE"; InstallSwitch = "/S"}
                        [PSCustomObject]@{NameParameter = "Dell SupportAssist"; SearchString = "Dell*Supportassist"; SetupSearchString = "SupportAssist*"; SilentSwitch = "/qn"; Sequence = 1; Type = "EXE"; InstallSwitch = "ADDLOCAL='BASE,CORE,FULL,HWDIAGS,INSIGHTS,RAAS' SOURCE=TechDirect /norestart /qn"}
                        [PSCustomObject]@{NameParameter = "Dell SupportAssist Remediation"; SearchString = "Dell*Supportassist*Remediation"; SetupSearchString = "SupportAssist*"; SilentSwitch = "/qn"; Sequence = 3; Type = "EXE"; InstallSwitch = "ADDLOCAL='BASE,CORE,FULL,HWDIAGS,INSIGHTS,RAAS' SOURCE=TechDirect /norestart /qn"}
                        [PSCustomObject]@{NameParameter = "Dell Display and Peripheral Manager"; SearchString = "Dell*Display*Peripheral*Manager"; SetupSearchString = "DDPM-Setup*"; SilentSwitch = "/uninst /silent"; Sequence = 1; Type = "EXE"; InstallSwitch = "/Silent /InAppUpdateLock /TelemetryConsent=false"}
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

##################################################
# Function Section                           #####
##################################################
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

##################################################
# Program Section                            #####
##################################################

Try
    {
        $SoftwareName = $DellSoftwareList | where-object {$_.NameParameter -eq $DellTool} | select-object -ExpandProperty Searchstring

        if(Test-SoftwareInstalled -NamePattern $SoftwareName -VersionPattern $Version -ISPattern $VersionIS)
            {
                Write-Host "Found it!"
            }
    }
Catch
    {
        Write-Output "Script failed: $($_.Exception.Message)"
        Exit 1
    }