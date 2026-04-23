<#
_author_ = Sven Riebe <sven_riebe@Dell.com>
_twitter_ = @SvenRiebe
_version_ = 1.0
_Dev_Status_ = Test
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
   This PowerShell is for uninstall Dell tools by Name and in Microsoft Intune or other solutions like this.

.DESCRIPTION
   This PowerShell will check if the requested Dell Software is installed and uninstall it.
   This script support the following applications
        - Dell Core Services
        - Dell SupportAssist
        - Dell SupportAssist Remediation
        - Dell SupportAssist OS Recovery
        - Dell Display and Peripheral Manager
        - Dell Device Management Agent (Agent for Dell Device Management Console for Peripherals updates)
        - Dell Command | Update (Universal App and Classic)
        - Dell Command | Configure
        - Dell Command | Endpoint Configure for Microsoft Intune
        - Dell Command | Monitor
        - Dell Trusted Device
        - Dell Optimizer
        - Microsoft Windows Desktop Runtime 6, 8, 9 and 10 (because some Dell tools require this as preparation) becareful it is not used by other applications

        .Parameter DellTool
        Value is the Name of Dell Application to looking for like example Dell Trusted Device


        Changelog:
            1.0.0   Initial Version

        .Example
        This will looking if Dell Command | Update is installed and uninstall this software
        UniversialDellUninstall.ps1 -DellTool 'Dell Command | Update'

        .Example
        This will looking for all listed Dell tools and uninstall them
        UniversialDellUninstall.ps1 -DellTool 'AllDell'

        .Example
        This will looking for Microsoft Desktop Runtime 8 and uninstall this software
        UniversialDellUninstall.ps1 -DellTool 'Microsoft Windows Desktop Runtime 8'

#>
param(
            [Parameter(mandatory=$false)][ValidateSet("AllDell","Dell Core Services","Dell Device Management Agent","Dell Digital Delivery","Dell Peripheral Core","Dell SupportAssist","Dell SupportAssist Remediation","Dell SupportAssist OS Recovery Plugin for Dell Update","Dell Display and Peripheral Manager","Dell Client Device Manager","Dell Command | Update","Dell Command | Configure","Dell Command | Endpoint Configure for Microsoft Intune","Dell Command | Monitor","Dell Trusted Device","Dell Optimizer","Dell Device Management Agent","Dell Pair","Microsoft Windows Desktop Runtime 6","Microsoft Windows Desktop Runtime 8","Microsoft Windows Desktop Runtime 9","Microsoft Windows Desktop Runtime 10")][String]$DellTool
    )

# Fallback if parameters are not provided by script call
if (-not $DellTool)  { $DellTool  = "Dell SupportAssist"}

##################################################
# Varible Section                            #####
##################################################
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

        $items = foreach ($path in $paths)
            {
                try
                    {
                        If ($NamePattern -ne "Microsoft Windows Desktop Runtime*(x64)*")
                            {
                                if ($NamePattern -ne "Dell SupportAssist")
                                    {
                                        Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | Where-Object {$_.DisplayName -like $NamePattern}
                                    }
                                else
                                {
                                    Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | Where-Object {$_.DisplayName -like $NamePattern -or $_.DisplayName -like "Dell SupportAssist*Business*"}
                                }
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

function Uninstall-DellTool
    {
        param
            (
                [Parameter(Mandatory)][string]$NamePattern,
                [Parameter(Mandatory)][string]$AppID,
                [Parameter(Mandatory)][string]$UninstallString
            )

        # Uninstall by MSI
        if ($UninstallString -like "*msiexec*")
            {
                try
                    {
                        Start-Process "msiexec.exe" -ArgumentList "/x $AppID /qn /norestart" -Wait -NoNewWindow

                        If($NamePattern -eq "Dell Digital Delivery")
                            {
                                Get-AppxPackage -AllUsers -Name "DellInc.DellDigitalDelivery" | Remove-AppxPackage
                                Write-Verbose "Uninstalled APPX DellInc.DellDigitalDelivery successfull" -Verbose
                            }

                        Return $true
                    }
                catch
                    {
                        Write-Verbose "Failed to uninstall $NamePattern" -Verbose
                        Return $false
                    }
            }
        # Uninstall by executable
        elseif ($null -ne $UninstallString)
            {
                try
                    {
                        # select the searchstring for function
                        $Software = $DellSoftwareList | where-object {$_.NameParameter -eq $NamePattern}
                        $UninstallParameter = $Software.SilentSwitch

                        If($NamePattern -ne "Dell Pair")
                            {
                                # prepare uninstall string
                                $ArgumentString = $UninstallString + " " + $UninstallParameter

                                Start-Process cmd.exe -ArgumentList "/c",$ArgumentString -Wait -NoNewWindow
                                Return $true
                            }
                        else
                            {
                                # uninstall Dell Pair
                                Start-Process $UninstallString -ArgumentList "/S" -wait -NoNewWindow
                                Return $true
                            }
                    }
                catch
                    {
                        Write-Verbose "Failed to uninstall $NamePattern" -Verbose
                        Return $false
                    }
            }
        else
            {
                Write-Verbose "No uninstall string found for $NamePattern" -Verbose
                Return $false
            }
    }
##################################################
# Program Section                            #####
##################################################

#### generate Logging Resources
try
    {
        [System.Diagnostics.EventLog]::CreateEventSource("Dell Software Uninstall", "Dell")
        Write-Verbose "Event source Dell Software Uninstall created for log Dell." -Verbose
    }
catch
    {
        Write-Verbose "Event source Dell Software Uninstall exist." -Verbose
    }

#### Check if installed and if yes uninstall application
Try
    {
        If($DellTool -ne "AllDell")
            {
                # select the searchstring for function
                $Software = $DellSoftwareList | where-object {$_.NameParameter -eq $DellTool}

                #### get Software details
                $SoftwareDetails = Test-SoftwareInstalled -NamePattern $Software.SearchString -VersionPattern 0.0.0.0 -ISPattern "Greater than"

                # cleanup App list for non msi uninstall apps like Dell Optimizer
                if ($Software.NameParameter -eq "Dell Optimizer" -or $Software.NameParameter -eq "Dell SupportAssist OS Recovery Plugin for Dell Update" -or $Software.NameParameter -eq "Dell SupportAssist Remediation" -or $Software.NameParameter -like "Microsoft Windows Desktop Runtime*")
                    {
                        $SoftwareDetails = $SoftwareDetails | Where-Object {$Null -eq $_.InstallLocation}
                    }

                # cover uninstall string not exist. This will be automaticlly a msi uninstall by default
                try
                    {
                        $SoftwareDetails.UninstallString = $SoftwareDetails.UninstallString #create a issue if not exist
                    }
                catch
                    {
                        $SoftwareDetails | Add-Member -MemberType NoteProperty -Name "UninstallString" -Value "msiexec"
                    }

                if($null -ne $SoftwareDetails)
                    {
                        Write-Verbose "$($SoftwareDetails.DisplayName) is installed with version $($SoftwareDetails.DisplayVersion)" -Verbose
                        $UninstallData = [PSCustomObject]@{
                                                            Software = $($SoftwareDetails.DisplayName)
                                                            Version = $($SoftwareDetails.DisplayVersion)
                                                            Uninstall = "started now"
                                                        } | ConvertTo-Json

                        Write-EventLog -LogName Dell -Source "Dell Software Uninstall" -EntryType Information -EventId 10 -Message $UninstallData

                        if ($DellTool -notlike "Microsoft Windows Desktop Runtime*")
                            {
                                # call uninstall function with cover multiple uninstall strings
                                Uninstall-DellTool -NamePattern $Software.NameParameter -AppID $SoftwareDetails.PSChildName -UninstallString $SoftwareDetails.UninstallString | Out-Null

                                # Logging uninstall result
                                $UninstallResult = Test-SoftwareInstalled -NamePattern $Software.SearchString -VersionPattern 0.0.0.0 -ISPattern "Greater than"

                                If($null -eq $UninstallResult)
                                    {
                                        Write-Verbose "$DellTool is uninstalled successfully" -Verbose

                                        $UninstallData = [PSCustomObject]@{
                                                                            Software = $DellTool
                                                                            Version = $($SoftwareDetails.DisplayVersion)
                                                                            Uninstall = $true
                                                                        } | ConvertTo-Json

                                        Write-EventLog -LogName Dell -Source "Dell Software Uninstall" -EntryType Information -EventId 10 -Message $UninstallData
                                        Exit 0
                                    }
                                else
                                    {
                                        Write-Verbose "$DellTool uninstall failed" -Verbose

                                        $UninstallData = [PSCustomObject]@{
                                                                            Software = $DellTool
                                                                            Version = $($SoftwareDetails.DisplayVersion)
                                                                            Uninstall = $false
                                                                        } | ConvertTo-Json

                                        Write-EventLog -LogName Dell -Source "Dell Software Uninstall" -EntryType Information -EventId 10 -Message $UninstallData
                                        Exit 1
                                    }
                            }
                        else
                            {
                                foreach ($SoftwareList in $SoftwareDetails)
                                    {
                                        # call uninstall function with cover multiple uninstall strings
                                        Uninstall-DellTool -NamePattern $Software.NameParameter -AppID $SoftwareList.PSChildName -UninstallString $SoftwareList.UninstallString | Out-Null
                                    }

                                # Check if Application uninstall was successful
                                $UninstallResult = Test-SoftwareInstalled -NamePattern $Software.SearchString -VersionPattern 0.0.0.0 -ISPattern "Greater than"

                                If($null -eq $UninstallResult)
                                    {
                                        Write-Verbose "$DellTool is uninstalled successfully" -Verbose

                                        $UninstallData = [PSCustomObject]@{
                                                                            Software = $DellTool
                                                                            Version = $($SoftwareDetails.DisplayVersion)
                                                                            Uninstall = $true
                                                                        } | ConvertTo-Json

                                        Write-EventLog -LogName Dell -Source "Dell Software Uninstall" -EntryType Information -EventId 10 -Message $UninstallData
                                        Exit 0
                                    }
                                else
                                    {
                                        Write-Verbose "$DellTool uninstall failed" -Verbose

                                        $UninstallData = [PSCustomObject]@{
                                                                            Software = $DellTool
                                                                            Version = $($SoftwareDetails.DisplayVersion)
                                                                            Uninstall = $false
                                                                        } | ConvertTo-Json

                                        Write-EventLog -LogName Dell -Source "Dell Software Uninstall" -EntryType Information -EventId 10 -Message $UninstallData
                                        Exit 1
                                    }

                            }

                    }
                else
                    {
                        Write-Verbose "$DellTool is not installed script will exit here" -Verbose

                        $UninstallData = [PSCustomObject]@{
                                                            Software = $DellTool
                                                            Version = "not installed"
                                                            Uninstall = $true
                                                        } | ConvertTo-Json

                        Write-EventLog -LogName Dell -Source "Dell Software Uninstall" -EntryType Information -EventId 10 -Message $UninstallData
                        Exit 0
                    }
            }
        else
            {
                # build uninstall working list by sequence number
                $DellSoftwareList = $DellSoftwareList | Where-Object {$_.Sequence -ne 9}  | Sort-Object -Property Sequence

                Foreach ($Software in $DellSoftwareList)
                    {
                        #### get Software details
                        $SoftwareDetails = Test-SoftwareInstalled -NamePattern $Software.SearchString -VersionPattern 0.0.0.0 -ISPattern "Greater than"

                        # cleanup App list for non msi uninstall apps like Dell Optimizer
                        if ($Software.NameParameter -eq "Dell Optimizer" -or $Software.NameParameter -eq "Dell SupportAssist OS Recovery Plugin for Dell Update" -or $Software.NameParameter -eq "Dell SupportAssist Remediation")
                            {
                                $SoftwareDetails = $SoftwareDetails | Where-Object {$Null -eq $_.InstallLocation}
                            }

                        if($null -ne $SoftwareDetails)
                            {
                                Write-Verbose "$($SoftwareDetails.DisplayName) is installed with version $($SoftwareDetails.DisplayVersion)" -Verbose
                                $UninstallData = [PSCustomObject]@{
                                                                        Software = $($SoftwareDetails.DisplayName)
                                                                        Version = $($SoftwareDetails.DisplayVersion)
                                                                        Uninstall = "started now"
                                                                } | ConvertTo-Json

                                Write-EventLog -LogName Dell -Source "Dell Software Uninstall" -EntryType Information -EventId 10 -Message $UninstallData

                                # call uninstall function with cover multiple uninstall strings
                                Uninstall-DellTool -NamePattern $Software.NameParameter -AppID $SoftwareDetails.PSChildName -UninstallString $SoftwareDetails.UninstallString |Out-Null

                                # Logging uninstall result
                                $UninstallResult = Test-SoftwareInstalled -NamePattern $Software.SearchString -VersionPattern 0.0.0.0 -ISPattern "Greater than"

                                If($null -eq $UninstallResult)
                                    {
                                        Write-Verbose "$($Software.NameParameter) is uninstalled successfully" -Verbose

                                        $UninstallData = [PSCustomObject]@{
                                                                                Software = $($Software.NameParameter)
                                                                                Version = $($SoftwareDetails.DisplayVersion)
                                                                                Uninstall = $true
                                                                        } | ConvertTo-Json

                                        Write-EventLog -LogName Dell -Source "Dell Software Uninstall" -EntryType Information -EventId 10 -Message $UninstallData
                                    }
                                else
                                    {
                                        Write-Verbose "$($Software.NameParameter) uninstall failed" -Verbose

                                        $UninstallData = [PSCustomObject]@{
                                                                                Software = $($Software.NameParameter)
                                                                                Version = $($SoftwareDetails.DisplayVersion)
                                                                                Uninstall = $false
                                                                            } | ConvertTo-Json

                                        Write-EventLog -LogName Dell -Source "Dell Software Uninstall" -EntryType Information -EventId 10 -Message $UninstallData

                                    }
                            }
                        else
                            {
                                        Write-Verbose "$($Software.NameParameter) is not installed script will exit here" -Verbose

                                        $UninstallData = [PSCustomObject]@{
                                                                            Software = $($Software.NameParameter)
                                                                            Version = "not installed"
                                                                            Uninstall = $true
                                                                        } | ConvertTo-Json

                                        Write-EventLog -LogName Dell -Source "Dell Software Uninstall" -EntryType Information -EventId 10 -Message $UninstallData
                            }
                    }
            }
    }
Catch
    {
        Write-Output "Script failed: $($_.Exception.Message)"
        Exit 1
    }